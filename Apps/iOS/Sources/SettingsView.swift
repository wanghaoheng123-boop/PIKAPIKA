import SwiftUI
import PikaCore
import SharedUI

struct SettingsView: View {
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var unlocked = false

    var body: some View {
        Form {
            if unlocked {
                Section("OpenAI API Key") {
                    SecureField("sk-…", text: $openAIKey)
                    Button("Save") { KeychainHelper.save(openAIKey, for: .openAIKey) }
                }
                Section("Anthropic API Key") {
                    SecureField("sk-ant-…", text: $anthropicKey)
                    Button("Save") { KeychainHelper.save(anthropicKey, for: .anthropicKey) }
                }
            } else {
                Section {
                    Button("Unlock with Face ID / Touch ID") {
                        Task {
                            let ok = await BiometricAuthManager.shared.authenticate(
                                reason: "Reveal your API keys"
                            )
                            if ok {
                                unlocked = true
                                openAIKey = KeychainHelper.load(.openAIKey) ?? ""
                                anthropicKey = KeychainHelper.load(.anthropicKey) ?? ""
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
