import XCTest
import PikaCoreBase
@testable import PikaAI

/// Fails `chat` with a fixed `AIClientError` (no stream).
private struct FailingChatClient: AIClient, Sendable {
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

private enum TestKeyMap {
    static func provider(_ pairs: (KeychainHelper.Key, String)...) -> (KeychainHelper.Key) -> String? {
        let dict = Dictionary(uniqueKeysWithValues: pairs)
        return { dict[$0] }
    }
}

final class DeepSeekRouterTests: XCTestCase {

    @MainActor
    func testDeepSeekFirstFallsBackToAnthropicOnRateLimit() async throws {
        let keys = TestKeyMap.provider(
            (.deepSeekKey, "ds"),
            (.anthropicKey, "ant"),
            (.openAIKey, "oai")
        )
        let router = AIProviderRouter(
            preference: .deepSeekAnthropicOpenAI,
            openAIFactory: { _ in MockAIClient(scriptedReplies: ["openai-only"], delay: .zero) },
            anthropicFactory: { _ in MockAIClient(scriptedReplies: ["anthropic ok"], delay: .zero) },
            deepSeekFactory: { _ in FailingChatClient(error: .rateLimited) },
            keyProvider: keys
        )
        var acc = ""
        try await router.runChatWithFallback(
            messages: [ChatMessage(role: "user", content: "hi")],
            systemPrompt: "sys",
            temperature: 0,
            onChunk: { acc += $0 }
        )
        XCTAssertTrue(acc.contains("anthropic"))
        XCTAssertFalse(acc.contains("openai-only"))
    }

    @MainActor
    func testThreeProviderHopDeepSeekOpenAIAnthropic() async throws {
        let keys = TestKeyMap.provider(
            (.deepSeekKey, "1"),
            (.openAIKey, "2"),
            (.anthropicKey, "3")
        )
        let router = AIProviderRouter(
            preference: .deepSeekOpenAIAnthropic,
            openAIFactory: { _ in FailingChatClient(error: .serverError(statusCode: 502, body: "bad")) },
            anthropicFactory: { _ in MockAIClient(scriptedReplies: ["third wins"], delay: .zero) },
            deepSeekFactory: { _ in FailingChatClient(error: .rateLimited) },
            keyProvider: keys
        )
        var acc = ""
        try await router.runChatWithFallback(
            messages: [ChatMessage(role: "user", content: "hi")],
            systemPrompt: "sys",
            temperature: 0,
            onChunk: { acc += $0 }
        )
        XCTAssertTrue(acc.contains("third"))
    }

    @MainActor
    func testAnthropicPrimaryIncludesDeepSeekAsThirdHop() async throws {
        let keys = TestKeyMap.provider(
            (.anthropicKey, "a"),
            (.openAIKey, "o"),
            (.deepSeekKey, "d")
        )
        let router = AIProviderRouter(
            preference: .anthropicPrimary,
            openAIFactory: { _ in FailingChatClient(error: .rateLimited) },
            anthropicFactory: { _ in FailingChatClient(error: .rateLimited) },
            deepSeekFactory: { _ in MockAIClient(scriptedReplies: ["deepseek rescue"], delay: .zero) },
            keyProvider: keys
        )
        var acc = ""
        try await router.runChatWithFallback(
            messages: [ChatMessage(role: "user", content: "hi")],
            systemPrompt: "sys",
            temperature: 0,
            onChunk: { acc += $0 }
        )
        XCTAssertTrue(acc.contains("deepseek"))
    }
}
