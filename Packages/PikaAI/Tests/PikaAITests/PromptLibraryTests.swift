import XCTest
import PikaCoreBase
@testable import PikaAI

final class PromptLibraryTests: XCTestCase {

    func testSystemPromptIncludesPetNameAndTraits() {
        let prompt = PromptLibrary.systemPrompt(
            petName: "Mochi",
            species: "cat",
            traits: ["playful", "sassy"],
            bondLevel: .friend,
            context: .coding
        )
        XCTAssertTrue(prompt.contains("Mochi"))
        XCTAssertTrue(prompt.contains("cat"))
        XCTAssertTrue(prompt.contains("playful"))
        XCTAssertTrue(prompt.contains("sassy"))
        XCTAssertTrue(prompt.contains(BondLevel.friend.displayName))
        XCTAssertTrue(prompt.contains(AppContext.coding.systemPromptHint))
    }

    func testSpritePromptFromText() {
        let req = PetCreationRequest(
            method: .textPrompt("a space hamster with goggles"),
            desiredName: "Nova",
            stylePreference: .pixelArt
        )
        let prompt = PromptLibrary.spritePrompt(request: req)
        XCTAssertTrue(prompt.contains("Nova"))
        XCTAssertTrue(prompt.contains("pixel art"))
        XCTAssertTrue(prompt.contains("space hamster with goggles"))
    }
}

final class MockAIClientTests: XCTestCase {

    func testMockChatStreamsWords() async throws {
        let client = MockAIClient(scriptedReplies: ["hello world"], delay: .milliseconds(1))
        let stream = try await client.chat(
            messages: [ChatMessage(role: "user", content: "hi")],
            systemPrompt: "sys",
            temperature: 0.7
        )
        var output = ""
        for try await chunk in stream { output += chunk }
        XCTAssertEqual(output.trimmingCharacters(in: .whitespaces), "hello world")
    }
}
