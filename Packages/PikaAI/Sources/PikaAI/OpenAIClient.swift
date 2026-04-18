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
        session: URLSession = .shared
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
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard !apiKey.isEmpty else { throw AIClientError.missingAPIKey }

        var body: [String: Any] = [
            "model": model,
            "temperature": temperature,
            "stream": true,
            "messages": [["role": "system", "content": systemPrompt]] +
                messages.map { ["role": $0.role, "content": $0.content] }
        ]
        _ = body  // silence if mutated later

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await session.bytes(for: request)
        try Self.validate(response)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else { continue }
                        continuation.yield(content)
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
        let body: [String: Any] = [
            "model": visionModel,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(b64)"]]
                ]
            ]]
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
