import Foundation
import PikaCoreBase

/// Selects an `AIClient` based on user preference and available keys.
/// If a provider fails with a recoverable error, falls back to the next provider in preference order when its key is present.
/// Factory closures are not forced `@Sendable` so defaults compile cleanly on CI toolchains (Swift 5/6).
public struct AIProviderRouter {

    public enum Preference: String, Sendable, CaseIterable {
        case anthropicPrimary
        case openAIPrimary
        /// DeepSeek first, then Anthropic, then OpenAI.
        case deepSeekAnthropicOpenAI
        /// DeepSeek first, then OpenAI, then Anthropic.
        case deepSeekOpenAIAnthropic
    }

    public enum ProviderKind: Sendable {
        case anthropic
        case openAI
        case deepSeek
    }

    public let preference: Preference
    private let openAIFactory: (String) -> AIClient
    private let anthropicFactory: (String) -> AIClient
    private let deepSeekFactory: (String) -> AIClient
    private let keyProvider: (KeychainHelper.Key) -> String?

    private static func defaultOpenAI(_ apiKey: String) -> AIClient {
        OpenAIClient(apiKey: apiKey)
    }

    private static func defaultAnthropic(_ apiKey: String) -> AIClient {
        AnthropicClient(apiKey: apiKey)
    }

    /// Default OpenAI + Anthropic + DeepSeek client factories (real network clients).
    public init(preference: Preference = .anthropicPrimary) {
        self.init(
            preference: preference,
            openAIFactory: Self.defaultOpenAI,
            anthropicFactory: Self.defaultAnthropic,
            deepSeekFactory: { DeepSeekClient(apiKey: $0) },
            keyProvider: { KeychainHelper.load($0) }
        )
    }

    /// Custom factories (tests, previews, injected mocks). Uses Keychain for keys.
    public init(
        preference: Preference,
        openAIFactory: @escaping (String) -> AIClient,
        anthropicFactory: @escaping (String) -> AIClient,
        deepSeekFactory: @escaping (String) -> AIClient = { DeepSeekClient(apiKey: $0) }
    ) {
        self.init(
            preference: preference,
            openAIFactory: openAIFactory,
            anthropicFactory: anthropicFactory,
            deepSeekFactory: deepSeekFactory,
            keyProvider: { KeychainHelper.load($0) }
        )
    }

    /// Test-only: supply key strings without touching Keychain.
    internal init(
        preference: Preference,
        openAIFactory: @escaping (String) -> AIClient,
        anthropicFactory: @escaping (String) -> AIClient,
        deepSeekFactory: @escaping (String) -> AIClient,
        keyProvider: @escaping (KeychainHelper.Key) -> String?
    ) {
        self.preference = preference
        self.openAIFactory = openAIFactory
        self.anthropicFactory = anthropicFactory
        self.deepSeekFactory = deepSeekFactory
        self.keyProvider = keyProvider
    }

    private func trimmedKey(_ key: KeychainHelper.Key) -> String? {
        guard let raw = keyProvider(key) else { return nil }
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func preferredKinds() -> [ProviderKind] {
        switch preference {
        case .anthropicPrimary: return [.anthropic, .openAI, .deepSeek]
        case .openAIPrimary: return [.openAI, .anthropic, .deepSeek]
        case .deepSeekAnthropicOpenAI: return [.deepSeek, .anthropic, .openAI]
        case .deepSeekOpenAIAnthropic: return [.deepSeek, .openAI, .anthropic]
        }
    }

    /// Clients in preference order for every kind that has a non-empty key.
    private func clientsInPreferenceOrder() -> [(AIClient, ProviderKind)] {
        var out: [(AIClient, ProviderKind)] = []
        for kind in preferredKinds() {
            switch kind {
            case .anthropic:
                if let key = trimmedKey(.anthropicKey) {
                    out.append((anthropicFactory(key), .anthropic))
                }
            case .openAI:
                if let key = trimmedKey(.openAIKey) {
                    out.append((openAIFactory(key), .openAI))
                }
            case .deepSeek:
                if let key = trimmedKey(.deepSeekKey) {
                    out.append((deepSeekFactory(key), .deepSeek))
                }
            }
        }
        return out
    }

    /// First available client in preference order, with which vendor backs it.
    public func primaryClientWithKind() throws -> (AIClient, ProviderKind) {
        let ordered = clientsInPreferenceOrder()
        guard let first = ordered.first else { throw AIClientError.missingAPIKey }
        return first
    }

    /// Resolve the primary client, or throw `missingAPIKey` if none is available.
    public func primaryClient() throws -> AIClient {
        try primaryClientWithKind().0
    }

    /// Stream chat; on rate limit, 5xx, network-ish `URLError`, or `networkUnavailable`,
    /// retry with the next provider in preference order when its key is present.
    /// - Note: Marked `@MainActor` so chunk callbacks can update SwiftUI without cross-actor hops; non-UI callers should hop to the main actor before invoking.
    @MainActor
    public func runChatWithFallback(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double,
        onChunk: @escaping (String) -> Void
    ) async throws {
        let candidates = try clientsInPreferenceOrderThrowingIfEmpty()
        var lastError: Error?
        for index in candidates.indices {
            let (client, _) = candidates[index]
            do {
                let stream = try await client.chat(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    temperature: temperature
                )
                try await Self.drain(stream, onChunk: onChunk)
                return
            } catch {
                lastError = error
                let hasNext = index < candidates.count - 1
                guard hasNext, Self.shouldFallback(for: error) else { throw error }
            }
        }
        throw lastError ?? AIClientError.missingAPIKey
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

    private func clientsInPreferenceOrderThrowingIfEmpty() throws -> [(AIClient, ProviderKind)] {
        let ordered = clientsInPreferenceOrder()
        guard !ordered.isEmpty else { throw AIClientError.missingAPIKey }
        return ordered
    }

    /// Return a client specifically for image generation (OpenAI-only today).
    public func imageClient() throws -> AIClient {
        if let key = trimmedKey(.openAIKey) {
            return openAIFactory(key)
        }
        throw AIClientError.missingAPIKey
    }

    // MARK: - Non-MainActor streaming (for `AIClient` adapters)

    /// Primary chat stream, walking preference order when recoverable errors happen **before** streaming begins.
    public func chatStreamResolvingPrimary(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        let candidates = try clientsInPreferenceOrderThrowingIfEmpty()
        var lastError: Error?
        for index in candidates.indices {
            let (client, _) = candidates[index]
            do {
                return try await client.chat(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    temperature: temperature
                )
            } catch {
                lastError = error
                let hasNext = index < candidates.count - 1
                guard hasNext, Self.shouldFallback(for: error) else { throw error }
            }
        }
        throw lastError ?? AIClientError.missingAPIKey
    }

    /// Vision / image captioning with fallback along preference order for recoverable errors.
    public func describeImageResolvingPrimary(_ imageData: Data, prompt: String) async throws -> String {
        let candidates = try clientsInPreferenceOrderThrowingIfEmpty()
        var lastError: Error?
        for index in candidates.indices {
            let (client, _) = candidates[index]
            do {
                return try await client.describeImage(imageData, prompt: prompt)
            } catch {
                lastError = error
                let hasNext = index < candidates.count - 1
                guard hasNext, Self.shouldFallback(for: error) else { throw error }
            }
        }
        throw lastError ?? AIClientError.missingAPIKey
    }
}
