import SwiftUI
import PikaCore

struct ChatView: View {
    let pet: Pet

    var body: some View {
        PetChatScreen(pet: pet)
    }
}
