import SwiftUI

struct OutfitDetailView: View {
    let outfitId: UUID
    @Bindable var outfitStore: OutfitStore
    @Bindable var userPhotos: UserPhotos
    @Bindable var collectionsStore: CollectionsStore

    @State private var detail: OutfitDetail?
    @State private var loadError: String?
    @State private var isLoading = true
    @State private var referenceImage: UIImage?
    @State private var itemImages: [UUID: UIImage] = [:]
    @State private var actionError: String?
    @State private var saveMessage: String?

    private var look: GeneratedLook? { outfitStore.looks[outfitId] }
    private var isGenerating: Bool { outfitStore.generatingOutfitId == outfitId }
    private var isSaving: Bool { outfitStore.savingOutfitId == outfitId }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError, detail == nil {
                ContentUnavailableView {
                    Label("Could not load outfit", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadError)
                } actions: {
                    Button("Try Again") {
                        Task { await load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let detail {
                outfitContent(detail)
            }
        }
        .navigationTitle(detail?.name ?? "Outfit")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func outfitContent(_ detail: OutfitDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                referenceSection(detail)
                piecesSection(detail)
                generateSection(detail)

                if let actionError {
                    Text(actionError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let look {
                    TryOnResultView(
                        compositeImage: look.compositeImage,
                        isSaved: look.isSaved,
                        isSaving: isSaving,
                        saveMessage: saveMessage,
                        onSave: {
                            Task { await save() }
                        }
                    )
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func referenceSection(_ detail: OutfitDetail) -> some View {
        if let referenceImage {
            Image(uiImage: referenceImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func piecesSection(_ detail: OutfitDetail) -> some View {
        if !detail.items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pieces")
                    .font(.headline)

                ForEach(detail.items) { item in
                    ClothingPieceRow(
                        category: item.category,
                        name: item.name,
                        brand: item.brand,
                        listingUrl: item.listingUrl,
                        image: itemImages[item.id]
                    )
                }
            }
        }
    }

    private func generateSection(_ detail: OutfitDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { await generate() }
            } label: {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canGenerate(detail))

            if isGenerating {
                HStack {
                    ProgressView()
                    Text("Creating your look… This can take up to 2 minutes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !userPhotos.isComplete {
                Text("Add front, side, and back photos on Home before trying this on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if detail.items.isEmpty {
                Text("This outfit has no pieces yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var buttonTitle: String {
        if isGenerating {
            return "Generating…"
        }
        return look == nil ? "Generate" : "Generate again"
    }

    private func canGenerate(_ detail: OutfitDetail) -> Bool {
        userPhotos.isComplete && !detail.items.isEmpty && !isGenerating
    }

    private func load() async {
        isLoading = detail == nil
        loadError = nil
        defer { isLoading = false }

        do {
            let loaded = try await outfitStore.outfit(id: outfitId)
            detail = loaded
            if let url = loaded.referenceImageUrl {
                referenceImage = await outfitStore.image(
                    forKey: "outfit-ref-\(loaded.id.uuidString)",
                    url: url
                )
            }
            for item in loaded.items {
                itemImages[item.id] = await outfitStore.image(
                    forKey: "clothing-item-\(item.id.uuidString)",
                    url: item.imageUrl
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func generate() async {
        actionError = nil
        saveMessage = nil
        do {
            try await outfitStore.generate(outfitId: outfitId)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func save() async {
        actionError = nil
        saveMessage = nil
        do {
            try await outfitStore.save(outfitId: outfitId, into: collectionsStore)
            saveMessage = "Saved to Collections."
        } catch {
            actionError = error.localizedDescription
        }
    }
}

struct ClothingPieceRow: View {
    let category: String
    let name: String
    let brand: String
    let listingUrl: String
    let image: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(category.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.headline)
                Text(brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let url = URL(string: listingUrl) {
                    Link("View listing", destination: url)
                        .font(.subheadline)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "tshirt")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
