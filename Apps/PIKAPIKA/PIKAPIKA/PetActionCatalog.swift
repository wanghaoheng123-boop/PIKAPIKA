import Foundation

/// 100+ named moves / moods the 3D playground can play. Motion is mapped procedurally in `PetScene3DView`.
enum PetActionCatalog {
    static let all: [String] = {
        var list: [String] = []
        let core = [
            "idle", "breathe", "blink", "look_around", "perk_up", "stretch", "yawn",
            "walk", "run", "sprint", "tiptoe", "strut", "shuffle", "moonwalk",
            "hop", "jump", "double_jump", "bounce", "pounce", "roll", "somersault",
            "spin", "twirl", "wiggle", "shake", "shiver", "tremble", "vibrate",
            "wave", "high_five", "clap", "point", "nod", "bow", "curtsy", "salute",
            "dance", "disco", "shuffle_dance", "waltz", "breakdance", "macarena",
            "sit", "lie_down", "sleep", "nap", "dream", "snore",
            "eat", "chew", "gulp", "lick", "sip", "feast", "snack",
            "drink", "slurp", "toast",
            "play_dead", "fetch", "chase", "tag", "hide", "peek", "sneak",
            "dig", "burrow", "scratch", "groom", "preen", "fluff",
            "swim", "float", "dive", "splash", "paddle",
            "fly", "hover", "glide", "land", "takeoff",
            "roar", "meow", "bark", "chirp", "squeak", "trill", "hum", "sing",
            "laugh", "giggle", "cry", "sulk", "pout", "glare", "stare", "wink",
            "love", "heart", "kiss", "hug", "cuddle", "nuzzle", "boop",
            "angry", "rage", "stomp", "huff", "puff", "steam",
            "scared", "cower", "flinch", "duck", "shield",
            "brave", "flex", "pose", "hero", "power_up", "charge",
            "magic", "sparkle", "glow", "teleport", "summon", "shield_spell",
            "fire", "ice", "lightning", "earth", "wind", "water", "nature",
            "heal", "buff", "debuff", "curse", "bless",
            "think", "idea", "confused", "dizzy", "facepalm", "shrug",
            "celebrate", "victory", "cheer", "party", "confetti",
            "work", "study", "read", "write", "type", "coffee", "focus",
            "workout", "pushup", "situp", "yoga", "meditate",
            "rain", "snow", "storm", "sunny", "rainbow",
            "photo", "selfie", "pose_flash", "camera_shy",
            "gift", "surprise", "peekaboo", "tickle", "poke",
            "friend", "wave_hello", "goodbye", "miss_you", "come_here",
            "follow", "lead", "guard", "patrol", "alert",
            "roll_over", "beg", "play_bow", "tail_wag", "ears_up",
            "custom_01", "custom_02", "custom_03", "custom_04", "custom_05"
        ]
        list.append(contentsOf: core)
        for i in 1 ... 15 {
            list.append("combo_\(i)")
            list.append("finisher_\(i)")
        }
        return list
    }()

    static var count: Int { all.count }
}
