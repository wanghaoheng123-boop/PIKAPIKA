import SwiftUI
import PikaCore
import SharedUI

struct PetOnboardingView: View {
    let onCreate: (Pet) -> Void

    @State private var currentStep = 0
    @State private var name: String = ""
    @State private var species: String = "cat"
    @State private var traits: String = ""
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 3
    private let speciesOptions: [(id: String, emoji: String)] = [
        ("cat", "🐱"), ("dog", "🐶"), ("hamster", "🐹"),
        ("fox", "🦊"), ("rabbit", "🐰")
    ]

    private let suggestedTraits = ["playful", "curious", "loyal", "energetic", "calm", "mischievous"]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: PikaTheme.Spacing.xl) {
                    progressIndicator
                    stepContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    navigationButtons
                }
                .padding()
            }
            .navigationTitle("New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                PikaTheme.Palette.warmBg,
                PikaTheme.Palette.accent.opacity(0.22),
                PikaTheme.Palette.warmBg
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var progressIndicator: some View {
        HStack(spacing: PikaTheme.Spacing.sm) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.accent.opacity(0.3))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.35), value: currentStep)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: nameStep
        case 1: speciesStep
        case 2: traitsStep
        default: EmptyView()
        }
    }

    private var nameStep: some View {
        VStack(spacing: PikaTheme.Spacing.xl) {
            VStack(spacing: PikaTheme.Spacing.sm) {
                Text("What will you call your pet?")
                    .font(PikaTheme.Typography.title)
                    .multilineTextAlignment(.center)
                Text("Choose something unique and meaningful.")
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            VStack(spacing: PikaTheme.Spacing.md) {
                TextField("e.g. Mochi, Luna, Pudge", text: $name)
                    .font(PikaTheme.Typography.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(PikaTheme.Palette.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: PikaTheme.Radius.card)
                            .stroke(name.isEmpty ? PikaTheme.Palette.accent.opacity(0.3) : PikaTheme.Palette.accent, lineWidth: 1.5)
                    )

                if !name.isEmpty {
                    HStack {
                        Text("Preview:")
                            .font(PikaTheme.Typography.caption)
                            .foregroundStyle(PikaTheme.Palette.textMuted)
                        Text("Meet **\(name)**!")
                            .font(PikaTheme.Typography.body)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private var speciesStep: some View {
        VStack(spacing: PikaTheme.Spacing.xl) {
            VStack(spacing: PikaTheme.Spacing.sm) {
                Text("What kind of companion?")
                    .font(PikaTheme.Typography.title)
                    .multilineTextAlignment(.center)
                Text("Pick the species that fits your vibe.")
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PikaTheme.Spacing.md), count: 3), spacing: PikaTheme.Spacing.md) {
                ForEach(speciesOptions, id: \.id) { option in
                    SpeciesCard(
                        speciesId: option.id,
                        emoji: option.emoji,
                        isSelected: species == option.id
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            species = option.id
                        }
                    }
                }
            }
            .padding(.horizontal, 4)

            if !species.isEmpty {
                Text("\(species.capitalized) selected")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            Spacer()
        }
    }

    private var traitsStep: some View {
        VStack(spacing: PikaTheme.Spacing.xl) {
            VStack(spacing: PikaTheme.Spacing.sm) {
                Text("Give \(name.isEmpty ? "your pet" : name) a personality")
                    .font(PikaTheme.Typography.title)
                    .multilineTextAlignment(.center)
                Text("Select up to 3 traits that feel right.")
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            FlowLayout(spacing: PikaTheme.Spacing.sm) {
                ForEach(suggestedTraits, id: \.self) { trait in
                    TraitChip(
                        trait: trait,
                        isSelected: traits.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.contains(trait)
                    ) {
                        toggleTrait(trait)
                    }
                }
            }
            .padding(.horizontal)

            VStack(spacing: 4) {
                Text("Your pet's traits:")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
                Text(finalTraits.isEmpty ? "None selected yet" : finalTraits)
                    .font(PikaTheme.Typography.body.weight(.medium))
                    .foregroundStyle(finalTraits.isEmpty ? PikaTheme.Palette.textMuted : PikaTheme.Palette.accentDeep)
            }

            Spacer()
        }
    }

    private var finalTraits: String {
        let selected = traits
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return selected.isEmpty ? "" : selected.joined(separator: ", ")
    }

    private func toggleTrait(_ trait: String) {
        var current = traits
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if current.contains(trait) {
            current.removeAll { $0 == trait }
        } else if current.count < 3 {
            current.append(trait)
        }

        traits = current.joined(separator: ",")
    }

    private var navigationButtons: some View {
        HStack(spacing: PikaTheme.Spacing.md) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .font(PikaTheme.Typography.body.weight(.semibold))
                .padding(.horizontal, PikaTheme.Spacing.lg)
                .padding(.vertical, PikaTheme.Spacing.sm)
                .background(canProceed ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.accent.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(!canProceed)
            } else {
                Button("Create \(name.isEmpty ? "Pet" : name)") {
                    let pet = Pet(
                        name: name.isEmpty ? "Pika" : name,
                        species: species,
                        creationMethod: "onboarding",
                        spriteAtlasPath: "",
                        personalityTraits: finalTraits.isEmpty ? [] : finalTraits.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                        visualModelPreset: Pet.defaultVisualModelPreset(forSpecies: species)
                    )
                    onCreate(pet)
                }
                .font(PikaTheme.Typography.body.weight(.semibold))
                .padding(.horizontal, PikaTheme.Spacing.lg)
                .padding(.vertical, PikaTheme.Spacing.sm)
                .background(PikaTheme.Palette.accentDeep)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !species.isEmpty
        default: return true
        }
    }
}

private struct SpeciesCard: View {
    let speciesId: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 40))
                Text(speciesId.capitalized)
                    .font(PikaTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PikaTheme.Spacing.md)
            .background(isSelected ? PikaTheme.Palette.accent.opacity(0.25) : PikaTheme.Palette.accent.opacity(0.08))
            .foregroundStyle(isSelected ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: PikaTheme.Radius.card)
                    .stroke(isSelected ? PikaTheme.Palette.accentDeep : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TraitChip: View {
    let trait: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(trait)
                    .font(PikaTheme.Typography.caption)
            }
            .padding(.horizontal, PikaTheme.Spacing.sm)
            .padding(.vertical, PikaTheme.Spacing.xs)
            .background(isSelected ? PikaTheme.Palette.accentDeep.opacity(0.2) : PikaTheme.Palette.accent.opacity(0.1))
            .foregroundStyle(isSelected ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.textMuted)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? PikaTheme.Palette.accentDeep : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

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
