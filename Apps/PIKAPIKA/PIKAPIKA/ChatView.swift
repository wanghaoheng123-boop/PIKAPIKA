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
    @StateObject private var voiceInput = VoiceInputManager()

    private var messages: [ConversationMessage] {
        allMessages.filter { $0.pet?.id == pet.id }
    }

    private var spirit: PetSpiritState { PetSpiritState.evaluate(for: pet) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(spirit.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pet.name) is \(spirit.shortTitle.lowercased())")
                        .font(.caption.weight(.semibold))
                    Text(spirit.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))

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

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Say anything…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .lineLimit(1 ... 5)
                Button {
                    voiceInput.toggle { text in
                        draft = text
                    }
                } label: {
                    Image(systemName: voiceInput.isListening ? "mic.fill" : "mic")
                        .font(.title3)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, PIKAPIKATheme.accent)
                    }
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            if voiceInput.isListening {
                Text(voiceInput.liveText.isEmpty ? "Listening…" : voiceInput.liveText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .background(PIKAPIKATheme.homeBackground.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            voiceInput.stop(commit: false) { _ in }
        }
        .alert("Microphone or speech permission denied", isPresented: $voiceInput.authorizationDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable Speech Recognition and Microphone in Settings to use voice input.")
        }
    }

    @ViewBuilder
    private func bubble(role: String, text: String) -> some View {
        HStack {
            if role == "user" { Spacer(minLength: 40) }
            Text(text)
                .padding(12)
                .background {
                    if role == "user" {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [PIKAPIKATheme.accent.opacity(0.35), PIKAPIKATheme.accentSecondary.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: role == "user" ? 0 : 1)
                }
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

        do {
            try await PetChatActions.send(
                pet: pet,
                userText: text,
                modelContext: modelContext,
                aiClient: aiHolder.client
            ) { partial in
                streamingAssistant = partial
            }
            PetSoundEngine.shared.speakReplyIfEnabled(streamingAssistant, for: pet, mood: spirit)
            streamingAssistant = ""
        } catch {
            errorText = error.localizedDescription
        }

        isSending = false
    }
}
