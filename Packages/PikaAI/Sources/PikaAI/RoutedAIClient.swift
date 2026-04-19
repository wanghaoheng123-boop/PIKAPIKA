import Foundation
import PikaCoreBase

/// Single `AIClient` implementation backed by Keychain keys and [`AIProviderRouter`].
/// Use this in the legacy PIKAPIKA app (and anywhere else) instead of OpenAI-only wiring.
public struct RoutedAIClient: AIClient, Sendable {

    private let preference: AIProviderRouter.Preference

    public init(preference: AIProviderRouter.Preference) {
        self.preference = preference
    }

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        let router = AIProviderRouter(preference: preference)
        return try await router.chatStreamResolvingPrimary(
            messages: messages,
            systemPrompt: systemPrompt,
            temperature: temperature
        )
    }

    public func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        let router = AIProviderRouter(preference: preference)
        let client = try router.imageClient()
        return try await client.generateImage(prompt: prompt, size: size)
    }

    public func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        let router = AIProviderRouter(preference: preference)
        return try await router.describeImageResolvingPrimary(imageData, prompt: prompt)
    }
}
