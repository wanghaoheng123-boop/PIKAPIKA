import SwiftUI
import PikaCoreBase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: AuthSession
    @Environment(AIClientHolder.self) private var aiHolder

    @State private var openAIKey = ""
    @State private var showSaveResult = false
    @State private var saveResultTitle = "Saved"
    @State private var saveResultMessage = "API key updated. Chat will use OpenAI when a key is present."
    @State private var allowRemoteChat = true
    @State private var allowRemoteImage = true
    @State private var allowRemoteMemoryExtraction = true

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

                Section("OpenAI") {
                    SecureField("API key", text: $openAIKey)
                        .textContentType(.password)
                    Toggle("Use remote AI for chat", isOn: $allowRemoteChat)
                    Toggle("Use remote AI for image design", isOn: $allowRemoteImage)
                    Toggle("Use remote AI for memory extraction", isOn: $allowRemoteMemoryExtraction)
                    Button("Save key") {
                        let trimmed = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        let keyUpdated: Bool
                        if trimmed.isEmpty {
                            KeychainHelper.delete(.openAIKey)
                            keyUpdated = true
                        } else {
                            keyUpdated = KeychainHelper.save(trimmed, for: .openAIKey)
                        }
                        guard keyUpdated else {
                            saveResultTitle = "Could not save key"
                            saveResultMessage = "Keychain write failed. Please try again."
                            showSaveResult = true
                            return
                        }
                        aiHolder.saveUsagePolicy(
                            AIUsagePolicy(
                                allowRemoteChat: allowRemoteChat,
                                allowRemoteImage: allowRemoteImage,
                                allowRemoteMemoryExtraction: allowRemoteMemoryExtraction
                            )
                        )
                        aiHolder.refresh()
                        saveResultTitle = "Saved"
                        saveResultMessage = "API key updated. Chat will use OpenAI when a key is present."
                        showSaveResult = true
                    }
                    Text("Use toggles to choose where remote AI is used. Voice input, pet sounds, and local quick interactions remain on-device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PIKAPIKATheme.homeBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                openAIKey = KeychainHelper.load(.openAIKey) ?? ""
                let policy = aiHolder.usagePolicy
                allowRemoteChat = policy.allowRemoteChat
                allowRemoteImage = policy.allowRemoteImage
                allowRemoteMemoryExtraction = policy.allowRemoteMemoryExtraction
            }
            .alert(saveResultTitle, isPresented: $showSaveResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveResultMessage)
            }
        }
        .tint(PIKAPIKATheme.accent)
    }
}
