import SwiftUI
import PikaCore
import PikaAI
import SharedUI

/// API keys, preferred chat provider, and a lightweight connectivity probe.
public struct PikaSettingsContent: View {
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var unlocked = false

    @AppStorage(PikaUserDefaultsKeys.aiProviderPreference) private var preferenceRaw: String =
        AIProviderRouter.Preference.anthropicPrimary.rawValue

    @State private var probing = false
    @State private var probeResult: String?
    @State private var probeIsSuccess = false
    /// After a probe, block rapid re-taps to avoid repeated billed API calls.
    @State private var probeCooldownUntil: Date = .distantPast

    private static let probeCooldownSeconds: TimeInterval = 15

    public init() {}

    private var resolvedPreference: AIProviderRouter.Preference {
        AIProviderRouter.Preference(rawValue: preferenceRaw) ?? .anthropicPrimary
    }

    public var body: some View {
        Form {
            Section("Chat provider") {
                Picker("Preferred provider", selection: Binding(
                    get: { resolvedPreference },
                    set: { preferenceRaw = $0.rawValue }
                )) {
                    Text("Anthropic first").tag(AIProviderRouter.Preference.anthropicPrimary)
                    Text("OpenAI first").tag(AIProviderRouter.Preference.openAIPrimary)
                }
                .pickerStyle(.inline)
            }

            Section {
                Button(probing ? "Testing…" : "Test connection") {
                    Task { await runConnectionProbe() }
                }
                .disabled(probing || Date() < probeCooldownUntil)
                .accessibilityLabel("Test API connection")
                .accessibilityHint(
                    "Runs a minimal chat request against your preferred provider. Uses a small billed API request."
                )
                if let probeResult {
                    Text(probeResult)
                        .font(PikaTheme.Typography.caption)
                        .foregroundStyle(probeIsSuccess ? .green : .red)
                }
            } header: {
                Text("Connection")
            } footer: {
                Text(
                    "Test connection sends one short chat turn to your provider (counts toward API usage). You can run it again after \(Int(Self.probeCooldownSeconds)) seconds."
                )
                .font(PikaTheme.Typography.caption)
                .foregroundStyle(PikaTheme.Palette.textMuted)
            }

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
                    Button("Unlock with Face ID / Touch ID / Password") {
                        Task {
                            let ok = await BiometricAuthManager.shared.authenticate(
                                reason: "Reveal your saved API keys"
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

    @MainActor
    private func runConnectionProbe() async {
        guard Date() >= probeCooldownUntil else { return }
        probing = true
        probeResult = nil
        var didAttemptBilledRequest = false
        defer {
            probing = false
            if didAttemptBilledRequest {
                probeCooldownUntil = Date().addingTimeInterval(Self.probeCooldownSeconds)
            }
        }
        let router = AIProviderRouter(preference: resolvedPreference)
        do {
            _ = try router.primaryClient()
        } catch {
            probeResult = error.localizedDescription
            probeIsSuccess = false
            return
        }
        didAttemptBilledRequest = true
        var accumulated = ""
        do {
            try await router.runChatWithFallback(
                messages: [ChatMessage(role: "user", content: "Reply with exactly: OK")],
                systemPrompt: "Output only the two letters OK and nothing else.",
                temperature: 0,
                onChunk: { accumulated += $0 }
            )
            let trimmed = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
            probeIsSuccess = !trimmed.isEmpty
            probeResult = probeIsSuccess
                ? "Connected. Preview: \(trimmed.prefix(48))"
                : "Connected but received an empty reply."
        } catch {
            probeIsSuccess = false
            probeResult = error.localizedDescription
        }
    }
}
