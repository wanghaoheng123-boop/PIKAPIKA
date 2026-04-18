import SwiftUI
import PikaCore
import PikaAI
import SharedUI

struct ChatView: View {
    let pet: Pet

    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var streamingReply: String = ""
    @State private var isSending = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                        ChatBubble(text: msg.content, sender: msg.role == "user" ? .user : .pet)
                    }
                    if !streamingReply.isEmpty {
                        ChatBubble(text: streamingReply, sender: .pet)
                    }
                    if let errorText {
                        Text(errorText)
                            .font(PikaTheme.Typography.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }

            HStack {
                TextField("Say something…", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await send() } }
                Button("Send") { Task { await send() } }
                    .disabled(input.isEmpty || isSending)
                    .keyboardShortcut(.return, modifiers: [.command])
            }
            .padding()
        }
    }

    @MainActor
    private func send() async {
        let userText = input
        input = ""
        messages.append(ChatMessage(role: "user", content: userText))
        streamingReply = ""
        isSending = true
        errorText = nil
        defer { isSending = false }

        do {
            let client = try AIProviderRouter().primaryClient()
            let sys = PromptLibrary.systemPrompt(
                petName: pet.name,
                species: pet.species,
                traits: pet.personalityTraits,
                bondLevel: BondLevel.from(xp: pet.bondXP)
            )
            let stream = try await client.chat(messages: messages, systemPrompt: sys, temperature: 0.8)
            for try await chunk in stream { streamingReply += chunk }
            messages.append(ChatMessage(role: "assistant", content: streamingReply))
            streamingReply = ""
        } catch {
            errorText = error.localizedDescription
        }
    }
}
