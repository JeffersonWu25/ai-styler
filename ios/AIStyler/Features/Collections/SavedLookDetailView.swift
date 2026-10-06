import SwiftUI

struct SavedLookDetailView: View {
    let look: SavedLook
    @Bindable var store: CollectionsStore

    @State private var panels: [PhotoSlot: UIImage] = [:]
    @State private var selectedSlot: PhotoSlot = .front
    @State private var isLoading = true
    @State private var itemImages: [Int: UIImage] = [:]

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if panels.isEmpty {
                ContentUnavailableView {
                    Label("Image unavailable", systemImage: "photo")
                } description: {
                    Text("This look could not be loaded.")
                }
            } else {
                detail
            }
        }
        .navigationTitle(look.outfit.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                anglePager
                    .frame(height: 520)
                    .background(Color.black)

                if panels.count > 1 {
                    Picker("Angle", selection: $selectedSlot) {
                        ForEach(availableSlots) { slot in
                            Text(slot.title).tag(slot)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(look.outfit.name)
                        .font(.title3.bold())
                    Text(look.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !look.outfit.items.isEmpty {
                    Text("Pieces")
                        .font(.headline)

                    ForEach(Array(look.outfit.items.enumerated()), id: \.offset) { index, item in
                        ClothingPieceRow(
                            category: item.category,
                            name: item.name,
                            brand: item.brand,
                            listingUrl: item.listingUrl,
                            image: itemImages[index]
                        )
                    }
                }
            }
            .padding()
        }
    }

    private var availableSlots: [PhotoSlot] {
        PhotoSlot.allCases.filter { panels[$0] != nil }
    }

    private var anglePager: some View {
        TabView(selection: $selectedSlot) {
            ForEach(availableSlots) { slot in
                if let panel = panels[slot] {
                    Image(uiImage: panel)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(slot)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func load() async {
        isLoading = panels.isEmpty
        defer { isLoading = false }

        let loaded = await store.panels(for: look)
        panels = loaded
        if panels[selectedSlot] == nil {
            selectedSlot = availableSlots.first ?? .front
        }

        for (index, item) in look.outfit.items.enumerated() {
            itemImages[index] = await store.itemImage(lookId: look.id, index: index, url: item.imageUrl)
        }
    }
}
