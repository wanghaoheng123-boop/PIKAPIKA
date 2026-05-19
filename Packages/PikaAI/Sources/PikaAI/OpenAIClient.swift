import Foundation
import PikaCoreBase

/// OpenAI implementation of `AIClient`. Uses `/v1/chat/completions` with SSE
/// streaming, `/v1/images/generations` for sprites, and vision via the chat
/// endpoint's multimodal content array.
public final class OpenAIClient: AIClient, @unchecked Sendable {

    private let apiKey: String
    private let model: String
    private let visionModel: String
    private let imageModel: String
    private let baseURL: URL
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "gpt-4o-mini",
        visionModel: String = "gpt-4o",
        imageModel: String = "dall-e-3",
        baseURL: URL = URL(string: "https://api.openai.com")!,
        session: URLSession = SecureNetworkPolicy.makeSession()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.visionModel = visionModel
        self.imageModel = imageModel
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Chat (streaming)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String?,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        var messageRows: [[String: Any]] = []
        if let prompt = systemPrompt, !prompt.isEmpty {
            messageRows.append(["role": "system", "content": prompt])
        }
        let chatRows: [[String: Any]] = messages.map { ["role": $0.role, "content": $0.content] as [String: Any] }
        messageRows.append(contentsOf: chatRows)
        let body: [String: Any] = [
            "model": model,
            "temperature": temperature,
            "stream": true,
            "messages": messageRows
        ]

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
                        case .ignore:
                            continue
                        case .done:
                            continuation.finish()
                            return
                        case .data(let payload):
                            guard let lineData = payload.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                                  let choices = json["choices"] as? [[String: Any]],
                                  let delta = choices.first?["delta"] as? [String: Any],
                                  let content = delta["content"] as? String else {
                                continue
                            }
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Image generation

    public func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        let body: [String: Any] = [
            "model": imageModel,
            "prompt": prompt,
            "size": size.rawValue,
            "n": 1,
            "response_format": "b64_json"
        ]

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/images/generations"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response, body: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let b64 = dataArray.first?["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64) else {
            throw AIClientError.imageGenerationFailed("Malformed response")
        }
        return imageData
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
            "model": visionModel,
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
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIClientError.serverError(statusCode: 0, body: "malformed vision response")
        }
        return content
    }

    // MARK: - Helpers

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
