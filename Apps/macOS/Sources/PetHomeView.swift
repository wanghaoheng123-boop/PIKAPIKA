import SwiftUI
import PikaCore
import SharedUI

struct PetHomeView: View {
    let pet: Pet

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .help("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                }
                .frame(minWidth: 420, minHeight: 400)
            }
        }
    }
}

