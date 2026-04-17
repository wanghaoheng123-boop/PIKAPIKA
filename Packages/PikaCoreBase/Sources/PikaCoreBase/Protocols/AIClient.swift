import Foundation

/// Protocol for any AI provider client (OpenAI, Anthropic, mock for tests).
public protocol AIClient: Sendable {
    /// Send a conversation turn and receive a streamed response.
    func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error>

    /// Generate a sprite sheet image from a text prompt.
    func generateImage(prompt: String, size: ImageSize) async throws -> Data

    /// Analyze an image and return a text description (for photo→prompt path).
    func describeImage(_ imageData: Data, prompt: String) async throws -> String
}

public struct ChatMessage: Sendable, Codable {
    public let role: String   // "user", "assistant", "system"
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public enum ImageSize: String, Sendable {
    case square256   = "256x256"
    case square512   = "512x512"
    case square1024  = "1024x1024"
}

public enum AIClientError: LocalizedError, Sendable {
    case missingAPIKey
    case rateLimited
    case contextTooLong
    case serverError(statusCode: Int, body: String)
    case imageGenerationFailed(String)
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key found. Please add your API key in Settings."
        case .rateLimited:
            return "You've hit the API rate limit. Please wait a moment."
        case .contextTooLong:
            return "The conversation is too long. Starting a fresh chat."
        case .serverError(let code, let body):
            return "Server error \(code): \(body)"
        case .imageGenerationFailed(let reason):
            return "Could not generate pet image: \(reason)"
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        }
    }
}
