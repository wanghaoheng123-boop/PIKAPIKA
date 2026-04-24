import SwiftUI
import PikaCore
import SharedUI

struct PetHomeView: View {
    let pet: Pet
    @Environment(\.modelContext) private var modelContext
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
        ZStack {
            LinearGradient(
                colors: [
                    PikaTheme.Palette.warmBg,
                    PikaTheme.Palette.accent.opacity(0.18),
                    PikaTheme.Palette.warmBg
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: PikaTheme.Spacing.lg) {
                headerRow
                spiritStateBadge
                petAvatarSection
                moodSelectorRow
                statsRow
                quickActionButtons
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showPetEditor = true }
                    .accessibilityLabel("Edit pet profile")
            }
        }
        .sheet(isPresented: $showPetEditor) {
            NavigationStack {
                PetProfileEditorView(pet: pet)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your companion")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
                Text(pet.name)
                    .font(PikaTheme.Typography.title)
            }
            Spacer()
            NavigationLink {
                ChatView(pet: pet)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat")
                }
                .font(PikaTheme.Typography.body.weight(.semibold))
                .padding(.horizontal, PikaTheme.Spacing.md)
                .padding(.vertical, PikaTheme.Spacing.sm)
                .background(PikaTheme.Palette.accentDeep)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .accessibilityLabel("Open chat with \(pet.name)")
        }
    }

    @ViewBuilder
    private var spiritStateBadge: some View {
        let colors = spiritState.pillColors
        HStack(spacing: 6) {
            Text(spiritState.emoji)
                .font(.system(size: 14))
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

    private var petAvatarSection: some View {
        VStack(spacing: PikaTheme.Spacing.sm) {
            PetAvatarView(pet: pet, state: PetState.from(mood: selectedMood), size: 160)
                .scaleEffect(isActionPressed ? 0.92 : 1.0)
                .animation(.spring(duration: 0.3), value: isActionPressed)
                .accessibilityLabel("\(pet.name), \(selectedMood.displayName)")

            MoodBadge(mood: selectedMood)
        }
    }

    private var moodSelectorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PikaTheme.Spacing.sm) {
                ForEach(PetMood.allCases, id: \.self) { mood in
                    MoodSelectorButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: { selectedMood = mood }
                    )
                    .accessibilityLabel("\(mood.displayName) mood")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var statsRow: some View {
        HStack(spacing: PikaTheme.Spacing.md) {
            StatCard(
                icon: "heart.fill",
                value: "\(pet.bondXP)",
                label: "Bond XP",
                color: PikaTheme.Palette.accentDeep
            )
            .accessibilityLabel("\(pet.bondXP) bond experience points")
            StatCard(
                icon: "star.fill",
                value: "\(bondLevel.rawValue)",
                label: bondLevel.displayName,
                color: .orange
            )
            .accessibilityLabel("Level \(bondLevel.rawValue), \(bondLevel.displayName)")
            if pet.streakCount > 0 {
                StatCard(
                    icon: "flame.fill",
                    value: "\(pet.streakCount)",
                    label: pet.streakCount == 1 ? "Day" : "Days",
                    color: .red
                )
                .accessibilityLabel("\(pet.streakCount)-day interaction streak")
            }
            StatCard(
                icon: "sparkles",
                value: "\(pet.personalityTraits.count)",
                label: "Traits",
                color: .purple
            )
            .accessibilityLabel("\(pet.personalityTraits.count) personality traits")
        }
    }

    private var quickActionButtons: some View {
        HStack(spacing: PikaTheme.Spacing.md) {
            QuickActionButton(
                icon: "fork.knife",
                label: "Feed",
                color: .orange
            ) {
                withAnimation { isActionPressed = true }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                awardBond(.feeding)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActionPressed = false
                }
            }
            .accessibilityLabel("Feed \(pet.name)")

            QuickActionButton(
                icon: "figure.run",
                label: "Play",
                color: .green
            ) {
                withAnimation { isActionPressed = true }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                awardBond(.playSession)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActionPressed = false
                }
            }
            .accessibilityLabel("Play with \(pet.name)")

            QuickActionButton(
                icon: "moon.fill",
                label: "Sleep",
                color: .indigo
            ) {
                withAnimation { isActionPressed = true }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedMood = .sleepy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActionPressed = false
                }
            }
            .accessibilityLabel("Put \(pet.name) to sleep")
        }
        .padding(.horizontal, 4)
    }

    private func awardBond(_ event: BondProgression.Event) {
        let award = BondProgression.xp(for: event)
        let (newXP, _) = BondProgression.apply(currentXP: pet.bondXP, award: award)
        let todayXP = pet.bondEvents
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.xpAwarded }
        guard todayXP < BondProgression.dailyCap else { return }
        let cappedXP = min(award.xp, BondProgression.dailyCap - todayXP)
        guard cappedXP > 0 else { return }
        pet.bondXP = newXP - award.xp + cappedXP
        pet.bondLevel = BondLevel.from(xp: pet.bondXP).rawValue
        PetInteractionStreak.recordInteraction(pet: pet)
        pet.lastInteractedAt = Date()
        modelContext.insert(BondEvent(
            pet: pet,
            eventType: award.eventType,
            xpAwarded: cappedXP,
            metadata: award.metadata
        ))
        try? modelContext.save()
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
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 22))
                Text(mood.displayName)
                    .font(PikaTheme.Typography.caption)
            }
            .frame(width: 60, height: 56)
            .background(isSelected ? mood.color.opacity(0.2) : PikaTheme.Palette.accent.opacity(0.08))
            .foregroundStyle(isSelected ? mood.color : PikaTheme.Palette.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: PikaTheme.Radius.card)
                    .stroke(isSelected ? mood.color : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(PikaTheme.Typography.body.weight(.bold))
            Text(label)
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PikaTheme.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(PikaTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PikaTheme.Spacing.md)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: PikaTheme.Radius.card)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

