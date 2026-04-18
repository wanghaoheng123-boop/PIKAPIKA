import Foundation
import PikaCoreBase
import UIKit

/// Deterministic offline replies for Simulator and testing.
final class MockAIClient: AIClient, @unchecked Sendable {

    func chat(
        messages: [ChatMessage],
        systemPrompt _: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        let lastUser = messages.last(where: { $0.role == "user" })?.content ?? ""
        let reply: String
        if lastUser.isEmpty {
            reply = "Hello! I'm your PIKAPIKA companion. Tell me about your day."
        } else {
            let trimmedUser = lastUser.trimmingCharacters(in: .whitespacesAndNewlines)
            reply = "You said: \"\(trimmedUser.prefix(120))\". I'm right here with you."
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(reply)
            continuation.finish()
        }
    }

    func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        let r = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let img = r.image { ctx in
            UIColor.systemPink.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return img.pngData() ?? Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    }

    func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        "Image described (mock): \(prompt.prefix(80))"
    }
}
