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
            VStack(spacing: PikaTheme.Spacing.xl) {
                progressIndicator
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                navigationButtons
            }
            .padding(PikaTheme.Spacing.xl)
            .frame(width: 420)
        }
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
        VStack(spacing: PikaTheme.Spacing.lg) {
            VStack(spacing: 4) {
                Text("What will you call your pet?")
                    .font(PikaTheme.Typography.title)
                Text("Choose something unique and meaningful.")
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }
            TextField("e.g. Mochi, Luna, Pudge", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(PikaTheme.Typography.body)
            Spacer()
        }
    }

    private var speciesStep: some View {
        VStack(spacing: PikaTheme.Spacing.lg) {
            VStack(spacing: 4) {
                Text("What kind of companion?")
                    .font(PikaTheme.Typography.title)
                Text("Pick the species that fits your vibe.")
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(speciesOptions, id: \.id) { option in
                    Button {
                        withAnimation { species = option.id }
                    } label: {
                        VStack(spacing: 4) {
                            Text(option.emoji).font(.system(size: 32))
                            Text(option.id.capitalized).font(PikaTheme.Typography.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(species == option.id ? PikaTheme.Palette.accent.opacity(0.25) : PikaTheme.Palette.accent.opacity(0.08))
                        .foregroundStyle(species == option.id ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(species == option.id ? PikaTheme.Palette.accentDeep : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
    }

    private var traitsStep: some View {
        VStack(spacing: PikaTheme.Spacing.lg) {
            VStack(spacing: 4) {
                Text("Give \(name.isEmpty ? "your pet" : name) a personality")
                    .font(PikaTheme.Typography.title)
                Text("Select up to 3 traits that feel right.")
                    .font(PikaTheme.Typography.body)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }
            FlowLayoutOnboarding(spacing: 6) {
                ForEach(suggestedTraits, id: \.self) { trait in
                    let isSelected = finalTraitsArray.contains(trait)
                    Button {
                        toggleTrait(trait)
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(trait).font(PikaTheme.Typography.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? PikaTheme.Palette.accentDeep.opacity(0.2) : PikaTheme.Palette.accent.opacity(0.1))
                        .foregroundStyle(isSelected ? PikaTheme.Palette.accentDeep : PikaTheme.Palette.textMuted)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSelected ? PikaTheme.Palette.accentDeep : .clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Traits: \(finalTraits.isEmpty ? "None selected" : finalTraits)")
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(finalTraits.isEmpty ? PikaTheme.Palette.textMuted : PikaTheme.Palette.accentDeep)
            Spacer()
        }
    }

    private var finalTraits: String {
        finalTraitsArray.joined(separator: ", ")
    }

    private var finalTraitsArray: [String] {
        traits.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func toggleTrait(_ trait: String) {
        var current = finalTraitsArray
        if current.contains(trait) {
            current.removeAll { $0 == trait }
        } else if current.count < 3 {
            current.append(trait)
        }
        traits = current.joined(separator: ",")
    }

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .foregroundStyle(PikaTheme.Palette.textMuted)
            }
            Spacer()
            if currentStep < totalSteps - 1 {
                Button("Next") {
                    withAnimation { currentStep += 1 }
                }
                .disabled(!canProceed)
            } else {
                Button("Create \(name.isEmpty ? "Pet" : name)") {
                    let pet = Pet(
                        name: name.isEmpty ? "Pika" : name,
                        species: species,
                        creationMethod: "onboarding",
                        spriteAtlasPath: "",
                        personalityTraits: finalTraitsArray,
                        visualModelPreset: Pet.defaultVisualModelPreset(forSpecies: species)
                    )
                    onCreate(pet)
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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

private struct FlowLayoutOnboarding: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[i].x, y: bounds.minY + result.positions[i].y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var xs: CGFloat = 0, ys: CGFloat = 0, lineH: CGFloat = 0
        var positions: [CGPoint] = []
        for subview in subviews {
            let s = subview.sizeThatFits(.unspecified)
            if xs + s.width > maxW && xs > 0 { xs = 0; ys += lineH + spacing; lineH = 0 }
            positions.append(CGPoint(x: xs, y: ys))
            lineH = max(lineH, s.height)
            xs += s.width + spacing
        }
        return (CGSize(width: maxW, height: ys + lineH), positions)
    }
}
