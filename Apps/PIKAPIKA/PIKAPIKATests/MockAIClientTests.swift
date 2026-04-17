import XCTest
import PikaCoreBase
@testable import PIKAPIKA

final class MockAIClientTests: XCTestCase {

    func testChatEchoesUserContent() async throws {
        let client = MockAIClient()
        let stream = try await client.chat(
            messages: [ChatMessage(role: "user", content: "hello from test")],
            systemPrompt: "You are a helpful pet.",
            temperature: 0.5
        )

        var chunks: [String] = []
        for try await piece in stream {
            chunks.append(piece)
        }

        let joined = chunks.joined()
        XCTAssertTrue(joined.contains("hello from test"), "Mock reply should reference user text: \(joined)")
    }

    func testChatEmptyUserGetsGreeting() async throws {
        let client = MockAIClient()
        let stream = try await client.chat(
            messages: [],
            systemPrompt: "sys",
            temperature: 0.0
        )

        var chunks: [String] = []
        for try await piece in stream {
            chunks.append(piece)
        }

        XCTAssertTrue(chunks.joined().contains("PIKAPIKA"))
    }

    func testDescribeImageReturnsStub() async throws {
        let client = MockAIClient()
        let text = try await client.describeImage(Data(), prompt: "what is this")
        XCTAssertTrue(text.contains("mock"))
    }

    func testGenerateImageReturnsEmptyData() async throws {
        let client = MockAIClient()
        let data = try await client.generateImage(prompt: "a cat", size: .square256)
        XCTAssertEqual(data.count, 0)
    }
}
