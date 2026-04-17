import AVFoundation
import Foundation
import PikaCore

@MainActor
final class PetSoundEngine {
    static let shared = PetSoundEngine()

    private let synth = AVSpeechSynthesizer()

    private init() {}

    func chirp(for pet: Pet, mood: PetSpiritState) {
        guard pet.soundEnabled else { return }
        let token: String
        switch pet.soundProfileKey {
        case "soft":
            token = ["mhm", "nya", "purr"].randomElement() ?? "mhm"
        case "playful":
            token = ["wee", "boop", "yip"].randomElement() ?? "boop"
        case "robot":
            token = ["beep", "bop", "pi"].randomElement() ?? "beep"
        default:
            token = ["nya", "pik", "chu", "peep"].randomElement() ?? "pik"
        }
        speak(text: token, for: pet, mood: mood, forceCompact: true)
    }

    func speakReplyIfEnabled(_ text: String, for pet: Pet, mood: PetSpiritState) {
        guard pet.soundEnabled else { return }
        speak(text: text, for: pet, mood: mood, forceCompact: false)
    }

    private func speak(text: String, for pet: Pet, mood: PetSpiritState, forceCompact: Bool) {
        let phrase: String
        if forceCompact {
            phrase = text
        } else {
            phrase = String(text.prefix(120))
        }
        guard !phrase.isEmpty else { return }

        let u = AVSpeechUtterance(string: phrase)
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        switch pet.soundProfileKey {
        case "soft":
            u.pitchMultiplier = 1.35
            u.rate = 0.47
            u.volume = 0.7
        case "playful":
            u.pitchMultiplier = 1.55
            u.rate = 0.54
            u.volume = 0.82
        case "robot":
            u.pitchMultiplier = 1.0
            u.rate = 0.5
            u.volume = 0.72
        default:
            u.pitchMultiplier = mood == .radiant ? 1.6 : 1.45
            u.rate = 0.5
            u.volume = 0.78
        }
        synth.speak(u)
    }
}
