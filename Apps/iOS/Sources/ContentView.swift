import SwiftUI
import SwiftData
import PikaCore
import PikaSubscription
import SharedUI

struct ContentView: View {
    @Query private var pets: [Pet]
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOnboarding = false
    @State private var paywallPresentation: PaywallPresentationCoordinator.ActivePresentation?
    private let onboardingOfferSeenKey = "com.pikapika.PIKAPIKA.onboardingOfferSeen"

    var body: some View {
        NavigationStack {
            Group {
                if let pet = pets.first {
                    PetHomeView(pet: pet)
                } else {
                    EmptyStateView(
                        title: "No pet yet",
                        message: "Let's create one together.",
                        icon: "pawprint.fill",
                        actionTitle: "Create my pet"
                    ) { showOnboarding = true }
                }
            }
            .navigationTitle("Pika")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                PetOnboardingView { newPet in
                    context.insert(newPet)
                    do {
                        try context.save()
                    } catch {
                        // Keep onboarding open if persistence fails so the user can retry safely.
                        return
                    }
                    showOnboarding = false
                    Task { await maybeShowSubscriptionOfferAfterOnboarding() }
                }
            }
            .paywallOfferSheet(presentation: $paywallPresentation) {
                UserDefaults.standard.set(true, forKey: onboardingOfferSeenKey)
            }
            .task {
                await SharedSubscriptionManager.refreshIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await SharedSubscriptionManager.refreshIfNeeded(minInterval: 5) }
                }
                guard newPhase != .active, paywallPresentation != nil else { return }
                PaywallPresentationCoordinator.clearBinding(&paywallPresentation)
            }
        }
    }

    @MainActor
    private func maybeShowSubscriptionOfferAfterOnboarding() async {
        guard !UserDefaults.standard.bool(forKey: onboardingOfferSeenKey) else { return }
        if let presentation = await PaywallPresentationCoordinator.requestPresentation(
            source: "onboarding_ios",
            forceRefresh: true
        ) {
            paywallPresentation = presentation
        } else {
            UserDefaults.standard.set(true, forKey: onboardingOfferSeenKey)
        }
    }
}
