import SwiftUI
import SwiftData
import PikaCore
import PikaAI
import SharedUI

/// SwiftData-backed pet chat with provider fallback, trim-to-50, and retry when the assistant stream fails after the user message was saved.
///
/// **Persistence policy:** If `save()` fails after inserting the user row, the pending row is removed from the context. If `save()` succeeds but trim (or later steps in that block) fails, the user line stays persisted and `awaitingAssistantRetry` is set so **Retry** can complete the assistant turn.
public struct PetChatScreen: View {
    let pet: Pet

    @Environment(\.modelContext) private var modelContext
    @Query private var persistedMessages: [ConversationMessage]

    @AppStorage(PikaUserDefaultsKeys.aiProviderPreference) private var preferenceRaw: String =
        AIProviderRouter.Preference.anthropicPrimary.rawValue

    @State private var input = ""
    @State private var streamingReply = ""
    @State private var isSending = false
    @State private var errorText: String?
    /// True when the last user line is in SwiftData but the assistant reply failed; Retry completes only the assistant turn.
    @State private var awaitingAssistantRetry = false

    public init(pet: Pet) {
        self.pet = pet
        let petId = pet.id
        _persistedMessages = Query(
            filter: #Predicate<ConversationMessage> { message in
                message.pet?.id == petId
            },
            sort: \ConversationMessage.timestamp
        )
    }

    private var preference: AIProviderRouter.Preference {
        AIProviderRouter.Preference(rawValue: preferenceRaw) ?? .anthropicPrimary
    }

    private var canRetryAssistant: Bool {
        awaitingAssistantRetry && persistedMessages.last?.role == "user"
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
                        ForEach(persistedMessages, id: \.id) { msg in
                            ChatBubble(
                                text: msg.content,
                                sender: msg.role == "user" ? .user : .pet
                            )
                            .id(msg.id)
                        }
                        if !streamingReply.isEmpty {
                            ChatBubble(text: streamingReply, sender: .pet)
                                .id("stream")
                        }
                        errorSection
                        Color.clear.frame(height: 1).id("chatBottomAnchor")
                    }
                    .padding()
                }
                .onChange(of: persistedMessages.count) { _, _ in
                    scrollChatToBottom(proxy: proxy)
                }
                .onChange(of: streamingReply) { _, _ in
                    scrollChatToBottom(proxy: proxy)
                }
            }

            if isSending {
                HStack(spacing: PikaTheme.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text(streamingReply.isEmpty ? "Waiting for reply…" : "Receiving…")
                        .font(PikaTheme.Typography.caption)
                        .foregroundStyle(PikaTheme.Palette.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PikaTheme.Spacing.xs)
            }

            composer
        }
        .navigationTitle(pet.name)
    }

    private func scrollChatToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if !streamingReply.isEmpty {
                proxy.scrollTo("stream", anchor: .bottom)
            } else if let last = persistedMessages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            } else {
                proxy.scrollTo("chatBottomAnchor", anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorText {
            VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
                Text(errorText)
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(.red)
                if canRetryAssistant {
                    Button("Retry") {
                        Task { await completeAssistantTurn() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSending)
                    .accessibilityLabel("Retry assistant reply")
                    .accessibilityHint("Sends your last message to the AI again without duplicating it.")
                }
            }
        }
    }

    private var composer: some View {
        HStack {
            TextField("Say something…", text: $input)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Message text field")
                .onSubmit { Task { await sendNewUserMessage() } }
            Button("Send") { Task { await sendNewUserMessage() } }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .accessibilityLabel("Send message")
                .accessibilityHint("Sends your message to your pet.")
                #if os(macOS)
                .keyboardShortcut(.return, modifiers: [.command])
                #endif
        }
        .padding()
    }

    @MainActor
    private func sendNewUserMessage() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        input = ""
        errorText = nil
        awaitingAssistantRetry = false
        isSending = true
        streamingReply = ""
        defer { isSending = false }

        let userRow = ConversationMessage(pet: pet, role: "user", content: trimmed)
        modelContext.insert(userRow)
        var userCommittedToStore = false
        do {
            try modelContext.save()
            userCommittedToStore = true
            try ConversationHistoryLimits.trimOldestIfNeeded(for: pet, modelContext: modelContext)
        } catch {
            errorText = error.localizedDescription
            if userCommittedToStore {
                awaitingAssistantRetry = true
            } else {
                modelContext.delete(userRow)
                try? modelContext.save()
            }
            return
        }

        await completeAssistantTurn()
    }

    /// Streams assistant reply for current history (after optional new user row was persisted).
    @MainActor
    private func completeAssistantTurn() async {
        errorText = nil
        isSending = true
        streamingReply = ""
        defer { isSending = false }

        let apiMessages: [ChatMessage] = persistedMessages.map {
            ChatMessage(role: $0.role, content: $0.content)
        }
        let systemPrompt = PromptLibrary.systemPrompt(
            petName: pet.name,
            species: pet.species,
            traits: pet.personalityTraits,
            bondLevel: BondLevel.from(xp: pet.bondXP)
        )
        let router = AIProviderRouter(preference: preference)
        var accumulated = ""
        do {
            try await router.runChatWithFallback(
                messages: apiMessages,
                systemPrompt: systemPrompt,
                temperature: 0.8,
                onChunk: { chunk in
                    accumulated += chunk
                    streamingReply = accumulated
                }
            )
            let clean = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else {
                errorText = "The model returned an empty reply."
                awaitingAssistantRetry = true
                streamingReply = ""
                return
            }
            modelContext.insert(ConversationMessage(pet: pet, role: "assistant", content: clean))
            try modelContext.save()
            try ConversationHistoryLimits.trimOldestIfNeeded(for: pet, modelContext: modelContext)
            streamingReply = ""
            awaitingAssistantRetry = false
        } catch {
            errorText = error.localizedDescription
            awaitingAssistantRetry = true
            streamingReply = ""
        }
    }
}
