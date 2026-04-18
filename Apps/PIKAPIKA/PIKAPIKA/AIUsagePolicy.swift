import Foundation

struct AIUsagePolicy: Equatable {
    var allowRemoteChat: Bool
    var allowRemoteImage: Bool
    var allowRemoteMemoryExtraction: Bool

    static let `default` = AIUsagePolicy(
        allowRemoteChat: true,
        allowRemoteImage: true,
        allowRemoteMemoryExtraction: true
    )
}

enum AIUsagePolicyStore {
    private static let defaults = UserDefaults.standard
    private static let chatKey = "ai_policy_remote_chat"
    private static let imageKey = "ai_policy_remote_image"
    private static let memoryKey = "ai_policy_remote_memory"

    static func load() -> AIUsagePolicy {
        if defaults.object(forKey: chatKey) == nil {
            save(.default)
            return .default
        }
        return AIUsagePolicy(
            allowRemoteChat: defaults.bool(forKey: chatKey),
            allowRemoteImage: defaults.bool(forKey: imageKey),
            allowRemoteMemoryExtraction: defaults.bool(forKey: memoryKey)
        )
    }

    static func save(_ p: AIUsagePolicy) {
        defaults.set(p.allowRemoteChat, forKey: chatKey)
        defaults.set(p.allowRemoteImage, forKey: imageKey)
        defaults.set(p.allowRemoteMemoryExtraction, forKey: memoryKey)
    }
}
