import SwiftUI
import SwiftData
import PikaCore
import PikaSubscription

struct PetListView: View {
    @Query(sort: \Pet.name) private var pets: [Pet]
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddPet = false
    @State private var showSettings = false
    @State private var showSubscriptionOffer = false
    @ObservedObject private var subscriptionManager = SharedSubscriptionManager.instance

    private static let freePetCap = 1

    private var totalStreak: Int {
        pets.map(\.streakCount).max() ?? 0
    }

    private var hasUnlimitedPets: Bool {
        subscriptionManager.currentEntitlements.contains(.unlimitedPets)
    }

    private var canCreateMorePets: Bool {
        hasUnlimitedPets || pets.count < Self.freePetCap
    }

    private var showPetLimitBanner: Bool {
        !hasUnlimitedPets && pets.count >= Self.freePetCap
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader

                    if pets.isEmpty {
                        emptyState
                            .padding(.top, 28)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            if showPetLimitBanner {
                                petLimitBanner
                                    .padding(.horizontal, PikaMetrics.screenHorizontal)
                                    .padding(.top, 20)
                            }
                            HStack {
                                PikaSectionHeader(
                                    title: "Your companions",
                                    subtitle: "Tap in daily — spirits stay brighter together."
                                )
                                Spacer()
                            }
                            .padding(.horizontal, PikaMetrics.screenHorizontal)
                            .padding(.top, 20)

                            LazyVStack(spacing: 12) {
                                ForEach(pets, id: \.id) { pet in
                                    let spirit = PetSpiritState.evaluate(for: pet)
                                    NavigationLink {
                                        PetDetailView(pet: pet)
                                    } label: {
                                        PetHomeCard(
                                            pet: pet,
                                            spirit: spirit,
                                            thumbnail: PetImageStore.loadImage(relativePath: pet.avatarImagePath)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, PikaMetrics.screenHorizontal)
                                }
                            }
                        }
                        .padding(.bottom, 28)
                    }
                }
            }
            .background(PIKAPIKATheme.homeBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PIKAPIKATheme.warmth)
                        Text("PIKAPIKA")
                            .font(.headline.weight(.heavy))
                            .tracking(0.5)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await handleAddPetTapped() }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(PIKAPIKATheme.accent, PIKAPIKATheme.accentSecondary)
                    }
                    .accessibilityLabel("Add companion")
                }
            }
            .sheet(isPresented: $showAddPet) {
                AddPetSheet()
            }
            .sheet(isPresented: $showSubscriptionOffer) {
                SubscriptionOfferSheet(subscriptionManager: subscriptionManager, source: "pet_limit") {
                    showSubscriptionOffer = false
                    PaywallPresentationGate.endPresentation(source: "pet_limit")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase != .active, showSubscriptionOffer else { return }
                showSubscriptionOffer = false
                PaywallPresentationGate.endPresentation(source: "pet_limit")
            }
            .task {
                await SharedSubscriptionManager.refreshIfNeeded()
            }
        }
        .tint(PIKAPIKATheme.accent)
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            PIKAPIKATheme.heroGradient
                .frame(height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .overlay {
                    LinearGradient(
                        colors: [.clear, Color(.systemGroupedBackground)],
                        startPoint: UnitPoint(x: 0.5, y: 0.35),
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 10) {
                Text(greetingLine)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Raise a companion with real memory, mood, and heart — like the classic desktop pet, reborn with AI.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    statPill(icon: "pawprint.fill", value: "\(pets.count)", label: "pets")
                    statPill(icon: "flame.fill", value: "\(totalStreak)", label: "best streak")
                }
            }
            .padding(.horizontal, PikaMetrics.screenHorizontal)
            .padding(.bottom, 20)
        }
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Hey, night owl"
        }
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(value)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .opacity(0.9)
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule().fill(.white.opacity(0.22))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("🐧✨")
                .font(.system(size: 52))
            Text("No companion yet")
                .font(.title3.weight(.bold))
            Text("Create a unique soul — describe anything, upload art, or generate a portrait. They’ll remember you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                showAddPet = true
            } label: {
                Label("Create your first pet", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(PikaProminentButtonStyle())
            .padding(.horizontal, PikaMetrics.screenHorizontal)
        }
        .frame(maxWidth: .infinity)
    }

    private var petLimitBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .foregroundStyle(PIKAPIKATheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Free plan limit reached")
                    .font(.subheadline.weight(.semibold))
                Text("Upgrade to Pro for unlimited companions and richer personalities.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("See Pro") {
                if PaywallPresentationGate.beginPresentation(source: "pet_limit") {
                    showSubscriptionOffer = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(PIKAPIKATheme.accent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    @MainActor
    private func handleAddPetTapped() async {
        await SharedSubscriptionManager.forceRefresh()
        if canCreateMorePets {
            showAddPet = true
            return
        }
        if PaywallPresentationGate.beginPresentation(source: "pet_limit") {
            showSubscriptionOffer = true
        }
    }
}
