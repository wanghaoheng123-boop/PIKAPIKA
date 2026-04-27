import SwiftUI
import StoreKit
import PikaCore
import PikaCoreBase
import PikaAI
import PikaSubscription
import SharedUI

/// API keys, preferred chat provider, and a lightweight connectivity probe.
public struct PikaSettingsContent: View {
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var deepSeekKey: String = ""
    @State private var unlocked = false

    @AppStorage(PikaUserDefaultsKeys.aiProviderPreference) private var preferenceRaw: String =
        AIProviderRouter.Preference.anthropicPrimary.rawValue

    @State private var probing = false
    @State private var probeResult: String?
    @State private var probeIsSuccess = false
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var purchasingProductID: String?
    /// After a probe, block rapid re-taps to avoid repeated billed API calls.
    @State private var probeCooldownUntil: Date = .distantPast

    private static let probeCooldownSeconds: TimeInterval = 15

    private var activePlanName: String {
        if let active = subscriptionManager.activeProductID {
            switch active {
            case .proMonthly:
                return "Pro Monthly"
            case .proYearly:
                return "Pro Yearly"
            case .proLifetime:
                return "Pro Lifetime"
            }
        }
        return "Free"
    }

    public init() {}

    private var resolvedPreference: AIProviderRouter.Preference {
        AIProviderRouter.Preference(rawValue: preferenceRaw) ?? .anthropicPrimary
    }

    private var hasOpenAIKey: Bool {
        !(KeychainHelper.load(.openAIKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnthropicKey: Bool {
        !(KeychainHelper.load(.anthropicKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasDeepSeekKey: Bool {
        !(KeychainHelper.load(.deepSeekKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        Form {
            Section("AI readiness") {
                LabeledContent("Chat") {
                    Text(hasOpenAIKey || hasAnthropicKey || hasDeepSeekKey ? "Keys on device" : "Add a key below")
                        .foregroundStyle(hasOpenAIKey || hasAnthropicKey || hasDeepSeekKey ? .green : .secondary)
                }
                LabeledContent("Portraits / DALL·E") {
                    Text(hasOpenAIKey ? "OpenAI ready" : "Needs OpenAI key")
                        .foregroundStyle(hasOpenAIKey ? .green : .orange)
                }
                Text("Pick order in Chat provider. OpenAI is still required for DALL·E portraits; DeepSeek covers chat when its key is set.")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)
            }

            Section("Chat provider") {
                Picker("Preferred provider", selection: Binding(
                    get: { resolvedPreference },
                    set: { preferenceRaw = $0.rawValue }
                )) {
                    Text("Anthropic first").tag(AIProviderRouter.Preference.anthropicPrimary)
                    Text("OpenAI first").tag(AIProviderRouter.Preference.openAIPrimary)
                    Text("DeepSeek → Anthropic → OpenAI").tag(AIProviderRouter.Preference.deepSeekAnthropicOpenAI)
                    Text("DeepSeek → OpenAI → Anthropic").tag(AIProviderRouter.Preference.deepSeekOpenAIAnthropic)
                }
                .pickerStyle(.inline)
            }

            Section("Subscription") {
                LabeledContent("Current plan", value: activePlanName)
                Text(subscriptionManager.currentEntitlements == .free
                     ? "Unlock deeper personalities, cloud sync, and unlimited pets with Pro."
                     : "Thanks for supporting PIKAPIKA Pro.")
                    .font(PikaTheme.Typography.caption)
                    .foregroundStyle(PikaTheme.Palette.textMuted)

                ForEach(subscriptionManager.products, id: \.id) { product in
                    Button {
                        Task { await purchase(product) }
                    } label: {
                        HStack {
                            Text(product.displayName)
                            Spacer()
                            Text(product.displayPrice)
                                .foregroundStyle(PikaTheme.Palette.textMuted)
                        }
                    }
                    .disabled(purchasingProductID != nil || subscriptionManager.activeProductID?.rawValue == product.id)
                }

                Button("Restore purchases") {
                    Task {
                        SettingsSubscriptionAnalytics.track(.restoreTapped, source: "settings")
                        await subscriptionManager.restorePurchases()
                    }
                }
                .disabled(purchasingProductID != nil)
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
                    Button("Save") {
                        guard !openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        KeychainHelper.save(openAIKey, for: .openAIKey)
                    }
                }
                Section("Anthropic API Key") {
                    SecureField("sk-ant-…", text: $anthropicKey)
                    Button("Save") {
                        guard !anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        KeychainHelper.save(anthropicKey, for: .anthropicKey)
                    }
                }
                Section("DeepSeek API Key") {
                    SecureField("DeepSeek key…", text: $deepSeekKey)
                    Button("Save") {
                        guard !deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        KeychainHelper.save(deepSeekKey, for: .deepSeekKey)
                    }
                    Button("Remove from this device", role: .destructive) {
                        KeychainHelper.delete(.deepSeekKey)
                        deepSeekKey = ""
                    }
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
                                deepSeekKey = KeychainHelper.load(.deepSeekKey) ?? ""
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await subscriptionManager.loadProducts()
            await subscriptionManager.refreshEntitlements()
        }
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

    @MainActor
    private func purchase(_ product: Product) async {
        purchasingProductID = product.id
        defer { purchasingProductID = nil }
        SettingsSubscriptionAnalytics.track(.purchaseStarted, source: "settings")
        do {
            let purchased = try await subscriptionManager.purchase(product)
            if purchased {
                SettingsSubscriptionAnalytics.track(.purchaseSucceeded, source: "settings")
            } else {
                SettingsSubscriptionAnalytics.track(.purchaseNotCompleted, source: "settings")
            }
        } catch {
            SettingsSubscriptionAnalytics.track(.purchaseNotCompleted, source: "settings")
            // Purchase errors are intentionally non-fatal for settings UX.
        }
    }
}

private enum SettingsSubscriptionAnalytics {
    enum Event {
        case restoreTapped
        case purchaseStarted
        case purchaseSucceeded
        case purchaseNotCompleted
    }

    static func track(_ event: Event, source: String) {
        _ = (event, source)
    }
}
