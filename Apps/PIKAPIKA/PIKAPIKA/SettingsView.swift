import SwiftUI
import PikaAI
import PikaCoreBase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: AuthSession
    @Environment(AIClientHolder.self) private var aiHolder

    @AppStorage(PikaUserDefaultsKeys.aiProviderPreference) private var preferenceRaw: String =
        AIProviderRouter.Preference.anthropicPrimary.rawValue

    @State private var openAIKey = ""
    @State private var anthropicKey = ""
    @State private var showSaveResult = false
    @State private var saveResultTitle = "Saved"
    @State private var saveResultMessage = ""
    @State private var allowRemoteChat = true
    @State private var allowRemoteImage = true
    @State private var allowRemoteMemoryExtraction = true

    private var resolvedPreference: AIProviderRouter.Preference {
        AIProviderRouter.Preference(rawValue: preferenceRaw) ?? .anthropicPrimary
    }

    private var hasOpenAI: Bool {
        !openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnthropic: Bool {
        !anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var chatRemoteReady: Bool {
        allowRemoteChat && (hasOpenAI || hasAnthropic)
    }

    private var portraitRemoteReady: Bool {
        allowRemoteImage && hasOpenAI
    }

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

                Section("AI status") {
                    LabeledContent("Chat (remote)") {
                        Text(chatRemoteReady ? "Ready" : "Needs key + toggle")
                            .foregroundStyle(chatRemoteReady ? .green : .secondary)
                    }
                    LabeledContent("Portraits / DALL·E") {
                        Text(portraitRemoteReady ? "Ready" : "Needs OpenAI key + toggle")
                            .foregroundStyle(portraitRemoteReady ? .green : .orange)
                    }
                    Text(
                        "Chat can use Anthropic or OpenAI. Image generation uses OpenAI only today."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section("Preferred chat provider") {
                    Picker("Try first", selection: Binding(
                        get: { resolvedPreference },
                        set: { preferenceRaw = $0.rawValue }
                    )) {
                        Text("Anthropic first").tag(AIProviderRouter.Preference.anthropicPrimary)
                        Text("OpenAI first").tag(AIProviderRouter.Preference.openAIPrimary)
                    }
                    .pickerStyle(.inline)
                }

                Section("Remote AI") {
                    Toggle("Use remote AI for chat", isOn: $allowRemoteChat)
                    Toggle("Use remote AI for image design", isOn: $allowRemoteImage)
                    Toggle("Use remote AI for memory extraction", isOn: $allowRemoteMemoryExtraction)
                    Text("Voice, local sounds, and offline replies stay on your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Anthropic API key") {
                    SecureField("sk-ant-api03-…", text: $anthropicKey)
                        .textContentType(.password)
                }

                Section("OpenAI API key") {
                    SecureField("sk-…", text: $openAIKey)
                        .textContentType(.password)
                }

                Section {
                    Button("Save API keys & preferences") {
                        saveKeysAndRefresh()
                    }
                } footer: {
                    Text("Clear a field and save to remove that key from this device.")
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
                anthropicKey = KeychainHelper.load(.anthropicKey) ?? ""
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

    private func saveKeysAndRefresh() {
        let o = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if o.isEmpty {
            KeychainHelper.delete(.openAIKey)
        } else {
            guard KeychainHelper.save(o, for: .openAIKey) else {
                saveResultTitle = "Could not save"
                saveResultMessage = "OpenAI key could not be written to the Keychain."
                showSaveResult = true
                return
            }
        }
        if a.isEmpty {
            KeychainHelper.delete(.anthropicKey)
        } else {
            guard KeychainHelper.save(a, for: .anthropicKey) else {
                saveResultTitle = "Could not save"
                saveResultMessage = "Anthropic key could not be written to the Keychain."
                showSaveResult = true
                return
            }
        }

        aiHolder.saveUsagePolicy(
            AIUsagePolicy(
                allowRemoteChat: allowRemoteChat,
                allowRemoteImage: allowRemoteImage,
                allowRemoteMemoryExtraction: allowRemoteMemoryExtraction
            )
        )
        aiHolder.refresh()
        openAIKey = KeychainHelper.load(.openAIKey) ?? ""
        anthropicKey = KeychainHelper.load(.anthropicKey) ?? ""

        saveResultTitle = "Saved"
        var parts: [String] = []
        if chatRemoteReady {
            parts.append("Remote chat is on.")
        } else if !hasOpenAI && !hasAnthropic {
            parts.append("Add at least one API key to enable remote chat.")
        } else if !allowRemoteChat {
            parts.append("Turn on “Use remote AI for chat” to talk to cloud models.")
        }
        if !portraitRemoteReady && allowRemoteImage {
            parts.append("Add an OpenAI key for AI portraits.")
        }
        saveResultMessage = parts.isEmpty ? "Your settings were saved." : parts.joined(separator: " ")
        showSaveResult = true
    }
}
