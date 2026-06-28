import PhotosUI
import SwiftUI

struct PhotoSlotCard: View {
    let slot: PhotoSlot
    let image: UIImage?
    let validationError: String?
    let onImageSelected: (UIImage) -> Void
    let onClear: () -> Void

    @State private var selectedItem: PhotosPickerItem?

    private var isValid: Bool {
        image != nil && validationError == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(slot.title, systemImage: slot.systemImageName)
                    .font(.headline)

                Spacer()

                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Add \(slot.title.lowercased()) photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                }
            }

            Text(slot.guidance)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text(image == nil ? "Choose Photo" : "Replace Photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if image != nil {
                    Button("Clear", role: .destructive) {
                        selectedItem = nil
                        onClear()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isValid ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        )
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        onImageSelected(uiImage)
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoSlotCard(
        slot: .front,
        image: nil,
        validationError: nil,
        onImageSelected: { _ in },
        onClear: {}
    )
    .padding()
}
