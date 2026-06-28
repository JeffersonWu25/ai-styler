import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 48))
                .foregroundStyle(.primary)

            Text("AI Styler")
                .font(.largeTitle.bold())

            Text("Phase 1 scaffold ready.\nPhoto capture arrives in Phase 2.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
