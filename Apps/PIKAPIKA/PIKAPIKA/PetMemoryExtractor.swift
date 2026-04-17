import Foundation
import PikaCore
import SwiftData

/// After a chat turn, asks the model for 0–2 compact memory facts (only when a real API key is configured).
enum PetMemoryExtractor {
    private static let maxFactsPerPet = 120

    @MainActor
    static func extractAndStore(
        pet: Pet,
        userLine: String,
        assistantLine: String,
        modelContext: ModelContext,
        aiClient: any AIClient,
        enabled: Bool
    ) async {
        guard enabled else { return }
        guard !userLine.isEmpty, !assistantLine.isEmpty else { return }

        let existingContents = pet.memoryFacts.map(\.content)
        var knownLower = Set(existingContents.map { $0.lowercased() })
        let existingSample = existingContents.prefix(12).joined(separator: " | ")

        let system = """
        You extract durable memories for a virtual pet about its human companion.
        Return ONLY JSON array with 0 to 2 objects. No markdown, no commentary.
        Schema: [{"content":"short fact","category":"preference|relationship|goal|schedule|style|fact","importance":0|1|2}]
        importance: 2=critical, 1=useful, 0=optional.
        Skip duplicates of existing memories. If nothing new, return [].
        """
        let userPayload = """
        Pet name: \(pet.name). Species: \(pet.species).
        Existing memory hints: \(existingSample.isEmpty ? "(none)" : existingSample)

        USER: \(userLine)
        ASSISTANT: \(assistantLine)
        """

        do {
            let stream = try await aiClient.chat(
                messages: [ChatMessage(role: "user", content: userPayload)],
                systemPrompt: system,
                temperature: 0.15
            )
            var raw = ""
            for try await chunk in stream {
                raw += chunk
            }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.first == "[" else { return }
            guard let data = trimmed.data(using: .utf8) else { return }
            let decoded = try JSONDecoder().decode([FactDTO].self, from: data)
            for fact in decoded {
                let key = fact.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty else { continue }
                if knownLower.contains(key) { continue }
                knownLower.insert(key)
                let row = PetMemoryFact(
                    pet: pet,
                    content: fact.content,
                    category: fact.category.isEmpty ? "fact" : fact.category,
                    importance: min(2, max(0, fact.importance)),
                    source: "ai_extract"
                )
                modelContext.insert(row)
            }
            try trimIfNeeded(pet: pet, modelContext: modelContext)
            try modelContext.save()
            PetMemoryFileStore.syncFacts(petId: pet.id, petName: pet.name, facts: pet.memoryFacts)
        } catch {
            // ignore extraction failures
        }
    }

    private struct FactDTO: Decodable {
        let content: String
        let category: String
        let importance: Int
    }

    @MainActor
    private static func trimIfNeeded(pet: Pet, modelContext: ModelContext) throws {
        let facts = pet.memoryFacts
        guard facts.count > maxFactsPerPet else { return }
        let sorted = facts.sorted {
            if $0.importance != $1.importance { return $0.importance < $1.importance }
            return $0.createdAt < $1.createdAt
        }
        let dropCount = facts.count - maxFactsPerPet
        for f in sorted.prefix(dropCount) {
            modelContext.delete(f)
        }
    }
}
