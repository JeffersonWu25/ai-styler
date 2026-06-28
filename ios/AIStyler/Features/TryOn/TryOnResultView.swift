import SwiftUI

struct TryOnResultView: View {
    let compositeImage: UIImage
    let outfitName: String
    let onSave: () -> Void
    let onDismiss: () -> Void

    private var panels: [PhotoSlot: UIImage] {
        TryOnCompositeImage.panels(from: compositeImage)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(outfitName)
                    .font(.title2.bold())

                if panels.count == PhotoSlot.allCases.count {
                    ForEach(PhotoSlot.allCases) { slot in
                        panelSection(for: slot)
                    }
                } else {
                    fallbackSection
                }

                actionFooter
            }
            .padding()
        }
    }

    @ViewBuilder
    private func panelSection(for slot: PhotoSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.title)
                .font(.headline)

            if let panel = panels[slot] {
                Image(uiImage: panel)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var fallbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try-On Result")
                .font(.headline)

            Image(uiImage: compositeImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var actionFooter: some View {
        VStack(spacing: 12) {
            Button(action: onSave) {
                Label("Save", systemImage: "bookmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)

            Text("Sign in to save — coming in a future update.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: onDismiss) {
                Label("Close", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }
}

#Preview {
    TryOnResultView(
        compositeImage: UIImage(systemName: "person.fill")!,
        outfitName: "Streetwear",
        onSave: {},
        onDismiss: {}
    )
}
