import SwiftUI
import PikaCore
import SharedUI

struct PetHomeView: View {
    let pet: Pet
    @Environment(\.modelContext) private var modelContext

    @State private var showSettings = false
    @State private var showPetEditor = false
    @State private var selectedMood: PetMood = .idle
    @State private var isActionPressed = false

    private var spiritState: PetSpiritState {
        PetSpiritState.evaluate(for: pet)
    }

    private var bondLevel: BondLevel {
        BondLevel.from(xp: pet.bondXP)
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationTitle("Pika")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button { showPetEditor = true } label: {
                            Label("Edit pet", systemImage: "pencil")
                        }
                        .help("Edit pet profile")
                        Button { showSettings = true } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        .help("Settings")
                    }
                }
        } detail: {
            ChatView(pet: pet)
                .frame(minWidth: 360)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
            .frame(minWidth: 420, minHeight: 400)
        }
        .sheet(isPresented: $showPetEditor) {
            NavigationStack {
                PetProfileEditorView(pet: pet)
            }
            .frame(minWidth: 420, minHeight: 480)
        }
    }

    private var sidebarContent: some View {
        ScrollView {
            VStack(spacing: PikaTheme.Spacing.xl) {
                petIdentitySection
                spiritStateSection
                moodSelectorSection
                statsSection
                quickActionsSection
                bondSection
                shortcutHints
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [PikaTheme.Palette.warmBg, PikaTheme.Palette.accent.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var petIdentitySection: some View {
        VStack(spacing: PikaTheme.Spacing.sm) {
            PetAvatarView(pet: pet, state: PetState.from(mood: selectedMood), size: 120)
                .scaleEffect(isActionPressed ? 0.92 : 1.0)
                .animation(.spring(duration: 0.3), value: isActionPressed)
                .accessibilityLabel("\(pet.name), \(selectedMood.displayName)")

            Text(pet.name)
                .font(PikaTheme.Typography.title)

            MoodBadge(mood: selectedMood)
        }
    }

    private var spiritStateSection: some View {
        let colors = spiritState.pillColors
        return HStack(spacing: 6) {
            Text(spiritState.emoji)
                .font(.system(size: 12))
            Text(spiritState.shortTitle)
                .font(PikaTheme.Typography.caption.weight(.medium))
            Text("·")
            Text(spiritState.subtitle)
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
                .lineLimit(1)
        }
        .foregroundStyle(colors.first ?? PikaTheme.Palette.accentDeep)
        .padding(.horizontal, PikaTheme.Spacing.md)
        .padding(.vertical, PikaTheme.Spacing.sm)
        .background(
            LinearGradient(
                colors: colors.map { $0.opacity(0.15) },
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .accessibilityLabel("\(pet.name) is \(spiritState.shortTitle): \(spiritState.subtitle)")
    }

    private var moodSelectorSection: some View {
        VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
            Text("Mood")
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(PetMood.allCases, id: \.self) { mood in
                    MoodSelectorButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: { selectedMood = mood }
                    )
                    .accessibilityLabel("\(mood.displayName) mood")
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
            Text("Stats")
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)

            VStack(spacing: 4) {
                StatRow(icon: "heart.fill", label: "Bond XP", value: "\(pet.bondXP)", color: PikaTheme.Palette.accentDeep)
                    .accessibilityLabel("\(pet.bondXP) bond experience points")
                StatRow(icon: "star.fill", label: "Level", value: "\(bondLevel.rawValue) \(bondLevel.displayName)", color: .orange)
                    .accessibilityLabel("Level \(bondLevel.rawValue), \(bondLevel.displayName)")
                if pet.streakCount > 0 {
                    StatRow(icon: "flame.fill", label: "Streak", value: "\(pet.streakCount) day\(pet.streakCount == 1 ? "" : "s")", color: .red)
                        .accessibilityLabel("\(pet.streakCount)-day interaction streak")
                }
                StatRow(icon: "sparkles", label: "Traits", value: "\(pet.personalityTraits.count)", color: .purple)
                    .accessibilityLabel("\(pet.personalityTraits.count) personality traits")
            }
            .padding(PikaTheme.Spacing.sm)
            .background(PikaTheme.Palette.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
            Text("Quick Actions")
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)

            VStack(spacing: 6) {
                QuickActionRow(icon: "fork.knife", label: "Feed", shortcut: "⌘F", color: .orange) {
                    isActionPressed = true
                    awardBond(.feeding)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isActionPressed = false }
                }
                .accessibilityLabel("Feed \(pet.name)")

                QuickActionRow(icon: "figure.run", label: "Play", shortcut: "⌘P", color: .green) {
                    isActionPressed = true
                    awardBond(.playSession)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isActionPressed = false }
                }
                .accessibilityLabel("Play with \(pet.name)")

                QuickActionRow(icon: "moon.fill", label: "Sleep", shortcut: "⌘S", color: .indigo) {
                    isActionPressed = true
                    selectedMood = .sleepy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isActionPressed = false }
                }
                .accessibilityLabel("Put \(pet.name) to sleep")
            }
        }
    }

    private func awardBond(_ event: BondProgression.Event) {
        let award = BondProgression.xp(for: event)
        let todayXP = pet.bondEvents
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.xpAwarded }
        guard todayXP < BondProgression.dailyCap else { return }
        let cappedXP = min(award.xp, BondProgression.dailyCap - todayXP)
        guard cappedXP > 0 else { return }
        pet.bondXP += cappedXP
        pet.bondLevel = BondLevel.from(xp: pet.bondXP).rawValue
        PetInteractionStreak.recordStreak(pet: pet)
        pet.lastInteractedAt = Date()
        modelContext.insert(BondEvent(
            pet: pet,
            eventType: award.eventType,
            xpAwarded: cappedXP,
            metadata: award.metadata
        ))
        do {
            try modelContext.save()
        } catch {
            print("Failed to save bond event: \(error)")
        }
    }


    private var bondSection: some View {
        VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
            Text("Bond")
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)

            BondProgressRing(xp: pet.bondXP, diameter: 80, lineWidth: 8)
                .frame(maxWidth: .infinity)

            if !pet.personalityTraits.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(pet.personalityTraits, id: \.self) { PersonalityBadge(trait: $0) }
                }
            }
        }
    }

    private var shortcutHints: some View {
        VStack(alignment: .leading, spacing: 4) {
            ShortcutHint(keys: "⌘ ,", description: "Settings")
            ShortcutHint(keys: "⌘ N", description: "New pet")
            ShortcutHint(keys: "⌘ Return", description: "Send chat")
        }
        .padding(.top, PikaTheme.Spacing.sm)
    }
}

private struct MoodBadge: View {
    let mood: PetMood
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(mood.color)
                .frame(width: 8, height: 8)
            Text(mood.displayName)
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
        }
        .padding(.horizontal, PikaTheme.Spacing.sm)
        .padding(.vertical, PikaTheme.Spacing.xs)
        .background(PikaTheme.Palette.accent.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct MoodSelectorButton: View {
    let mood: PetMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(mood.emoji)
                    .font(.system(size: 18))
                Text(mood.displayName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isSelected ? mood.color.opacity(0.2) : PikaTheme.Palette.accent.opacity(0.08))
            .foregroundStyle(isSelected ? mood.color : PikaTheme.Palette.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? mood.color : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(label)
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
            Spacer()
            Text(value)
                .font(PikaTheme.Typography.caption.weight(.semibold))
        }
    }
}

private struct QuickActionRow: View {
    let icon: String
    let label: String
    let shortcut: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(label)
                    .font(PikaTheme.Typography.caption)
                Spacer()
                Text(shortcut)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }
            .padding(.horizontal, PikaTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct ShortcutHint: View {
    let keys: String
    let description: String

    var body: some View {
        HStack(spacing: 6) {
            Text(keys)
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                )
            Text(description)
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

