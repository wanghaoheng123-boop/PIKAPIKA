import XCTest
import PikaCoreBase
@testable import PikaAI

private struct GoldenFailingClient: AIClient, Sendable {
    let error: AIClientError

    func chat(
        messages: [ChatMessage],
        systemPrompt: String?,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        throw error
    }

    func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        Data()
    }

    func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        ""
    }
}

final class RouterGoldenFallbackTests: XCTestCase {

    @MainActor
    func testFallbackProducesDeterministicGoldenResponse() async throws {
        let keyProvider: (KeychainHelper.Key) -> String? = {
            switch $0 {
            case .deepSeekKey: return "deepseek"
            case .openAIKey: return "openai"
            case .anthropicKey: return "anthropic"
            default: return nil
            }
        }
        let router = AIProviderRouter(
            preference: .deepSeekOpenAIAnthropic,
            openAIFactory: { _ in GoldenFailingClient(error: .serverError(statusCode: 503, body: "down")) },
            anthropicFactory: { _ in MockAIClient(scriptedReplies: ["golden fallback ready"], delay: .zero) },
            deepSeekFactory: { _ in GoldenFailingClient(error: .rateLimited) },
            keyProvider: keyProvider
        )

        var output = ""
        try await router.runChatWithFallback(
            messages: [ChatMessage(role: "user", content: "hi")],
            systemPrompt: "sys",
            temperature: 0.0,
            onChunk: { output += $0 }
        )
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "golden fallback ready")
    }
}

