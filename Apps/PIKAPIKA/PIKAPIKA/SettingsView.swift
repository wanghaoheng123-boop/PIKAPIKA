import SwiftUI
import PikaCoreBase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: AuthSession
    @Environment(AIClientHolder.self) private var aiHolder

    @State private var openAIKey = ""
    @State private var showKeySaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let p = authSession.provider, let id = authSession.userId {
                        LabeledContent("Signed in", value: p.rawValue)
                        Text(id)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button("Sign out", role: .destructive) {
                        authSession.signOut()
                        dismiss()
                    }
                }
                Section("OpenAI (optional)") {
                    SecureField("API key", text: $openAIKey)
                        .textContentType(.password)
                    Button("Save key") {
                        let trimmed = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            KeychainHelper.delete(.openAIKey)
                        } else {
                            _ = KeychainHelper.save(trimmed, for: .openAIKey)
                        }
                        aiHolder.refresh()
                        showKeySaved = true
                    }
                    Text("Leave empty to use the built-in mock replies. Keys stay in Keychain on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                openAIKey = KeychainHelper.load(.openAIKey) ?? ""
            }
            .alert("Saved", isPresented: $showKeySaved) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("API key updated. Chat will use OpenAI when a key is present.")
            }
        }
    }
}
