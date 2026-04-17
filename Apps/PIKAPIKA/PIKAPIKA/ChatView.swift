import SwiftUI
import SwiftData
import PikaCore

struct ChatView: View {
    let pet: Pet

    @Environment(\.modelContext) private var modelContext
    @Environment(AIClientHolder.self) private var aiHolder

    @Query(sort: \ConversationMessage.timestamp) private var allMessages: [ConversationMessage]

    @State private var draft = ""
    @State private var streamingAssistant = ""
    @State private var isSending = false
    @State private var errorText: String?

    private var messages: [ConversationMessage] {
        allMessages.filter { $0.pet?.id == pet.id }
    }

    private var systemPrompt: String {
        let traits = pet.personalityTraits.joined(separator: ", ")
        let base = "You are \(pet.name), a virtual \(pet.species) companion in PIKAPIKA."
        if traits.isEmpty {
            return base
        }
        return "\(base) Personality hints: \(traits)."
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages, id: \.id) { msg in
                            bubble(role: msg.role, text: msg.content)
                                .id(msg.id)
                        }
                        if !streamingAssistant.isEmpty {
                            bubble(role: "assistant", text: streamingAssistant)
                                .id("stream")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: streamingAssistant) { _, _ in
                    withAnimation { proxy.scrollTo("stream", anchor: .bottom) }
                }
            }

            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack {
                TextField("Message", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1 ... 4)
                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func bubble(role: String, text: String) -> some View {
        HStack {
            if role == "user" { Spacer(minLength: 40) }
            Text(text)
                .padding(10)
                .background(role == "user" ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if role != "user" { Spacer(minLength: 40) }
        }
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        errorText = nil
        draft = ""
        isSending = true
        streamingAssistant = ""

        let userMsg = ConversationMessage(pet: pet, role: "user", content: text)
        modelContext.insert(userMsg)
        try? modelContext.save()

        let history = messages.sorted { $0.timestamp < $1.timestamp }
        var chatMessages: [ChatMessage] = history.map { ChatMessage(role: $0.role, content: $0.content) }
        if chatMessages.last?.role != "user" || chatMessages.last?.content != text {
            chatMessages.append(ChatMessage(role: "user", content: text))
        }

        do {
            let stream = try await aiHolder.client.chat(
                messages: chatMessages,
                systemPrompt: systemPrompt,
                temperature: 0.7
            )
            var full = ""
            for try await chunk in stream {
                full += chunk
                streamingAssistant = full
            }
            let assistant = ConversationMessage(pet: pet, role: "assistant", content: full)
            modelContext.insert(assistant)
            streamingAssistant = ""
        } catch {
            errorText = error.localizedDescription
        }

        isSending = false
    }
}
