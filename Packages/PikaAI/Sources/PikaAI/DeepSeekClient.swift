import Foundation
import PikaCoreBase

/// DeepSeek OpenAI-compatible chat (`deepseek-v4-pro`) at `https://api.deepseek.com`.
/// Streaming yields visible assistant `content` deltas only; reasoning / thinking deltas are ignored.
public final class DeepSeekClient: AIClient, @unchecked Sendable {

    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "deepseek-v4-pro",
        baseURL: URL = URL(string: "https://api.deepseek.com")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Chat (streaming)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        let systemRow: [String: Any] = ["role": "system", "content": systemPrompt]
        let chatRows: [[String: Any]] = messages.map { ["role": $0.role, "content": $0.content] as [String: Any] }
        let messageRows: [[String: Any]] = [systemRow] + chatRows
        let body: [String: Any] = [
            "model": model,
            "temperature": temperature,
            "stream": true,
            "messages": messageRows,
            "thinking": ["type": "enabled"] as [String: Any],
            "reasoning_effort": "high"
        ]

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response, body: data)

        let payloadText = String(data: data, encoding: .utf8) ?? ""
        let lines = payloadText.components(separatedBy: .newlines)

        return AsyncThrowingStream { continuation in
            Task {
                for line in lines {
                    guard line.hasPrefix("data:") else { continue }
                    let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    if payload == "[DONE]" { break }
                    guard let lineData = payload.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                          let choices = json["choices"] as? [[String: Any]],
                          let delta = choices.first?["delta"] as? [String: Any] else { continue }
                    let visible = Self.visibleAssistantText(from: delta)
                    if !visible.isEmpty {
                        continuation.yield(visible)
                    }
                }
                continuation.finish()
            }
        }
    }

    /// Extracts user-visible assistant text from a chat completion `delta`, ignoring reasoning-only fields.
    private static func visibleAssistantText(from delta: [String: Any]) -> String {
        if let s = delta["reasoning_content"] as? String, !s.isEmpty { return "" }
        if let s = delta["content"] as? String, !s.isEmpty { return s }
        if let parts = delta["content"] as? [[String: Any]] {
            var out = ""
            for part in parts {
                guard let type = part["type"] as? String else { continue }
                if type == "text", let t = part["text"] as? String { out += t }
            }
            return out
        }
        return ""
    }

    // MARK: - Image generation

    public func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        throw AIClientError.imageGenerationFailed("DeepSeek does not support image generation; use OpenAI.")
    }

    // MARK: - Image description (vision)

    public func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        let b64 = imageData.base64EncodedString()
        let imageURL: [String: Any] = ["url": "data:image/png;base64,\(b64)"]
        let textPart: [String: Any] = ["type": "text", "text": prompt]
        let imagePart: [String: Any] = ["type": "image_url", "image_url": imageURL]
        let contentParts: [Any] = [textPart, imagePart]
        let userMessage: [String: Any] = ["role": "user", "content": contentParts]
        let body: [String: Any] = [
            "model": model,
            "messages": [userMessage]
        ]

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response, body: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            throw AIClientError.serverError(statusCode: 0, body: "malformed vision response")
        }
        if let content = message["content"] as? String, !content.isEmpty {
            return content
        }
        if let parts = message["content"] as? [[String: Any]] {
            var out = ""
            for part in parts {
                if part["type"] as? String == "text", let t = part["text"] as? String {
                    out += t
                }
            }
            if !out.isEmpty { return out }
        }
        throw AIClientError.serverError(statusCode: 0, body: "malformed vision response")
    }

    // MARK: - Helpers

    private static func validate(_ response: URLResponse, body: Data = Data()) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200..<300: return
        case 401:       throw AIClientError.missingAPIKey
        case 429:       throw AIClientError.rateLimited
        case 413:       throw AIClientError.contextTooLong
        default:
            let text = String(data: body, encoding: .utf8) ?? ""
            throw AIClientError.serverError(statusCode: http.statusCode, body: text)
        }
    }
}
