import Foundation
import PikaCore

/// Maps macOS bundle identifiers to `AppContext`. Extend the tables as needed;
/// unknown bundles fall back to `.unknown` (pet stays idle).
public enum AppContextMapper {

    public static func context(for bundleID: String) -> AppContext {
        let id = bundleID.lowercased()
        if Self.coding.contains(where: id.contains)     { return .coding }
        if Self.browsing.contains(where: id.contains)   { return .browsing }
        if Self.music.contains(where: id.contains)      { return .music }
        if Self.messaging.contains(where: id.contains)  { return .messaging }
        if Self.documents.contains(where: id.contains)  { return .documents }
        if Self.terminal.contains(where: id.contains)   { return .terminal }
        if Self.design.contains(where: id.contains)     { return .design }
        if Self.video.contains(where: id.contains)      { return .video }
        if Self.email.contains(where: id.contains)      { return .email }
        return .unknown
    }

    private static let coding    = ["xcode", "vscode", "com.microsoft.vscode", "intellij", "jetbrains"]
    private static let browsing  = ["safari", "chrome", "firefox", "arc", "brave"]
    private static let music     = ["spotify", "music", "apple.music"]
    private static let messaging = ["slack", "discord", "teams", "messages", "telegram", "whatsapp"]
    private static let documents = ["pages", "word", "docs", "notion", "obsidian"]
    private static let terminal  = ["terminal", "iterm", "warp", "alacritty", "kitty"]
    private static let design    = ["figma", "sketch", "photoshop", "illustrator", "affinity"]
    private static let video     = ["youtube", "netflix", "zoom", "quicktime", "vlc"]
    private static let email     = ["mail", "outlook", "spark", "airmail"]
}
