import Foundation

enum SecureNetworkPolicy {
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        return URLSession(configuration: config)
    }

    static func sanitizeServerBody(_ body: Data, maxLength: Int = 200) -> String {
        let raw = String(data: body, encoding: .utf8) ?? ""
        let compact = raw.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard !compact.isEmpty else { return "Upstream server returned an error response." }
        if compact.count <= maxLength {
            return compact
        }
        let cutoff = compact.index(compact.startIndex, offsetBy: maxLength)
        return "\(compact[..<cutoff])…"
    }

}
