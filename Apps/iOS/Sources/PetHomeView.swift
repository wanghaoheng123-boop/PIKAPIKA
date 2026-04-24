import SwiftUI
import PikaCore
import SharedUI

struct PetHomeView: View {
    let pet: Pet
    @State private var showPetEditor = false
    @State private var selectedMood: PetMood = .idle
    @State private var isActionPressed = false

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
        }
    }

    private var petAvatarSection: some View {
        VStack(spacing: PikaTheme.Spacing.sm) {
            PetAvatarView(pet: pet, state: PetState.from(mood: selectedMood), size: 160)
                .scaleEffect(isActionPressed ? 0.92 : 1.0)
                .animation(.spring(duration: 0.3), value: isActionPressed)

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
            StatCard(
                icon: "star.fill",
                value: "\(BondLevel.from(xp: pet.bondXP).rawValue)",
                label: "Level",
                color: .orange
            )
            StatCard(
                icon: "sparkles",
                value: "\(pet.personalityTraits.count)",
                label: "Traits",
                color: .purple
            )
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActionPressed = false
                }
            }
            QuickActionButton(
                icon: "figure.run",
                label: "Play",
                color: .green
            ) {
                withAnimation { isActionPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActionPressed = false
                }
            }
            QuickActionButton(
                icon: "moon.fill",
                label: "Sleep",
                color: .indigo
            ) {
                withAnimation { isActionPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActionPressed = false
                }
            }
        }
        .padding(.horizontal, 4)
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

extension PetState {
    static func from(mood: PetMood) -> PetState {
        switch mood {
        case .happy:    return .celebrating
        case .sleepy:   return .sleeping
        case .sad:       return .sad
        case .excited:  return .celebrating
        case .idle:     return .idle
        }
    }
}

extension PetMood: CaseIterable {
    static var allCases: [PetMood] = [.happy, .excited, .idle, .sleepy, .sad]
}
