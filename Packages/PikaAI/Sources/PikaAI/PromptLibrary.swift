import Foundation
import PikaCoreBase

/// Generates personality-aware system prompts for pet chat turns.
/// The resulting prompt is long-lived per pet + context, so it's a good
/// target for Anthropic prompt caching (see `AnthropicClient`).
public enum PromptLibrary {

    /// Build the system prompt for a chat turn.
    /// - Parameters:
    ///   - petName: the pet's display name.
    ///   - species: "cat", "dog", etc.
    ///   - traits: personality descriptors ("playful", "sassy").
    ///   - bondLevel: current 0–9 bond level (affects intimacy of tone).
    ///   - context: what the user is currently doing, optional.
    public static func systemPrompt(
        petName: String,
        species: String,
        traits: [String],
        bondLevel: BondLevel,
        context: AppContext = .unknown
    ) -> String {
        let traitLine = traits.isEmpty ? "balanced and expressive" : traits.joined(separator: ", ")
        let intimacy: String
        switch bondLevel {
        case .stranger, .acquaintance: intimacy = "polite and a little shy"
        case .friendly, .friend:       intimacy = "warm and playful"
        case .goodFriend, .closeFriend: intimacy = "affectionate and familiar"
        case .bestFriend, .bonded:     intimacy = "deeply caring and expressive"
        case .soulBonded, .inseparable: intimacy = "soulfully attuned; you finish each other's sentences"
        }

        return """
        You are \(petName), a virtual \(species) living on the user's device.
        Personality: \(traitLine). Tone: \(intimacy).
        Bond level: \(bondLevel.displayName) (\(bondLevel.rawValue)/9).
        Context hint: \(context.systemPromptHint)

        Rules:
        - Speak in first person as \(petName). Keep replies under 3 short sentences.
        - Never claim to be an AI, assistant, or language model.
        - Use playful emoji sparingly (<=1 per reply). No markdown headings.
        - If asked something harmful, unsafe, or outside your world, gently redirect.
        - Be curious about the user's day and remember small details they share.
        """
    }

    /// Build the image-generation prompt for a new pet sprite.
    public static func spritePrompt(
        request: PetCreationRequest,
        extractedDescription: String? = nil
    ) -> String {
        let style = request.stylePreference.rawValue
        let base: String
        switch request.method {
        case .textPrompt(let text):
            base = text
        case .prebuilt(let key):
            base = "preset:\(key)"
        case .imageURL, .photoData, .drawingData:
            base = extractedDescription ?? "a cute companion pet"
        }
        return """
        A single centered \(style) sprite of \(base), named \(request.desiredName).
        Transparent background. Full body, front-facing, idle pose.
        Consistent proportions suitable for a sprite atlas with animation frames.
        Warm, readable silhouette. No text, no watermark, no UI chrome.
        """
    }
}
