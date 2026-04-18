import SwiftUI
import PikaCore
import SharedUI

struct PetHomeView: View {
    let pet: Pet

    var body: some View {
        VStack(spacing: PikaTheme.Spacing.lg) {
            PetAvatarView(pet: pet, size: 160)
            Text(pet.name).font(PikaTheme.Typography.title)
            BondProgressRing(xp: pet.bondXP)
            HStack(spacing: PikaTheme.Spacing.sm) {
                ForEach(pet.personalityTraits, id: \.self) { PersonalityBadge(trait: $0) }
            }
            NavigationLink {
                ChatView(pet: pet)
            } label: {
                Text("Chat with \(pet.name)")
                    .font(PikaTheme.Typography.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PikaTheme.Palette.accentDeep)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: PikaTheme.Radius.card))
            }
            .padding(.horizontal, PikaTheme.Spacing.xl)
            Spacer()
        }
        .padding()
    }
}
