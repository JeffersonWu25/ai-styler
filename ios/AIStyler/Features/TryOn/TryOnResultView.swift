import SwiftUI

struct TryOnResultView: View {
    let image: UIImage
    let outfitName: String
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(outfitName)
                        .font(.title2.bold())

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Your Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
    }
}

#Preview {
    TryOnResultView(
        image: UIImage(systemName: "person.fill")!,
        outfitName: "Old Money",
        onDone: {}
    )
}
