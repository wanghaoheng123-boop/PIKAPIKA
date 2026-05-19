import XCTest
import SwiftData
import PikaCorePersistence
import PikaCoreBase

private struct FixtureAIClient: AIClient, Sendable {
    let responseText: String

    func chat(
        messages: [ChatMessage],
        systemPrompt: String?,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(responseText)
            continuation.finish()
        }
    }

    func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        Data()
    }

    func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        ""
    }
}

final class PetMemoryExtractorTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Pet.self,
            PetMemoryFact.self,
            BondEvent.self,
            ConversationMessage.self,
            SeasonalEvent.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    func testExtractAndStorePersistsSingleFactFromJSONFixture() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let pet = Pet(name: "Pika", species: "cat", creationMethod: "prompt", spriteAtlasPath: "")
        context.insert(pet)
        try context.save()

        let fixture = """
        {"content":"I remember you like green tea in the morning.","category":"preference","importance":1}
        """
        let ai = FixtureAIClient(responseText: fixture)

        let stored = await PetMemoryExtractor.extractAndStore(
            pet: pet,
            userLine: "I drink green tea every morning.",
            assistantLine: "Nice routine!",
            modelContext: context,
            aiClient: ai,
            enabled: true
        )
        XCTAssertTrue(stored)

        let rows = try context.fetch(FetchDescriptor<PetMemoryFact>())
            .filter { $0.pet?.id == pet.id }
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.category, "preference")
        XCTAssertEqual(rows.first?.importance, 1)
        XCTAssertTrue(rows.first?.content.contains("green tea") == true)
    }

    @MainActor
    func testExtractAndStoreReturnsFalseForInvalidJSONFixture() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let pet = Pet(name: "Pika", species: "dog", creationMethod: "prompt", spriteAtlasPath: "")
        context.insert(pet)
        try context.save()

        let ai = FixtureAIClient(responseText: "not-json")
        let stored = await PetMemoryExtractor.extractAndStore(
            pet: pet,
            userLine: "I run daily.",
            assistantLine: "Great!",
            modelContext: context,
            aiClient: ai,
            enabled: true
        )
        XCTAssertFalse(stored)
    }
}

