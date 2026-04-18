import SwiftUI
import PikaCore
import SharedUI

struct PetHomeView: View {
    let pet: Pet

    var body: some View {
        HStack(spacing: PikaTheme.Spacing.xl) {
            VStack {
                PetAvatarView(pet: pet, size: 200)
                Text(pet.name).font(PikaTheme.Typography.title)
                BondProgressRing(xp: pet.bondXP)
            }
            ChatView(pet: pet)
                .frame(minWidth: 360)
        }
        .padding()
        .frame(minWidth: 720, minHeight: 480)
    }
}
