import SwiftUI
import SwiftData
import PikaCore
import PikaCoreBase
import PikaAI
import PikaSubscription
import SharedUI

/// SwiftData-backed pet chat with provider fallback, trim-to-50, and retry when the assistant stream fails after the user message was saved.
///
/// **Persistence policy:** If `save()` fails after inserting the user row, the pending row is removed from the context. If `save()` succeeds but trim (or later steps in that block) fails, the user line stays persisted and `awaitingAssistantRetry` is set so **Retry** can complete the assistant turn.
public struct PetChatScreen: View {
    let pet: Pet

    @Environment(\.modelContext) private var modelContext
    @Query private var persistedMessages: [ConversationMessage]
    @Query private var bondEvents: [BondEvent]

    @AppStorage(PikaUserDefaultsKeys.aiProviderPreference) private var preferenceRaw: String =
        AIProviderRouter.Preference.anthropicPrimary.rawValue

    @State private var input = ""
    @State private var streamingReply = ""
    @State private var isSending = false
    @State private var errorText: String?
    /// True when the last user line is in SwiftData but the assistant reply failed; Retry completes only the assistant turn.
    @State private var awaitingAssistantRetry = false
    @State private var latestLevelUp: BondProgression.LevelUp?
    @State private var showSubscriptionOffer = false
    @ObservedObject private var subscriptionManager = SharedSubscriptionManager.instance
    @State private var pendingStreamScrollTask: Task<Void, Never>?
    private let streamScrollThrottleSeconds: TimeInterval = 0.12

