import Foundation
import PikaCoreBase

/// Selects an `AIClient` based on user preference and available keys.
/// If the preferred provider fails with a recoverable error, falls back to
/// the alternate provider when its key is present.
/// Factory closures are not forced `@Sendable` so defaults compile cleanly on CI toolchains (Swift 5/6).
public struct AIProviderRouter {

    public enum Preference: String, Sendable, CaseIterable {
        case anthropicPrimary
        case openAIPrimary
    }

    enum ProviderKind: Sendable {
        case anthropic
        case openAI
    }

    public let preference: Preference
    private let openAIFactory: (String) -> AIClient
    private let anthropicFactory: (String) -> AIClient

    private static func defaultOpenAI(_ apiKey: String) -> AIClient {
        OpenAIClient(apiKey: apiKey)
    }

    private static func defaultAnthropic(_ apiKey: String) -> AIClient {
        AnthropicClient(apiKey: apiKey)
    }

    /// Default OpenAI + Anthropic client factories (real network clients).
    public init(preference: Preference = .anthropicPrimary) {
        self.preference = preference
        self.openAIFactory = Self.defaultOpenAI
        self.anthropicFactory = Self.defaultAnthropic
    }

    /// Custom factories (tests, previews, injected mocks).
    public init(
        preference: Preference,
        openAIFactory: @escaping (String) -> AIClient,
        anthropicFactory: @escaping (String) -> AIClient
    ) {
        self.preference = preference
        self.openAIFactory = openAIFactory
        self.anthropicFactory = anthropicFactory
    }

    private func preferredKinds() -> [ProviderKind] {
        switch preference {
        case .anthropicPrimary: return [.anthropic, .openAI]
        case .openAIPrimary: return [.openAI, .anthropic]
        }
    }

    /// First available client in preference order, with which vendor backs it.
    public func primaryClientWithKind() throws -> (AIClient, ProviderKind) {
        for kind in preferredKinds() {
            switch kind {
            case .anthropic:
                if let key = KeychainHelper.load(.anthropicKey), !key.isEmpty {
                    return (anthropicFactory(key), .anthropic)
                }
            case .openAI:
                if let key = KeychainHelper.load(.openAIKey), !key.isEmpty {
                    return (openAIFactory(key), .openAI)
                }
            }
        }
        throw AIClientError.missingAPIKey
    }

    /// Resolve the primary client, or throw `missingAPIKey` if none is available.
    public func primaryClient() throws -> AIClient {
        try primaryClientWithKind().0
    }

    /// Client for the vendor that is *not* `used`, when a key exists.
    func alternateClient(after used: ProviderKind) -> AIClient? {
        switch used {
        case .anthropic:
            guard let key = KeychainHelper.load(.openAIKey), !key.isEmpty else { return nil }
            return openAIFactory(key)
        case .openAI:
            guard let key = KeychainHelper.load(.anthropicKey), !key.isEmpty else { return nil }
            return anthropicFactory(key)
        }
    }

    /// Stream chat; on rate limit, 5xx, network-ish `URLError`, or `networkUnavailable`,
    /// retry once using the other provider when its key is present.
    /// - Note: Marked `@MainActor` so chunk callbacks can update SwiftUI without cross-actor hops; non-UI callers should hop to the main actor before invoking.
    @MainActor
    public func runChatWithFallback(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double,
        onChunk: @escaping (String) -> Void
    ) async throws {
        let (primary, kind) = try primaryClientWithKind()
        do {
            let stream = try await primary.chat(
                messages: messages,
                systemPrompt: systemPrompt,
                temperature: temperature
            )
            try await Self.drain(stream, onChunk: onChunk)
        } catch {
            guard Self.shouldFallback(for: error),
                  let alt = alternateClient(after: kind)
            else { throw error }
            let stream = try await alt.chat(
                messages: messages,
                systemPrompt: systemPrompt,
                temperature: temperature
            )
            try await Self.drain(stream, onChunk: onChunk)
        }
    }

    @MainActor
    private static func drain(
        _ stream: AsyncThrowingStream<String, Error>,
        onChunk: @escaping (String) -> Void
    ) async throws {
        for try await chunk in stream {
            onChunk(chunk)
        }
    }

    private static func shouldFallback(for error: Error) -> Bool {
        if let e = error as? AIClientError {
            switch e {
            case .rateLimited, .networkUnavailable:
                return true
            case .serverError(let code, _):
                return (500...599).contains(code)
            default:
                return false
            }
        }
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut,
                    .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        return false
    }

    /// Return a client specifically for image generation (OpenAI-only today).
    public func imageClient() throws -> AIClient {
        if let key = KeychainHelper.load(.openAIKey), !key.isEmpty {
            return openAIFactory(key)
        }
        throw AIClientError.missingAPIKey
    }

    // MARK: - Non-MainActor streaming (for `AIClient` adapters)

    /// Primary chat stream, or the alternate vendor if the primary fails **before** streaming begins (same recoverability rules as `runChatWithFallback`).
    public func chatStreamResolvingPrimary(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        let (primary, kind) = try primaryClientWithKind()
        do {
            return try await primary.chat(
                messages: messages,
                systemPrompt: systemPrompt,
                temperature: temperature
            )
        } catch {
            guard Self.shouldFallback(for: error),
                  let alt = alternateClient(after: kind)
            else { throw error }
            return try await alt.chat(
                messages: messages,
                systemPrompt: systemPrompt,
                temperature: temperature
            )
        }
    }

    /// Vision / image captioning with one fallback attempt when recoverable.
    public func describeImageResolvingPrimary(_ imageData: Data, prompt: String) async throws -> String {
        let (primary, kind) = try primaryClientWithKind()
        do {
            return try await primary.describeImage(imageData, prompt: prompt)
        } catch {
            guard Self.shouldFallback(for: error),
                  let alt = alternateClient(after: kind)
            else { throw error }
            return try await alt.describeImage(imageData, prompt: prompt)
        }
    }
}
