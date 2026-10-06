import SwiftUI

struct CollectionsView: View {
    @Bindable var store: CollectionsStore
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.looks.isEmpty {
                    loadingState
                } else if let errorMessage = store.errorMessage, store.looks.isEmpty {
                    errorState(errorMessage)
                } else if store.looks.isEmpty {
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
            .navigationDestination(for: UUID.self) { lookId in
                if let look = store.looks.first(where: { $0.id == lookId }) {
                    SavedLookDetailView(look: look, store: store)
                }
            }
        }
    }

    private var closetList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.looks) { look in
                    NavigationLink(value: look.id) {
                        SavedLookRow(look: look, store: store)
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
            Text("Save a look from an outfit to see it here.")
        } actions: {
            Button("Go to Explore") {
                selectedTab = .explore
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
    let look: SavedLook
    let store: CollectionsStore

    @State private var frontImage: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        SavedLookCard(
            outfitName: look.outfit.name,
            createdAt: look.createdAt,
            frontImage: frontImage,
            isLoadingImage: isLoadingImage
        )
        .padding(.horizontal)
        .task(id: look.id) {
            isLoadingImage = true
            frontImage = await store.frontPanel(for: look)
            isLoadingImage = false
        }
    }
}

#Preview {
    let apiClient = APIClient()
    CollectionsView(
        store: CollectionsStore(apiClient: apiClient, imageCache: ImageCache(apiClient: apiClient)),
        selectedTab: .constant(.collections)
    )
}
