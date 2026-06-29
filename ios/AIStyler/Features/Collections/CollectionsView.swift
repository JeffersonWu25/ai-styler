import SwiftUI

struct CollectionsView: View {
    @Bindable var store: CollectionsStore
    @Bindable var tryOnSession: TryOnSession

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.generations.isEmpty {
                    loadingState
                } else if let errorMessage = store.errorMessage, store.generations.isEmpty {
                    errorState(errorMessage)
                } else if store.generations.isEmpty {
                    emptyState
                } else {
                    closetList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.load()
            }
            .task {
                await store.load()
            }
            .navigationDestination(for: GenerationResponse.self) { generation in
                SavedLookDetailView(generation: generation, store: store)
            }
        }
    }

    private var closetList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.generations) { generation in
                    NavigationLink(value: generation) {
                        SavedLookRow(
                            generation: generation,
                            store: store
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading your looks…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No saved looks", systemImage: "bookmark")
        } description: {
            Text("Save a look from Explore to see it here.")
        } actions: {
            Button("Go to Explore") {
                tryOnSession.selectedTab = .explore
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Could not load looks", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await store.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct SavedLookRow: View {
    let generation: GenerationResponse
    let store: CollectionsStore

    @State private var frontImage: UIImage?

    var body: some View {
        SavedLookCard(
            outfitName: generation.outfitName,
            createdAt: generation.createdAt,
            frontImage: frontImage
        )
        .padding(.horizontal)
        .task(id: generation.id) {
            frontImage = await store.frontPanel(for: generation.id)
        }
    }
}

#Preview {
    CollectionsView(
        store: CollectionsStore(authService: AuthService()),
        tryOnSession: TryOnSession(authService: AuthService())
    )
}
