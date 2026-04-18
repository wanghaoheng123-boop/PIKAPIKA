import Foundation
import PikaCore

/// Selects an `AIClient` based on user preference and available keys.
/// If the preferred provider fails with a recoverable error, falls back to
/// the alternate provider when its key is present.
public struct AIProviderRouter: Sendable {

    public enum Preference: String, Sendable, CaseIterable {
        case anthropicPrimary
        case openAIPrimary
    }

    public let preference: Preference
    private let openAIFactory: @Sendable (String) -> AIClient
    private let anthropicFactory: @Sendable (String) -> AIClient

    public init(
        preference: Preference = .anthropicPrimary,
        openAIFactory: @escaping @Sendable (String) -> AIClient = { OpenAIClient(apiKey: $0) },
        anthropicFactory: @escaping @Sendable (String) -> AIClient = { AnthropicClient(apiKey: $0) }
    ) {
        self.preference = preference
        self.openAIFactory = openAIFactory
        self.anthropicFactory = anthropicFactory
    }

    /// Resolve the primary client, or throw `missingAPIKey` if none is available.
    public func primaryClient() throws -> AIClient {
        switch preference {
        case .anthropicPrimary:
            if let key = KeychainHelper.load(.anthropicKey), !key.isEmpty {
                return anthropicFactory(key)
            }
            if let key = KeychainHelper.load(.openAIKey), !key.isEmpty {
                return openAIFactory(key)
            }
        case .openAIPrimary:
            if let key = KeychainHelper.load(.openAIKey), !key.isEmpty {
                return openAIFactory(key)
            }
            if let key = KeychainHelper.load(.anthropicKey), !key.isEmpty {
                return anthropicFactory(key)
            }
        }
        throw AIClientError.missingAPIKey
    }

    /// Return a client specifically for image generation (OpenAI-only today).
    public func imageClient() throws -> AIClient {
        if let key = KeychainHelper.load(.openAIKey), !key.isEmpty {
            return openAIFactory(key)
        }
        throw AIClientError.missingAPIKey
    }
}
