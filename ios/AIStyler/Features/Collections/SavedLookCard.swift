import SwiftUI

struct SavedLookCard: View {
    let outfitName: String
    let createdAt: Date
    let frontImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            imageContent
            bottomGradient
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var imageContent: some View {
        if let frontImage {
            Image(uiImage: frontImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    ProgressView()
                }
        }
    }

    private var bottomGradient: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(outfitName)
                .font(.title3.bold())
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                Text(createdAt.formatted(.relative(presentation: .named)))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                angleIndicator
            }
        }
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

    private var angleIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == 0 ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityLabel("3 views")
    }
}

#Preview {
    SavedLookCard(
        outfitName: "Streetwear",
        createdAt: .now,
        frontImage: UIImage(systemName: "person.fill")
    )
    .padding()
}
