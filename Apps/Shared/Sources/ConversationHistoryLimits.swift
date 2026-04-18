import Foundation
import PikaCore
import SwiftData

/// Keeps at most `maxMessagesPerPet` rows per pet, deleting oldest by timestamp.
public enum ConversationHistoryLimits {
    public static let maxMessagesPerPet = 50

    @MainActor
    public static func trimOldestIfNeeded(for pet: Pet, modelContext: ModelContext) throws {
        let petId = pet.id
        let descriptor = FetchDescriptor<ConversationMessage>(
            predicate: #Predicate<ConversationMessage> { message in
                message.pet?.id == petId
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let rows = try modelContext.fetch(descriptor)
        guard rows.count > maxMessagesPerPet else { return }
        let overflow = rows.count - maxMessagesPerPet
        for row in rows.prefix(overflow) {
            modelContext.delete(row)
        }
        try modelContext.save()
    }
}
