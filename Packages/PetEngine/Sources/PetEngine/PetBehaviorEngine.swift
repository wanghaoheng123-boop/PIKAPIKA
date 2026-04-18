import Foundation
import PikaCore

/// Translates a stream of `UserActivity` samples into `PetState` transitions.
/// Pure logic; no timers or Combine — the caller drives it with samples.
public actor PetBehaviorEngine {

    public private(set) var currentState: PetState = .idle
    public private(set) var lastTransitionAt: Date = .distantPast

    /// Minimum time between transitions to avoid animation thrash.
    public var debounceInterval: TimeInterval = 1.5
    /// Idle threshold before the pet goes to sleep.
    public var sleepAfter: TimeInterval = 300

    public init() {}

    /// Feed a new activity sample and receive the resulting state (possibly
    /// unchanged if within the debounce window).
    @discardableResult
    public func ingest(_ activity: UserActivity) -> PetState {
        let proposed = Self.proposedState(for: activity, sleepAfter: sleepAfter)
        let now = activity.timestamp
        if proposed != currentState,
           now.timeIntervalSince(lastTransitionAt) >= debounceInterval {
            currentState = proposed
            lastTransitionAt = now
        }
        return currentState
    }

    /// Force a transient state (celebrating, sad) that overrides normal behavior.
    public func override(_ state: PetState, at date: Date = Date()) {
        currentState = state
        lastTransitionAt = date
    }

    /// Pure function exposed for unit tests.
    public static func proposedState(
        for activity: UserActivity,
        sleepAfter: TimeInterval
    ) -> PetState {
        if activity.idleSeconds >= sleepAfter { return .sleeping }
        if activity.keystrokesPerMinute > 5 {
            return .typing(intensity: TypingIntensity.classify(
                keystrokesPerMinute: activity.keystrokesPerMinute
            ))
        }
        if activity.activeApp != .unknown { return .reacting(context: activity.activeApp) }
        if activity.idleSeconds > 60 { return .curious }
        return .idle
    }
}
