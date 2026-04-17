import Foundation
import PikaCoreBase

/// Deterministic offline replies for Simulator and testing.
final class MockAIClient: AIClient, @unchecked Sendable {

    func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        let lastUser = messages.last(where: { $0.role == "user" })?.content ?? ""
        let reply: String
        if lastUser.isEmpty {
            reply = "Hello! I'm your PIKAPIKA companion. Tell me about your day."
        } else {
            reply = "(\(systemPrompt.prefix(40))…) You said: “\(lastUser.prefix(120))” — I'm here with you!"
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(reply)
            continuation.finish()
        }
    }

    func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        Data()
    }

    func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        "Image described (mock): \(prompt.prefix(80))"
    }
}
