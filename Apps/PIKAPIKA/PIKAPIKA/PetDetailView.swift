import SwiftData
import SwiftUI
import UIKit
import PikaCore

struct PetDetailView: View {
    @Bindable var pet: Pet

    @Environment(\.modelContext) private var modelContext
    @Environment(AIClientHolder.self) private var aiHolder

    @Query(sort: \ConversationMessage.timestamp, order: .reverse) private var messagesForPet: [ConversationMessage]

    @State private var streamingAssistant = ""
    @State private var reactionBubble: String?
    @State private var reactionTask: Task<Void, Never>?
    @State private var isTalking = false
    @State private var errorText: String?
    @State private var stagedAction = "idle"
    @State private var actionTick = 0
    @State private var showMovesSheet = false
    @State private var showCustomize = false
    @State private var moveSearch = ""
    @State private var levelUpInfo: BondProgression.LevelUp?
    @StateObject private var voiceInput = VoiceInputManager()

    init(pet: Pet) {
        self.pet = pet
        let petId = pet.id
        _messagesForPet = Query(
            filter: #Predicate<ConversationMessage> { message in
                message.pet?.id == petId
            },
            sort: [SortDescriptor(\ConversationMessage.timestamp, order: .reverse)]
        )
    }

    private var lastAssistantSnippet: String? {
        let sorted = messagesForPet
            .filter { $0.role == "assistant" }
            .sorted { $0.timestamp > $1.timestamp }
        guard let msg = sorted.first else { return nil }
        return clip(msg.content, max: 120)
    }

    private var speechBubble: String? {
        if !streamingAssistant.isEmpty { return streamingAssistant }
        if let reactionBubble { return reactionBubble }
        return lastAssistantSnippet
    }

    private let quickPhrases = [
        "Hi!",
        "How are you?",
        "Tell me a joke",
        "I missed you",
        "Want to play?"
    ]

    private var portraitImage: UIImage? {
        PetImageStore.loadImage(relativePath: pet.avatarImagePath)
    }

    private var filteredMoves: [String] {
        let q = moveSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return PetActionCatalog.all }
        return PetActionCatalog.all.filter { $0.lowercased().contains(q) }
    }

    private var hoursAway: Int {
        Int(Date().timeIntervalSince(pet.lastInteractedAt) / 3600)
    }

    private var spirit: PetSpiritState { PetSpiritState.evaluate(for: pet) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PikaMetrics.sectionSpacing) {
                SpiritBondStrip(pet: pet, spirit: spirit)
                    .padding(.horizontal, PikaMetrics.screenHorizontal)

                if hoursAway >= 6 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("While you were away")
                            .font(.subheadline.weight(.semibold))
                        Text("\(pet.name) stayed \(spirit.shortTitle.lowercased()) and waited \(hoursAway)h for your return.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let lastAssistantSnippet {
                            Text("Last thought: \(lastAssistantSnippet)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(PikaMetrics.cardPadding)
                    .background {
                        RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                    .padding(.horizontal, PikaMetrics.screenHorizontal)
                }

                if !pet.creatureDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(pet.creatureDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(PikaMetrics.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        }
                        .padding(.horizontal, PikaMetrics.screenHorizontal)
                }

                PetAvatarView(
                    pet: pet,
                    speechBubble: speechBubble,
                    avatarImage: portraitImage,
                    actionName: stagedAction,
                    actionTick: actionTick,
                    onTapPet: {
                        handlePetTap()
                    }
                )
                .padding(.horizontal, PikaMetrics.screenHorizontal)

                actionBar

                movesButton

                quickPhrasesSection

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, PikaMetrics.screenHorizontal)
                }

                recentChatPreview

                NavigationLink {
                    PetMemoryListView(pet: pet)
                } label: {
                    Label("Heart & memory", systemImage: "heart.text.square.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(PIKAPIKATheme.accentSecondary)
                .padding(.horizontal, PikaMetrics.screenHorizontal)

                NavigationLink {
                    ChatView(pet: pet)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Open full chat")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerMedium, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [PIKAPIKATheme.accent, PIKAPIKATheme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, PikaMetrics.screenHorizontal)
            }
            .padding(.vertical, 8)
        }
        .background(PIKAPIKATheme.homeBackground.ignoresSafeArea())
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCustomize = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Customize pet")
            }
        }
        .sheet(isPresented: $showCustomize) {
            PetCustomizationSheet(pet: pet) { _ in
                triggerAction("pose")
            }
        }
        .sheet(isPresented: $showMovesSheet) {
            NavigationStack {
                List(filteredMoves, id: \.self) { move in
                    Button {
                        triggerAction(move)
                        showMovesSheet = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(move)
                                .font(.body.monospaced())
                                .foregroundStyle(.primary)
                            Text("Tap to play on the 3D stage")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .searchable(text: $moveSearch, prompt: "Search \(PetActionCatalog.count) moves")
                .navigationTitle("Moves")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showMovesSheet = false }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isTalking {
                ProgressView("Thinking…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 8)
            }
        }
        .onDisappear {
            reactionTask?.cancel()
            voiceInput.stop(commit: false) { _ in }
        }
        .alert("Microphone or speech permission denied", isPresented: $voiceInput.authorizationDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable Speech Recognition and Microphone in Settings to use voice input.")
        }
    }

    private var movesButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            PikaSectionHeader(
                title: "Moves & play",
                subtitle: "Pick a move — your companion performs on the 3D stage."
            )
            .padding(.horizontal, PikaMetrics.screenHorizontal)
            Button {
                showMovesSheet = true
            } label: {
                Label("Browse \(PetActionCatalog.count)+ actions", systemImage: "figure.walk.motion")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(PikaSecondaryButtonStyle())
            .padding(.horizontal, PikaMetrics.screenHorizontal)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            actionButton(title: "Pet", symbol: "hand.tap.fill", tint: .pink) {
                awardBond(event: .tapPet)
                triggerAction("nuzzle")
                flashReaction(["So soft!", "Hehe!", "Love that!"].randomElement()!)
            }
            actionButton(title: "Feed", symbol: "leaf.fill", tint: .green) {
                awardBond(event: .feeding)
                triggerAction("eat")
                flashReaction(["Yum!", "Tasty!", "More please!"].randomElement()!)
            }
            actionButton(title: "Play", symbol: "ball.fill", tint: .orange) {
                awardBond(event: .playSession)
                triggerAction("fetch")
                flashReaction(["Catch!", "Zoom!", "Again!"].randomElement()!)
            }
        }
        .padding(.horizontal, PikaMetrics.screenHorizontal)
    }

    private func actionButton(title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title2)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var quickPhrasesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PikaSectionHeader(
                    title: "Quick talk",
                    subtitle: "One tap — they answer with spirit."
                )
                Button {
                    voiceInput.toggle { text in
                        if let intent = VoiceIntentRouter.parse(text) {
                            applyVoiceIntent(intent)
                        } else {
                            Task { await sendWithAI(text) }
                        }
                    }
                } label: {
                    Image(systemName: voiceInput.isListening ? "mic.fill" : "mic")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, PikaMetrics.screenHorizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickPhrases, id: \.self) { phrase in
                        Button {
                            handleQuickPhrase(phrase)
                        } label: {
                            Text(phrase)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .shadow(color: PIKAPIKATheme.shadowSoft, radius: 4, x: 0, y: 2)
                                )
                        }
                        .disabled(isTalking)
                    }
                }
                .padding(.horizontal, PikaMetrics.screenHorizontal)
            }
        }
    }

    private var recentChatPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            PikaSectionHeader(title: "Recent whispers", subtitle: nil)
                .padding(.horizontal, PikaMetrics.screenHorizontal)
            let recent = messagesForPet.sorted { $0.timestamp > $1.timestamp }.prefix(4)
            if recent.isEmpty {
                Text("Tap your pet or send a quick line — they’re listening.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, PikaMetrics.screenHorizontal)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recent.reversed()), id: \.id) { msg in
                        HStack(alignment: .top, spacing: 8) {
                            Text(msg.role == "user" ? "You" : pet.name)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(PIKAPIKATheme.accent)
                                .frame(width: 48, alignment: .leading)
                            Text(msg.content)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(PikaMetrics.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: PIKAPIKATheme.cornerLarge, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground).opacity(0.85))
                }
                .padding(.horizontal, PikaMetrics.screenHorizontal)
            }
        }
    }

    private func triggerAction(_ name: String) {
        stagedAction = name
        actionTick += 1
    }

    private func handlePetTap() {
        awardBond(event: .tap)
        triggerAction("boop")
        PetSoundEngine.shared.chirp(for: pet, mood: spirit)
        let lines: [String]
        switch pet.species.lowercased() {
        case "cat": lines = ["Purr…", "Mrr?", "Pet me more!"]
        case "dog": lines = ["Woof!", "Play?", "Hehe!"]
        case "hamster": lines = ["Squeak!", "Nom?", "Zoom!"]
        default: lines = ["Hi!", "Cute!", "♥"]
        }
        flashReaction(lines.randomElement() ?? "♥")
    }

    private func flashReaction(_ text: String) {
        reactionTask?.cancel()
        reactionBubble = text
        reactionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            reactionBubble = nil
        }
    }

    private func awardBond(event: BondProgression.Event) {
        do {
            let outcome = try PetInteractionStreak.applyBondEvent(event, to: pet, modelContext: modelContext)
            levelUpInfo = outcome.levelUp
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func sendWithAI(_ text: String) async {
        guard !isTalking else { return }
        errorText = nil
        isTalking = true
        streamingAssistant = ""
        reactionBubble = nil
        reactionTask?.cancel()
        do {
            try await PetChatActions.send(
                pet: pet,
                userText: text,
                modelContext: modelContext,
                aiClient: aiHolder.client,
                options: .init(
                    allowRemoteChat: aiHolder.hasRemoteAI && aiHolder.usagePolicy.allowRemoteChat,
                    allowMemoryExtraction: aiHolder.hasRemoteAI && aiHolder.usagePolicy.allowRemoteMemoryExtraction
                )
            ) { partial in
                streamingAssistant = partial
            }
            awardBond(event: .chatMessage)
            PetSoundEngine.shared.speakReplyIfEnabled(streamingAssistant, for: pet, mood: spirit)
            streamingAssistant = ""
        } catch {
            errorText = error.localizedDescription
        }
        isTalking = false
    }

    private func handleQuickPhrase(_ phrase: String) {
        let canRemote = aiHolder.hasRemoteAI && aiHolder.usagePolicy.allowRemoteChat
        if canRemote {
            Task { await sendWithAI(phrase) }
            return
        }
        let reply = PetChatActions.localCompanionReply(for: pet, userText: phrase)
        modelContext.insert(ConversationMessage(pet: pet, role: "user", content: phrase))
        modelContext.insert(ConversationMessage(pet: pet, role: "assistant", content: reply))
        awardBond(event: .localCompanion)
        PetSoundEngine.shared.speakReplyIfEnabled(reply, for: pet, mood: spirit)
        do {
            try modelContext.save()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func applyVoiceIntent(_ intent: VoiceIntent) {
        switch intent {
        case .ask(let text):
            Task { await sendWithAI(text) }
        case .pet:
            awardBond(event: .tapPet)
            triggerAction("nuzzle")
        case .feed:
            awardBond(event: .feeding)
            triggerAction("eat")
        case .play:
            awardBond(event: .playSession)
            triggerAction("fetch")
        case .move(let name):
            triggerAction(name)
            awardBond(event: .voiceMove)
        case .openMemories:
            flashReaction("Tap Heart & memory below")
        }
    }

    private func clip(_ s: String, max: Int) -> String {
        if s.count <= max { return s }
        return String(s.prefix(max)) + "…"
    }
}
