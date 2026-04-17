import Foundation
import PikaCore
import PikaCoreBase
import SwiftData

/// Shared send/receive flow for `ChatView` and `PetDetailView` playground.
enum PetChatActions {

    static func systemPrompt(for pet: Pet, modelContext: ModelContext) -> String {
        let traits = pet.personalityTraits.joined(separator: ", ")
        let lore = pet.creatureDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let loreBlock = lore.isEmpty ? "" : " Creature design: \(lore)"

        let memoryLines = (try? memoryLines(for: pet, modelContext: modelContext)) ?? []
        let memoryBlock: String
        if memoryLines.isEmpty {
            memoryBlock = ""
        } else {
            memoryBlock = " What you remember about your human (most important first): \(memoryLines.joined(separator: " · "))."
        }

        let base = "You are \(pet.name), a virtual \(pet.species) companion in PIKAPIKA. Keep replies short (1–3 sentences) and warm.\(loreBlock)\(memoryBlock)"
        if traits.isEmpty {
            return base
        }
        return "\(base) Personality hints: \(traits)."
    }

    private static func memoryLines(for pet: Pet, modelContext: ModelContext) throws -> [String] {
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
        return rows.prefix(12).map(\.content)
    }

    @MainActor
    static func messages(for pet: Pet, modelContext: ModelContext) throws -> [ConversationMessage] {
        let descriptor = FetchDescriptor<ConversationMessage>()
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.pet?.id == pet.id }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Sends a user line and streams the assistant reply; persists both messages.
    @MainActor
    static func send(
        pet: Pet,
        userText: String,
        modelContext: ModelContext,
        aiClient: any AIClient,
        onStreamingAssistant: @escaping (String) -> Void
    ) async throws {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = ConversationMessage(pet: pet, role: "user", content: trimmed)
        modelContext.insert(userMsg)
        try modelContext.save()

        var history = try messages(for: pet, modelContext: modelContext)
        var chatMessages: [ChatMessage] = history.map { ChatMessage(role: $0.role, content: $0.content) }
        if chatMessages.last?.role != "user" || chatMessages.last?.content != trimmed {
            chatMessages.append(ChatMessage(role: "user", content: trimmed))
        }

        let stream = try await aiClient.chat(
            messages: chatMessages,
            systemPrompt: systemPrompt(for: pet, modelContext: modelContext),
            temperature: 0.75
        )
        var full = ""
        for try await chunk in stream {
            full += chunk
            onStreamingAssistant(full)
        }
        let assistant = ConversationMessage(pet: pet, role: "assistant", content: full)
        modelContext.insert(assistant)
        PetInteractionStreak.recordInteraction(pet: pet)
        pet.lastInteractedAt = Date()
        try modelContext.save()

        await PetMemoryExtractor.extractAndStore(
            pet: pet,
            userLine: trimmed,
            assistantLine: full,
            modelContext: modelContext,
            aiClient: aiClient
        )
    }
}
