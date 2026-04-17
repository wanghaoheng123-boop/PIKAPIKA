import Foundation
import SwiftData

/// One durable fact this pet has learned about the human (or the world), scoped to a single pet.
/// OpenViking-style priority: higher `importance` is surfaced first in prompts.
@Model
public final class PetMemoryFact {
    public var id: UUID
    public var pet: Pet?
    public var content: String
    /// e.g. preference, relationship, schedule, style, goal
    public var category: String
    /// 0 = P2 (nice-to-have), 1 = P1, 2 = P0 (critical)
    public var importance: Int
    public var createdAt: Date
    /// chat, manual, import, ai_extract
    public var source: String

    public init(
        id: UUID = UUID(),
        pet: Pet? = nil,
        content: String,
        category: String = "fact",
        importance: Int = 1,
        createdAt: Date = Date(),
        source: String = "ai_extract"
    ) {
        self.id = id
        self.pet = pet
        self.content = content
        self.category = category
        self.importance = importance
        self.createdAt = createdAt
        self.source = source
    }
}