    public init(pet: Pet) {
        self.pet = pet
        let petId = pet.id
        _persistedMessages = Query(
            filter: #Predicate<ConversationMessage> { message in
                message.pet?.id == petId
            },
            sort: \ConversationMessage.timestamp
        )
        _bondEvents = Query(
            filter: #Predicate<BondEvent> { event in
                event.pet?.id == petId
            },
            sort: [SortDescriptor(\BondEvent.timestamp, order: .reverse)]
        )
    }

    private var preference: AIProviderRouter.Preference {
        AIProviderRouter.Preference(rawValue: preferenceRaw) ?? .anthropicPrimary
    }

    private var canRetryAssistant: Bool {
        awaitingAssistantRetry && persistedMessages.last?.role == "user"
    }

    private var hasAnyAPIKey: Bool {
        let o = (KeychainHelper.load(.openAIKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let a = (KeychainHelper.load(.anthropicKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let d = (KeychainHelper.load(.deepSeekKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !o.isEmpty || !a.isEmpty || !d.isEmpty
    }

    public var body: some View {
        VStack(spacing: 0) {
            bondStatusHeader
            if !hasAnyAPIKey {
                Label(
                    "Cloud chat needs an API key. Open Settings from the home screen and add Anthropic, OpenAI, and/or DeepSeek.",
                    systemImage: "key.horizontal"
                )
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
                .padding(PikaTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PikaTheme.Palette.accent.opacity(0.12))
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
                        ForEach(persistedMessages, id: \.id) { msg in
                            ChatBubble(
                                text: msg.content,
                                sender: msg.role == "user" ? .user : .pet,
                                timestamp: msg.timestamp
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
                    pendingStreamScrollTask?.cancel()
                    scrollChatToBottom(proxy: proxy, animated: true)
                }
                .onChange(of: streamingReply) { _, _ in
                    scheduleStreamingScroll(proxy: proxy)
                }
            }

            if isSending {
                HStack(spacing: PikaTheme.Spacing.sm) {
                    TypingIndicator()
                    Text(streamingReply.isEmpty ? "Waiting for reply…" : "Receiving…")
                        .font(PikaTheme.Typography.caption)
                        .foregroundStyle(PikaTheme.Palette.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PikaTheme.Spacing.md)
                .padding(.vertical, PikaTheme.Spacing.xs)
            }

            composer
        }
        .navigationTitle(pet.name)
        .sheet(isPresented: $showSubscriptionOffer) {
            SubscriptionOfferSheet(subscriptionManager: subscriptionManager, source: "chat_daily_cap") {
                showSubscriptionOffer = false
                PaywallPresentationGate.endPresentation(source: "chat_daily_cap")
            }
        }
        .onDisappear {
            pendingStreamScrollTask?.cancel()
        }
        .task {
            await SharedSubscriptionManager.refreshIfNeeded()
        }
        .overlay(alignment: .top) {
            if let levelUp = latestLevelUp {
                Text("Level up! \(levelUp.from.displayName) → \(levelUp.to.displayName)")
                    .font(PikaTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, PikaTheme.Spacing.md)
                    .padding(.vertical, PikaTheme.Spacing.sm)
                    .background(PikaTheme.Palette.accentDeep)
                    .clipShape(Capsule())
                    .padding(.top, PikaTheme.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var todayXP: Int {
        PetInteractionStreak.xpEarnedToday(petID: pet.id)
    }

    private var latestBondEvent: BondEvent? {
        bondEvents.first
    }

    private var bondStatusHeader: some View {
        VStack(alignment: .leading, spacing: PikaTheme.Spacing.xs) {
            Text("Bond today: \(todayXP)/\(BondProgression.dailyCap) XP • Streak \(pet.streakCount)")
                .font(PikaTheme.Typography.caption.weight(.semibold))
                .foregroundStyle(PikaTheme.Palette.textMuted)
            if let latestBondEvent {
                Text("Latest: +\(latestBondEvent.xpAwarded) XP from \(latestBondEvent.eventType)")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PikaTheme.Spacing.md)
        .padding(.vertical, PikaTheme.Spacing.xs)
        .background(PikaTheme.Palette.accent.opacity(0.08))
    }

    private func scrollChatToBottom(proxy: ScrollViewProxy, animated: Bool) {
        let scrollAction = {
            if !streamingReply.isEmpty {
                proxy.scrollTo("stream", anchor: .bottom)
            } else if let last = persistedMessages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            } else {
                proxy.scrollTo("chatBottomAnchor", anchor: .bottom)
            }
        }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                scrollAction()
            }
        } else {
            scrollAction()
        }
    }

    private func scheduleStreamingScroll(proxy: ScrollViewProxy) {
        pendingStreamScrollTask?.cancel()
        let delay = UInt64(streamScrollThrottleSeconds * 1_000_000_000)
        pendingStreamScrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            scrollChatToBottom(proxy: proxy, animated: false)
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
        HStack(spacing: PikaTheme.Spacing.sm) {
            Button {
                // Voice input placeholder — integrate VoiceInputManager when ready
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(PikaTheme.Palette.textMuted)
                    .frame(width: 36, height: 36)
                    .background(PikaTheme.Palette.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voice input")

            TextField("Say something…", text: $input)
                .textFieldStyle(.roundedBorder)
                .font(PikaTheme.Typography.chat)
                .accessibilityLabel("Message text field")
                .onSubmit { Task { await sendNewUserMessage() } }

            Button { Task { await sendNewUserMessage() } } label: {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                    }
                }
                .foregroundStyle(canSend ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.textMuted)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
            .accessibilityHint("Sends your message to your pet.")
            #if os(macOS)
            .keyboardShortcut(.return, modifiers: [.command])
            #endif
        }
        .padding(.horizontal, PikaTheme.Spacing.md)
        .padding(.vertical, PikaTheme.Spacing.sm)
        .background(
            Rectangle()
                .fill(PikaTheme.Palette.warmBg)
                .shadow(color: .black.opacity(0.06), radius: 8, y: -4)
        )
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
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
            do {
                try ConversationHistoryLimits.trimOldestIfNeeded(for: pet, modelContext: modelContext)
            } catch {
                print("Failed to trim conversation history: \(error)")
            }
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

        // Build memory facts list for system prompt
        let memoryFacts = fetchMemoryFacts()

        let apiMessages: [ChatMessage] = persistedMessages.map {
            ChatMessage(role: $0.role, content: $0.content)
        }
        let systemPrompt = PromptLibrary.systemPrompt(
            petName: pet.name,
            species: pet.species,
            traits: pet.personalityTraits,
            bondLevel: BondLevel.from(xp: pet.bondXP),
            creatureDescription: pet.creatureDescription,
            memoryFacts: memoryFacts
        )
        let router = AIProviderRouter(preference: preference)
        var accumulated = ""
        let lastUserLine = persistedMessages.last(where: { $0.role == "user" })?.content
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
            let assistantRow = ConversationMessage(pet: pet, role: "assistant", content: clean)
            modelContext.insert(assistantRow)
            try modelContext.save()
            do {
                try ConversationHistoryLimits.trimOldestIfNeeded(for: pet, modelContext: modelContext)
            } catch {
                print("Failed to trim conversation history: \(error)")
            }

<<<<<<< HEAD
            // Record daily streak and update last-interaction time
            PetInteractionStreak.recordStreak(pet: pet)
            pet.lastInteractedAt = Date()
            do {
                try modelContext.save()
            } catch {
                print("Failed to save streak update: \(error)")
=======
            do {
                let outcome = try PetInteractionStreak.applyBondEvent(.chatMessage, to: pet, modelContext: modelContext)
                if outcome.awardedXP == 0 {
                    await subscriptionManager.refreshEntitlements()
                    if subscriptionManager.currentEntitlements == .free,
                       PaywallPresentationGate.beginPresentation(source: "chat_daily_cap") {
                        showSubscriptionOffer = true
                    }
                }
                if let levelUp = outcome.levelUp {
                    withAnimation {
                        latestLevelUp = levelUp
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation {
                            latestLevelUp = nil
                        }
                    }
                }
            } catch {
                print("Failed to save bond event for chat: \(error)")
>>>>>>> ec0be87 (chore: checkpoint autonomous quality and orchestration updates)
            }

            // Attempt memory extraction from this exchange
            if let lastUserLine {
                await attemptMemoryExtraction(
                    userLine: lastUserLine,
                    assistantLine: clean,
                    router: router
                )
            }

            streamingReply = ""
            awaitingAssistantRetry = false
        } catch {
            errorText = error.localizedDescription
            awaitingAssistantRetry = true
            streamingReply = ""
        }
    }

    @MainActor
    private func fetchMemoryFacts() -> [String] {
        let petId = pet.id
        let descriptor = FetchDescriptor<PetMemoryFact>(
            predicate: #Predicate<PetMemoryFact> { fact in
                fact.pet?.id == petId
            },
            sortBy: [
                SortDescriptor(\.importance, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return rows.prefix(12).map(\.content)
    }

    @MainActor
    private func attemptMemoryExtraction(
        userLine: String,
        assistantLine: String,
        router: AIProviderRouter
    ) async {
        let trimmed = userLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5 else { return }

        let key = "pet_memory_extract_last_\(pet.id.uuidString)"
        if let last = UserDefaults.standard.object(forKey: key) as? Date,
           Date().timeIntervalSince(last) < 5 * 60 {
            return
        }

        guard let client = try? router.primaryClient() else { return }
        let extracted = await PetMemoryExtractor.extractAndStore(
            pet: pet,
            userLine: userLine,
            assistantLine: assistantLine,
            modelContext: modelContext,
            aiClient: client,
            enabled: true
        )
        if extracted {
            UserDefaults.standard.set(Date(), forKey: key)
        }
    }
}
