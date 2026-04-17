import Foundation

/// A snapshot of the user's current activity, published by the activity monitor.
public struct UserActivity: Sendable {
    public let keystrokesPerMinute: Double
    public let idleSeconds: TimeInterval
    public let activeApp: AppContext
    public let activeBundleID: String
    public let timestamp: Date

    public init(
        keystrokesPerMinute: Double = 0,
        idleSeconds: TimeInterval = 0,
        activeApp: AppContext = .unknown,
        activeBundleID: String = "",
        timestamp: Date = Date()
    ) {
        self.keystrokesPerMinute = keystrokesPerMinute
        self.idleSeconds = idleSeconds
        self.activeApp = activeApp
        self.activeBundleID = activeBundleID
        self.timestamp = timestamp
    }

    public static let idle = UserActivity()
}

/// A request to generate a new pet sprite.
public struct PetCreationRequest: Sendable {
    public enum Method: Sendable {
        case textPrompt(String)
        case imageURL(URL)
        case photoData(Data)
        case drawingData(Data)
        case prebuilt(String)   // key into bundled preset catalog
    }

    public let method: Method
    public let desiredName: String
    public let stylePreference: StylePreference

    public enum StylePreference: String, Sendable {
        case pixelArt = "pixel art"
        case cartoon = "cartoon"
        case realistic = "realistic"
        case chibi = "chibi"
    }

    public init(method: Method, desiredName: String, stylePreference: StylePreference = .pixelArt) {
        self.method = method
        self.desiredName = desiredName
        self.stylePreference = stylePreference
    }
}
