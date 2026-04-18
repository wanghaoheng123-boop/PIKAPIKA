import Foundation
import Combine
import PikaCore

#if os(macOS)
import AppKit
import Carbon.HIToolbox

/// macOS implementation of `ActivitySource`. Publishes a `UserActivity`
/// sample every `sampleInterval` seconds. Requires Accessibility permission
/// for global key event monitoring.
public final class MacActivityMonitor: ActivitySource, @unchecked Sendable {

    public let activityPublisher: AnyPublisher<UserActivity, Never>
    private let subject = PassthroughSubject<UserActivity, Never>()

    private var keyMonitor: Any?
    private var timer: Timer?
    private var keystrokeTimestamps: [Date] = []
    private let lock = NSLock()
    private let sampleInterval: TimeInterval

    public init(sampleInterval: TimeInterval = 5) {
        self.sampleInterval = sampleInterval
        self.activityPublisher = subject.eraseToAnyPublisher()
    }

    public func start() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            guard let self else { return }
            self.lock.lock()
            self.keystrokeTimestamps.append(Date())
            self.lock.unlock()
        }

        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.emit()
        }
    }

    public func stop() {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        keyMonitor = nil
        timer?.invalidate()
        timer = nil
    }

    private func emit() {
        lock.lock()
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        keystrokeTimestamps = keystrokeTimestamps.filter { $0 > oneMinuteAgo }
        let kpm = Double(keystrokeTimestamps.count)
        lock.unlock()

        let idle = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .init(~0)) ?? 0
        let front = NSWorkspace.shared.frontmostApplication
        let bundleID = front?.bundleIdentifier ?? ""
        let ctx = AppContextMapper.context(for: bundleID)

        subject.send(UserActivity(
            keystrokesPerMinute: kpm,
            idleSeconds: idle,
            activeApp: ctx,
            activeBundleID: bundleID,
            timestamp: Date()
        ))
    }

    deinit { stop() }
}
#endif

#if os(iOS)
import UIKit

/// iOS implementation. iOS can't monitor global keystrokes or foreground
/// bundle IDs of other apps, so this emits simpler samples based on the app
/// being active/background and scene activity.
public final class IOSActivityMonitor: ActivitySource, @unchecked Sendable {

    public let activityPublisher: AnyPublisher<UserActivity, Never>
    private let subject = PassthroughSubject<UserActivity, Never>()
    private var timer: Timer?
    private var lastForegroundAt: Date = Date()

    public init() {
        self.activityPublisher = subject.eraseToAnyPublisher()
    }

    public func start() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.emit()
        }
    }

    public func stop() {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }

    @objc private func didBecomeActive() { lastForegroundAt = Date() }

    private func emit() {
        let idle = Date().timeIntervalSince(lastForegroundAt)
        subject.send(UserActivity(
            keystrokesPerMinute: 0,
            idleSeconds: idle,
            activeApp: .unknown,
            activeBundleID: Bundle.main.bundleIdentifier ?? "",
            timestamp: Date()
        ))
    }
}
#endif
