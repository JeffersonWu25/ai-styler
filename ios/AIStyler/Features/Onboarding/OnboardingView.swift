import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("For the best try-on results, upload three clear full-body photos.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    tipRow(
                        icon: "person.fill",
                        title: "Front, side, and back",
                        detail: "Capture each angle separately so we can learn your shape."
                    )
                    tipRow(
                        icon: "figure.stand",
                        title: "Full body in frame",
                        detail: "Head to toe works best, with a neutral standing pose."
                    )
                    tipRow(
                        icon: "sun.max",
                        title: "Good lighting",
                        detail: "Use even light and a plain background when possible."
                    )
                    tipRow(
                        icon: "camera",
                        title: "Front photo matters most",
                        detail: "The first try-on uses your front photo plus outfit references."
                    )
                }
                .padding()
            }
            .navigationTitle("Photo Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got it") { dismiss() }
                }
            }
        }
    }

    private func tipRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
