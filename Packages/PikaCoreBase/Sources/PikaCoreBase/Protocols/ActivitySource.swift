import Foundation
import Combine

/// Protocol for anything that publishes user activity updates.
/// The real implementation uses CGEventTap; tests use a mock.
public protocol ActivitySource: AnyObject, Sendable {
    var activityPublisher: AnyPublisher<UserActivity, Never> { get }
    func start()
    func stop()
}

/// Protocol for observing pet state changes.
public protocol PetStateObserver: AnyObject {
    func petStateDidChange(from: PetState, to: PetState)
}
