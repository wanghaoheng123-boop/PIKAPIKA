import Foundation
import PikaCoreBase

/// Deterministic in-memory `AIClient` for previews, tests, and offline demos.
/// `@unchecked Sendable`: class is immutable after init; required for `AIClient: Sendable` under strict concurrency.
public final class MockAIClient: AIClient, @unchecked Sendable {

    private let scriptedReplies: [String]
    private let imageBytes: Data
    private let delay: Duration

    public init(
        scriptedReplies: [String] = ["Hi! I'm your pet.", "Nice to see you."],
        imageBytes: Data = Data([0x89, 0x50, 0x4E, 0x47]),
        delay: Duration = .milliseconds(20)
    ) {
        self.scriptedReplies = scriptedReplies
        self.imageBytes = imageBytes
        self.delay = delay
    }

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        let text = scriptedReplies[messages.count % scriptedReplies.count]
        let d = delay
        return AsyncThrowingStream { continuation in
            Task {
                // Let the consumer attach before yielding (avoids empty reads on fast CI runners).
                await Task.yield()
                for word in text.split(separator: " ") {
                    if d != .zero {
                        try? await Task.sleep(for: d)
                    }
                    continuation.yield(String(word) + " ")
                }
                continuation.finish()
            }
        }
    }

    public func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        imageBytes
    }

    public func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        "a mock description"
    }
}
