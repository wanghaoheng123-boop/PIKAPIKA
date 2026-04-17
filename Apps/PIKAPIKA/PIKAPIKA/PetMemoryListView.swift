import SwiftData
import SwiftUI
import PikaCore

struct PetMemoryListView: View {
    @Bindable var pet: Pet

    @Environment(\.modelContext) private var modelContext
    @State private var errorText: String?

    private var facts: [PetMemoryFact] {
        pet.memoryFacts.sorted {
            if $0.importance != $1.importance { return $0.importance > $1.importance }
            return $0.createdAt > $1.createdAt
        }
    }

    var body: some View {
        Group {
            if facts.isEmpty {
                ContentUnavailableView {
                    Label("No memories yet", systemImage: "sparkles")
                } description: {
                    Text("Chat with \(pet.name) — they’ll learn what matters to you, one moment at a time.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        PikaSectionHeader(
                            title: "What \(pet.name) remembers",
                            subtitle: "Priority P0 = critical, P1 = useful, P2 = nice-to-have."
                        )
                    }
                    .listRowBackground(Color.clear)

                    ForEach(facts, id: \.id) { fact in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(fact.content)
                                .font(.body)
                            HStack {
                                Text(fact.category)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(PIKAPIKATheme.accent)
                                Spacer()
                                Text(priorityLabel(fact.importance))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteFacts)
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(PIKAPIKATheme.homeBackground.ignoresSafeArea())
        .navigationTitle("Memories")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could not save changes", isPresented: Binding(
            get: { errorText != nil },
            set: { newValue in
                if !newValue { errorText = nil }
            }
        )) {
            Button("OK", role: .cancel) { errorText = nil }
        } message: {
            Text(errorText ?? "Unknown error")
        }
    }

    private func priorityLabel(_ i: Int) -> String {
        switch i {
        case 2: return "P0"
        case 1: return "P1"
        default: return "P2"
        }
    }

    private func deleteFacts(at offsets: IndexSet) {
        for i in offsets {
            let fact = facts[i]
            modelContext.delete(fact)
        }
        do {
            try modelContext.save()
        } catch {
            errorText = error.localizedDescription
        }
        PetMemoryFileStore.syncFacts(petId: pet.id, petName: pet.name, facts: pet.memoryFacts)
    }
}
