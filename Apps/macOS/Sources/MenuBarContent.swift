import SwiftUI
import SwiftData
import PikaCore
import SharedUI

struct MenuBarContent: View {
    @Query private var pets: [Pet]

    var body: some View {
        VStack(alignment: .leading, spacing: PikaTheme.Spacing.sm) {
            if let pet = pets.first {
                HStack {
                    PetAvatarView(pet: pet, size: 48)
                    VStack(alignment: .leading) {
                        Text(pet.name).font(PikaTheme.Typography.body.weight(.semibold))
                        Text(BondLevel.from(xp: pet.bondXP).displayName)
                            .font(PikaTheme.Typography.caption)
                            .foregroundStyle(PikaTheme.Palette.textMuted)
                    }
                }
            } else {
                Text("No pet yet").foregroundStyle(PikaTheme.Palette.textMuted)
            }
            Divider()
            Button("Open Pika") { NSApp.activate(ignoringOtherApps: true) }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding()
        .frame(width: 240)
    }
}
