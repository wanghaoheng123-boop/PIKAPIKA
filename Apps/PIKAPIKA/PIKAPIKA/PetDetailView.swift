import SwiftData
import SwiftUI
import UIKit
import PikaCore

struct PetDetailView: View {
    @Bindable var pet: Pet

    @Environment(\.modelContext) private var modelContext
    @Environment(AIClientHolder.self) private var aiHolder

    @Query(sort: \ConversationMessage.timestamp, order: .reverse) private var allMessages: [ConversationMessage]

    @State private var streamingAssistant = ""
    @State private var reactionBubble: String?
    @State private var isTalking = false
    @State private var errorText: String?
    @State private var stagedAction = "idle"
    @State private var actionTick = 0
    @State private var showMovesSheet = false
    @State private var showCustomize = false
    @State private var moveSearch = ""

    private var messagesForPet: [ConversationMessage] {
        allMessages.filter { $0.pet?.id == pet.id }
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

    private var spirit: PetSpiritState { PetSpiritState.evaluate(for: pet) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PikaMetrics.sectionSpacing) {
                SpiritBondStrip(pet: pet, spirit: spirit)
                    .padding(.horizontal, PikaMetrics.screenHorizontal)

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
                awardBond(event: "pet", xp: 4)
                triggerAction("nuzzle")
                flashReaction(["So soft!", "Hehe!", "Love that!"].randomElement()!)
            }
            actionButton(title: "Feed", symbol: "leaf.fill", tint: .green) {
                awardBond(event: "feed", xp: 6)
                triggerAction("eat")
                flashReaction(["Yum!", "Tasty!", "More please!"].randomElement()!)
            }
            actionButton(title: "Play", symbol: "ball.fill", tint: .orange) {
                awardBond(event: "play", xp: 8)
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
            PikaSectionHeader(
                title: "Quick talk",
                subtitle: "One tap — they answer with spirit."
            )
            .padding(.horizontal, PikaMetrics.screenHorizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickPhrases, id: \.self) { phrase in
                        Button {
                            Task { await sendWithAI(phrase) }
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
        awardBond(event: "tap", xp: 3)
        triggerAction("boop")
        PetSoundEngine.shared.chirp(for: pet, mood: spirit)
        let lines: [String]
        switch pet.species.lowercased() {
        case "cat": lines = ["Purr…", "Mrr?", "Pet me more!"]
        case "dog": lines = ["Woof!", "Play?", "Hehe!"]
        case "hamster": lines = ["Squeak!", "Nom?", "Zoom!"]
        default: lines = ["Hi!", "Cute!", "♥"]
        }
        flashReaction(lines.randomElement()!)
    }

    private func flashReaction(_ text: String) {
        reactionBubble = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if reactionBubble == text {
                reactionBubble = nil
            }
        }
    }

    private func awardBond(event: String, xp: Int) {
        pet.bondXP += xp
        pet.bondLevel = BondLevel.from(xp: pet.bondXP).rawValue
        PetInteractionStreak.recordInteraction(pet: pet)
        pet.lastInteractedAt = Date()
        modelContext.insert(BondEvent(pet: pet, eventType: event, xpAwarded: xp))
        try? modelContext.save()
    }

    private func sendWithAI(_ text: String) async {
        guard !isTalking else { return }
        errorText = nil
        isTalking = true
        streamingAssistant = ""
        reactionBubble = nil
        awardBond(event: "chat", xp: 2)
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
        isTalking = false
    }

    private func clip(_ s: String, max: Int) -> String {
        if s.count <= max { return s }
        return String(s.prefix(max)) + "…"
    }
}
