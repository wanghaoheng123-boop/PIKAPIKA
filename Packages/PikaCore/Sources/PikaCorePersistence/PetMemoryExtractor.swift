import Foundation
import SwiftData
import PikaCoreBase

/// Uses an AI client to extract notable facts from a chat exchange and persist them as `PetMemoryFact`.
public enum PetMemoryExtractor {
    private static let maxMemoryFactsPerPet = 12

    /// Attempts to extract a memory fact from the given exchange and store it.
    /// Returns `true` if a fact was extracted and stored; `false` if nothing notable was found.
    public static func extractAndStore(
        pet: Pet,
        userLine: String,
        assistantLine: String,
        modelContext: ModelContext,
        aiClient: any AIClient,
        enabled: Bool
    ) async -> Bool {
        guard enabled else { return false }

        let extractionPrompt = """
        You are a memory manager for a virtual pet companion app.
        Given the following exchange between a user and their pet "\(pet.name)", \
        extract at most ONE notable fact about the user that the pet should remember long-term.

        Return ONLY a JSON object with this shape (or return empty {}):
        {
          "content": "the fact, in the pet's voice, 1 short sentence",
          "category": "preference|relationship|schedule|style|goal|f fact",
          "importance": 0
        }

        Rules:
        - content must be something the pet would say back to the user (first person toward the user)
        - importance: 0 = P2 nice-to-have, 1 = P1 notable, 2 = P0 critical (never forget)
        - If nothing worth remembering, return {}
        - Never make up facts not in the exchange.

        Exchange:
        User: \(userLine)
        Pet: \(assistantLine)
        """

        do {
            let messages: [ChatMessage] = [
                ChatMessage(role: "user", content: extractionPrompt)
            ]
            var result = ""
            let stream = try await aiClient.chat(messages: messages, systemPrompt: nil, temperature: 0.3)
            for try await chunk in stream {
                result += chunk
            }
            let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = trimmed.data(using: .utf8) else { return false }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            guard let content = json["content"] as? String,
                  !content.isEmpty else { return false }
            let category = json["category"] as? String ?? "fact"
            let importance = json["importance"] as? Int ?? 1

            let fact = PetMemoryFact(
                pet: pet,
                content: content,
                category: category,
                importance: importance,
                source: "ai_extract"
            )
            modelContext.insert(fact)
            try modelContext.save()

            try pruneExcess(pet: pet, modelContext: modelContext)
            return true
        } catch {
            return false
        }
    }

    private static func pruneExcess(pet: Pet, modelContext: ModelContext) throws {
        let petId = pet.id
        let descriptor = FetchDescriptor<PetMemoryFact>(
            predicate: #Predicate<PetMemoryFact> { fact in
                fact.pet?.id == petId
            },
            sortBy: [
                SortDescriptor(\.importance, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        let rows = try modelContext.fetch(descriptor)
        guard rows.count > maxMemoryFactsPerPet else { return }
        let overflow = rows.count - maxMemoryFactsPerPet
        for row in rows.suffix(overflow) {
            modelContext.delete(row)
        }
        try modelContext.save()
    }
}
