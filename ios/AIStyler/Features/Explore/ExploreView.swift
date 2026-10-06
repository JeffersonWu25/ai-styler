import SwiftUI

struct ExploreView: View {
    @Bindable var outfitStore: OutfitStore
    let userPhotos: UserPhotos
    @Bindable var collectionsStore: CollectionsStore

    var body: some View {
        NavigationStack {
            Group {
                if outfitStore.isLoading && outfitStore.outfits.isEmpty {
                    loadingState
                } else if let errorMessage = outfitStore.errorMessage, outfitStore.outfits.isEmpty {
                    errorState(errorMessage)
                } else if outfitStore.outfits.isEmpty {
                    emptyState
                } else {
                    outfitList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await outfitStore.load()
            }
            .navigationDestination(for: UUID.self) { outfitId in
                OutfitDetailView(
                    outfitId: outfitId,
                    outfitStore: outfitStore,
                    userPhotos: userPhotos,
                    collectionsStore: collectionsStore
                )
            }
        }
    }

    private var outfitList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(outfitStore.outfits) { outfit in
                    NavigationLink(value: outfit.id) {
                        OutfitCard(outfit: outfit, outfitStore: outfitStore)
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
            Text("Loading outfits…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No outfits yet", systemImage: "tshirt")
        } description: {
            Text("Outfits added to the catalog will show up here.")
        }
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Could not load outfits", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await outfitStore.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct OutfitCard: View {
    let outfit: OutfitSummary
    let outfitStore: OutfitStore

    @State private var image: UIImage?
    @State private var isLoadingImage = false

    var body: some View {
        ZStack(alignment: .bottom) {
            imageContent
            bottomGradient
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .task(id: outfit.id) {
            guard let url = outfit.referenceImageUrl else { return }
            isLoadingImage = true
            image = await outfitStore.image(forKey: "outfit-ref-\(outfit.id.uuidString)", url: url)
            isLoadingImage = false
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if isLoadingImage {
            Color(.secondarySystemBackground)
                .overlay {
                    ProgressView()
                }
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var bottomGradient: some View {
        Text(outfit.name)
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

#Preview {
    let apiClient = APIClient()
    let imageCache = ImageCache(apiClient: apiClient)
    ExploreView(
        outfitStore: OutfitStore(apiClient: apiClient, imageCache: imageCache),
        userPhotos: UserPhotos(),
        collectionsStore: CollectionsStore(apiClient: apiClient, imageCache: imageCache)
    )
}
