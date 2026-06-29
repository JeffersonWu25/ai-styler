import SwiftUI

struct SavedLookDetailView: View {
    let generation: GenerationResponse
    @Bindable var store: CollectionsStore

    @State private var panels: [PhotoSlot: UIImage] = [:]
    @State private var selectedSlot: PhotoSlot = .front
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .bottom) {
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
                anglePager
                bottomOverlay
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPanels()
        }
    }

    private var anglePager: some View {
        TabView(selection: $selectedSlot) {
            ForEach(PhotoSlot.allCases) { slot in
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
    }

    private var bottomOverlay: some View {
        VStack(spacing: 12) {
            Picker("Angle", selection: $selectedSlot) {
                ForEach(PhotoSlot.allCases) { slot in
                    Text(slot.title).tag(slot)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text(generation.outfitName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text(generation.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background {
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func loadPanels() async {
        isLoading = true
        defer { isLoading = false }

        let loaded = await store.panels(for: generation.id)
        panels = loaded
        if panels[selectedSlot] == nil {
            selectedSlot = PhotoSlot.allCases.first { panels[$0] != nil } ?? .front
        }
    }
}

#Preview {
    NavigationStack {
        SavedLookDetailView(
            generation: GenerationResponse(
                id: "preview",
                outfitName: "Streetwear",
                isSaved: true,
                createdAt: .now
            ),
            store: CollectionsStore(authService: AuthService())
        )
    }
}
