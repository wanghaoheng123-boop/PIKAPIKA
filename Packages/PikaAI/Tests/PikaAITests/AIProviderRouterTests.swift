import XCTest
import PikaCore
@testable import PikaAI

/// Fails `chat` with a fixed `AIClientError` (no stream).
private struct FailingChatClient: AIClient {
    let error: AIClientError

    func chat(
        messages: [ChatMessage],
        systemPrompt: String,
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

@MainActor
final class AIProviderRouterTests: XCTestCase {

    override func tearDown() {
        KeychainHelper.delete(.anthropicKey)
        KeychainHelper.delete(.openAIKey)
        super.tearDown()
    }

    func testFallbackOnRateLimitUsesAlternateProvider() async throws {
        XCTAssertTrue(KeychainHelper.save("anthropic-test-key", for: .anthropicKey))
        XCTAssertTrue(KeychainHelper.save("openai-test-key", for: .openAIKey))

        let router = AIProviderRouter(
            preference: .anthropicPrimary,
            anthropicFactory: { _ in FailingChatClient(error: .rateLimited) },
            openAIFactory: { _ in MockAIClient(scriptedReplies: ["fallback ok"], delay: .milliseconds(1)) }
        )

        var out = ""
        try await router.runChatWithFallback(
            messages: [ChatMessage(role: "user", content: "hi")],
            systemPrompt: "sys",
            temperature: 0.5,
            onChunk: { out += $0 }
        )
        XCTAssertTrue(out.contains("fallback"))
    }

    func testNoFallbackOnMissingKeyAlternate() async throws {
        XCTAssertTrue(KeychainHelper.save("anthropic-only", for: .anthropicKey))
        KeychainHelper.delete(.openAIKey)

        let router = AIProviderRouter(
            preference: .anthropicPrimary,
            anthropicFactory: { _ in FailingChatClient(error: .rateLimited) },
            openAIFactory: { _ in MockAIClient(scriptedReplies: ["should not run"], delay: .milliseconds(1)) }
        )

        do {
            try await router.runChatWithFallback(
                messages: [ChatMessage(role: "user", content: "hi")],
                systemPrompt: "sys",
                temperature: 0.5,
                onChunk: { _ in }
            )
            XCTFail("expected rateLimited")
        } catch let e as AIClientError {
            if case .rateLimited = e {} else { XCTFail("wrong error \(e)") }
        }
    }

    func testFallbackOnServerError5xx() async throws {
        XCTAssertTrue(KeychainHelper.save("a", for: .anthropicKey))
        XCTAssertTrue(KeychainHelper.save("o", for: .openAIKey))

        let router = AIProviderRouter(
            preference: .openAIPrimary,
            openAIFactory: { _ in FailingChatClient(error: .serverError(statusCode: 503, body: "down")) },
            anthropicFactory: { _ in MockAIClient(scriptedReplies: ["anthropic rescue"], delay: .milliseconds(1)) }
        )

        var out = ""
        try await router.runChatWithFallback(
            messages: [ChatMessage(role: "user", content: "x")],
            systemPrompt: "s",
            temperature: 0,
            onChunk: { out += $0 }
        )
        XCTAssertTrue(out.contains("anthropic"))
    }
}
