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
    @State private var showSubscriptionOffer = false
    @ObservedObject private var subscriptionManager = SharedSubscriptionManager.instance
    private let onboardingOfferSeenKey = "com.pikapika.PIKAPIKA.onboardingOfferSeen"

    var body: some View {
        Group {
            if let pet = pets.first {
                PetHomeView(pet: pet)
            } else {
                EmptyStateView(
                    title: "Create your first pet",
                    message: "Your companion awaits. Let's bring them to life.",
                    icon: "pawprint.fill",
                    actionTitle: "Get started"
                ) { showOnboarding = true }
                    .frame(minWidth: 420, minHeight: 320)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            PetOnboardingView { newPet in
                context.insert(newPet)
                do {
                    try context.save()
                } catch {
                    print("Failed to save new pet: \(error.localizedDescription)")
                }
                showOnboarding = false
                Task { await maybeShowSubscriptionOfferAfterOnboarding() }
            }
        }
        .sheet(isPresented: $showSubscriptionOffer) {
            SubscriptionOfferSheet(subscriptionManager: subscriptionManager, source: "onboarding_macos") {
                showSubscriptionOffer = false
                PaywallPresentationGate.endPresentation(source: "onboarding_macos")
                UserDefaults.standard.set(true, forKey: onboardingOfferSeenKey)
            }
            .frame(minWidth: 520, minHeight: 420)
        }
        .task {
            await SharedSubscriptionManager.refreshIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active, showSubscriptionOffer else { return }
            showSubscriptionOffer = false
            PaywallPresentationGate.endPresentation(source: "onboarding_macos")
        }
    }

    @MainActor
    private func maybeShowSubscriptionOfferAfterOnboarding() async {
        guard !UserDefaults.standard.bool(forKey: onboardingOfferSeenKey) else { return }
        await subscriptionManager.refreshEntitlements()
        guard subscriptionManager.currentEntitlements == .free else {
            UserDefaults.standard.set(true, forKey: onboardingOfferSeenKey)
            return
        }
        guard PaywallPresentationGate.beginPresentation(source: "onboarding_macos") else {
            UserDefaults.standard.set(true, forKey: onboardingOfferSeenKey)
            return
        }
        showSubscriptionOffer = true
    }
}
