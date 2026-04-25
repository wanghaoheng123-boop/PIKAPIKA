import Foundation
import PikaCoreBase

/// Anthropic implementation of `AIClient`. Uses `/v1/messages` with SSE
/// streaming. The system prompt is marked `cache_control: ephemeral` so
/// repeated chat turns with the same pet personality hit the prompt cache.
public final class AnthropicClient: AIClient, @unchecked Sendable {

    private let apiKey: String
    private let model: String
    private let maxTokens: Int
    private let baseURL: URL
    private let session: URLSession
    private let apiVersion: String

    public init(
        apiKey: String,
        model: String = "claude-sonnet-4-6",
        maxTokens: Int = 1024,
        apiVersion: String = "2023-06-01",
        baseURL: URL = URL(string: "https://api.anthropic.com")!,
        session: URLSession = SecureNetworkPolicy.makeSession()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        self.apiVersion = apiVersion
        self.baseURL = baseURL
        self.session = session
    }

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String?,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        let userMessages: [[String: Any]] = messages
            .filter { $0.role != "system" }
            .map { [
                "role": $0.role == "assistant" ? "assistant" : "user",
                "content": $0.content
            ] as [String: Any] }

        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "stream": true,
            "messages": userMessages
        ]

        if let prompt = systemPrompt, !prompt.isEmpty {
            let cacheControl: [String: Any] = ["type": "ephemeral"]
            let systemBlock: [String: Any] = [
                "type": "text",
                "text": prompt,
                "cache_control": cacheControl
            ]
            body["system"] = [systemBlock]
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/messages"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw AIClientError.networkUnavailable
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var body = Data()
                        for try await byte in bytes {
                            body.append(byte)
                        }
                        throw Self.httpError(statusCode: http.statusCode, body: body)
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        switch SSELineParser.parseLine(line) {
                        case .ignore, .done:
                            continue
                        case .data(let payload):
                            guard let lineData = payload.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                                continue
                            }

                            let type = json["type"] as? String
                            if type == "content_block_delta",
                               let delta = json["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                continuation.yield(text)
                            } else if type == "message_stop" {
                                continuation.finish()
                                return
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        // Anthropic does not provide native image generation as of this client's
        // target API version. Routing callers should fall back to OpenAI.
        throw AIClientError.imageGenerationFailed("Anthropic does not support image generation; use OpenAI.")
    }

    public func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        let b64 = imageData.base64EncodedString()
        let source: [String: Any] = [
            "type": "base64",
            "media_type": "image/png",
            "data": b64
        ]
        let imagePart: [String: Any] = ["type": "image", "source": source]
        let textPart: [String: Any] = ["type": "text", "text": prompt]
        let contentParts: [Any] = [imagePart, textPart]
        let userMessage: [String: Any] = ["role": "user", "content": contentParts]
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [userMessage]
        ]

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/messages"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response, body: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw AIClientError.serverError(statusCode: 0, body: "malformed vision response")
        }
        return text
    }

    private static func validate(_ response: URLResponse, body: Data = Data()) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw httpError(statusCode: http.statusCode, body: body)
        }
    }

    private static func httpError(statusCode: Int, body: Data) -> AIClientError {
        switch statusCode {
        case 401: return .missingAPIKey
        case 429: return .rateLimited
        case 413: return .contextTooLong
        default:
            return .serverError(statusCode: statusCode, body: SecureNetworkPolicy.sanitizeServerBody(body))
        }
    }
}
