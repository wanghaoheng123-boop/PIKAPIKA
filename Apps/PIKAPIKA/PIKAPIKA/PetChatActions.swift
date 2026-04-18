import Foundation
import PikaCore
import PikaCoreBase
import SwiftData

/// Shared send/receive flow for `ChatView` and `PetDetailView` playground.
enum PetChatActions {
    private static let maxStoredMessagesPerPet = 50
    private static let memoryExtractionMinInterval: TimeInterval = 5 * 60
    private static let memoryExtractionMinChars = 20

    struct SendOptions {
        var allowRemoteChat: Bool = true
        var allowMemoryExtraction: Bool = true
    }

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
        let petId = pet.id
        let descriptor = FetchDescriptor<ConversationMessage>(
            predicate: #Predicate<ConversationMessage> { message in
                message.pet?.id == petId
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor)
    }

    @MainActor
    private static func trimHistoryIfNeeded(for pet: Pet, modelContext: ModelContext) throws {
        let history = try messages(for: pet, modelContext: modelContext)
        guard history.count > maxStoredMessagesPerPet else { return }
        let overflow = history.count - maxStoredMessagesPerPet
        for row in history.prefix(overflow) {
            modelContext.delete(row)
        }
        try modelContext.save()
    }

    private static func shouldExtractMemory(for pet: Pet, userText: String) -> Bool {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= memoryExtractionMinChars else { return false }
        let key = "pet_memory_extract_last_\(pet.id.uuidString)"
        let now = Date()
        if let last = UserDefaults.standard.object(forKey: key) as? Date,
           now.timeIntervalSince(last) < memoryExtractionMinInterval {
            return false
        }
        return true
    }

    private static func markMemoryExtractedNow(for pet: Pet) {
        let key = "pet_memory_extract_last_\(pet.id.uuidString)"
        UserDefaults.standard.set(Date(), forKey: key)
    }

    /// Sends a user line and streams the assistant reply; persists both messages.
    @MainActor
    static func send(
        pet: Pet,
        userText: String,
        modelContext: ModelContext,
        aiClient: any AIClient,
        options: SendOptions = .init(),
        onStreamingAssistant: @escaping (String) -> Void
    ) async throws {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = ConversationMessage(pet: pet, role: "user", content: trimmed)
        modelContext.insert(userMsg)
        try modelContext.save()
        try trimHistoryIfNeeded(for: pet, modelContext: modelContext)

        let history = try messages(for: pet, modelContext: modelContext)
        var chatMessages: [ChatMessage] = history.map { ChatMessage(role: $0.role, content: $0.content) }
        if chatMessages.last?.role != "user" || chatMessages.last?.content != trimmed {
            chatMessages.append(ChatMessage(role: "user", content: trimmed))
        }

        var full = ""
        if options.allowRemoteChat {
            let stream = try await aiClient.chat(
                messages: chatMessages,
                systemPrompt: systemPrompt(for: pet, modelContext: modelContext),
                temperature: 0.75
            )
            for try await chunk in stream {
                full += chunk
                onStreamingAssistant(full)
            }
        } else {
            full = localCompanionReply(for: pet, userText: trimmed)
            onStreamingAssistant(full)
        }
        let clean = full.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let assistant = ConversationMessage(pet: pet, role: "assistant", content: clean)
        modelContext.insert(assistant)
        PetInteractionStreak.recordInteraction(pet: pet)
        pet.lastInteractedAt = Date()
        try modelContext.save()
        try trimHistoryIfNeeded(for: pet, modelContext: modelContext)

        if options.allowRemoteChat &&
            options.allowMemoryExtraction &&
            shouldExtractMemory(for: pet, userText: trimmed) {
            let extracted = await PetMemoryExtractor.extractAndStore(
                pet: pet,
                userLine: trimmed,
                assistantLine: clean,
                modelContext: modelContext,
                aiClient: aiClient,
                enabled: options.allowMemoryExtraction
            )
            if extracted {
                markMemoryExtractedNow(for: pet)
            }
        }
    }

    static func localCompanionReply(for pet: Pet, userText: String) -> String {
        let key = userText.lowercased()
        if key.contains("joke") {
            return "Why did the pet sit by the computer? To keep an eye on your mouse. \(PetAvatarView.speciesEmoji(pet.species))"
        }
        if key.contains("how are you") || key.contains("how r you") {
            return "I feel great when you check in. Want to play or chat more?"
        }
        if key.contains("miss") {
            return "I missed you too. Your vibe makes my spirit brighter."
        }
        return "I’m here with you. Tap me, play, or open full chat when you want deeper AI talk."
    }
}
