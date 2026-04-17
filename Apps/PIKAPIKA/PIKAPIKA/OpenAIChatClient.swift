import Foundation
import PikaCoreBase

/// Minimal OpenAI Chat Completions (non-streaming) behind `AIClient.chat` streaming API.
final class OpenAIChatClient: AIClient, @unchecked Sendable {

    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gpt-4o-mini") {
        self.apiKey = apiKey
        self.model = model
    }

    func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        temperature: Double
    ) async throws -> AsyncThrowingStream<String, Error> {
        var bodyMessages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for m in messages {
            bodyMessages.append(["role": m.role, "content": m.content])
        }
        let payload: [String: Any] = [
            "model": model,
            "temperature": temperature,
            "messages": bodyMessages
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (respData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIClientError.networkUnavailable
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw AIClientError.serverError(statusCode: http.statusCode, body: body)
        }
        guard
            let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw AIClientError.serverError(statusCode: http.statusCode, body: String(data: respData, encoding: .utf8) ?? "")
        }

        return AsyncThrowingStream { continuation in
            continuation.yield(content)
            continuation.finish()
        }
    }

    func generateImage(prompt: String, size: ImageSize) async throws -> Data {
        let apiSize = Self.openAISize(for: size)
        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": apiSize,
            "response_format": "b64_json"
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (respData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIClientError.networkUnavailable
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw AIClientError.serverError(statusCode: http.statusCode, body: body)
        }
        guard
            let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
            let arr = json["data"] as? [[String: Any]],
            let first = arr.first,
            let b64 = first["b64_json"] as? String,
            let decoded = Data(base64Encoded: b64)
        else {
            throw AIClientError.imageGenerationFailed("Missing image data in response.")
        }
        return decoded
    }

    func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        let b64 = imageData.base64EncodedString()
        let pngMagic = Data([0x89, 0x50, 0x4E, 0x47])
        let mime = imageData.starts(with: pngMagic) ? "image/png" : "image/jpeg"
        let messageBlocks: [[String: Any]] = [
            [
                "type": "text",
                "text": prompt
            ],
            [
                "type": "image_url",
                "image_url": [
                    "url": "data:\(mime);base64,\(b64)"
                ]
            ]
        ]
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0.3,
            "messages": [
                [
                    "role": "user",
                    "content": messageBlocks
                ]
            ]
        ]
        let payload = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload

        let (respData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIClientError.networkUnavailable
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw AIClientError.serverError(statusCode: http.statusCode, body: body)
        }
        guard
            let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let replyText = message["content"] as? String
        else {
            throw AIClientError.serverError(statusCode: http.statusCode, body: String(data: respData, encoding: .utf8) ?? "")
        }
        return replyText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func openAISize(for size: ImageSize) -> String {
        switch size {
        case .square256, .square512, .square1024:
            return "1024x1024"
        }
    }
}
