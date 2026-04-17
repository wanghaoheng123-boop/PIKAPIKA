import Foundation
import SwiftData

/// The core domain model for a user's virtual pet.
/// Stored via SwiftData and optionally synced via CloudKit.
@Model
public final class Pet {
    public var id: UUID
    public var name: String
    public var species: String               // "cat", "dog", "hamster", "custom"
    public var creationMethod: String        // "photo", "drawing", "prompt", "prebuilt"
    public var spriteAtlasPath: String       // Relative path within App Group container
    public var personalityTraits: [String]   // Flavor AI system prompts, e.g. ["playful", "sassy"]
    public var bondXP: Int
    public var bondLevel: Int                // Cached from BondLevelManager; 0–9
    public var createdAt: Date
    public var lastInteractedAt: Date
    public var streakCount: Int              // Consecutive days with at least one interaction
    public var longestStreak: Int
    public var totalWorkSessionMinutes: Int  // Cumulative minutes pet was present during work

    // Appearance customization
    public var tintColorHex: String?         // Optional accent color override
    public var accessoryKey: String?         // Active cosmetic accessory identifier

    public init(
        id: UUID = UUID(),
        name: String,
        species: String,
        creationMethod: String,
        spriteAtlasPath: String,
        personalityTraits: [String] = [],
        bondXP: Int = 0,
        bondLevel: Int = 0,
        createdAt: Date = Date(),
        lastInteractedAt: Date = Date(),
        streakCount: Int = 0,
        longestStreak: Int = 0,
        totalWorkSessionMinutes: Int = 0,
        tintColorHex: String? = nil,
        accessoryKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.creationMethod = creationMethod
        self.spriteAtlasPath = spriteAtlasPath
        self.personalityTraits = personalityTraits
        self.bondXP = bondXP
        self.bondLevel = bondLevel
        self.createdAt = createdAt
        self.lastInteractedAt = lastInteractedAt
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.totalWorkSessionMinutes = totalWorkSessionMinutes
        self.tintColorHex = tintColorHex
        self.accessoryKey = accessoryKey
    }
}

/// A time-series record of XP-earning events for analytics and debugging.
@Model
public final class BondEvent {
    public var id: UUID
    public var pet: Pet?
    public var eventType: String            // "checkin", "feed", "chat", "worksession", "milestone"
    public var xpAwarded: Int
    public var timestamp: Date
    public var metadata: String?            // Optional JSON blob for event-specific context

    public init(
        id: UUID = UUID(),
        pet: Pet? = nil,
        eventType: String,
        xpAwarded: Int,
        timestamp: Date = Date(),
        metadata: String? = nil
    ) {
        self.id = id
        self.pet = pet
        self.eventType = eventType
        self.xpAwarded = xpAwarded
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// A conversation message exchanged between the user and the pet's AI.
/// Only the last 50 per pet are kept; older ones are purged by background task.
@Model
public final class ConversationMessage {
    public var id: UUID
    public var pet: Pet?
    public var role: String     // "user" or "assistant"
    public var content: String
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        pet: Pet? = nil,
        role: String,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.pet = pet
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// A remote-configured seasonal event (Halloween, Christmas, etc.).
/// Fetched from Cloudflare Worker and persisted locally for offline access.
@Model
public final class SeasonalEvent {
    public var eventID: String              // e.g. "halloween_2025"
    public var name: String
    public var startsAt: Date
    public var endsAt: Date
    public var isActive: Bool
    public var unlockedAnimationKeys: [String]  // Animation names unlocked during the event
    public var iconEmoji: String

    public var isCurrentlyActive: Bool {
        let now = Date()
        return isActive && now >= startsAt && now <= endsAt
    }

    public init(
        eventID: String,
        name: String,
        startsAt: Date,
        endsAt: Date,
        isActive: Bool = true,
        unlockedAnimationKeys: [String] = [],
        iconEmoji: String = "🎉"
    ) {
        self.eventID = eventID
        self.name = name
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.isActive = isActive
        self.unlockedAnimationKeys = unlockedAnimationKeys
        self.iconEmoji = iconEmoji
    }
}
