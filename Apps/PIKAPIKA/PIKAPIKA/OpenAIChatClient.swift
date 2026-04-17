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
        throw AIClientError.imageGenerationFailed("Image generation not wired in OpenAIChatClient yet.")
    }

    func describeImage(_ imageData: Data, prompt: String) async throws -> String {
        throw AIClientError.serverError(statusCode: 501, body: "describeImage not implemented")
    }
}
