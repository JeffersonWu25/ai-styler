import SwiftUI

struct ContentView: View {
    @State private var userPhotos = UserPhotos()

    var body: some View {
        PhotoCaptureView(userPhotos: userPhotos)
    }
}

#Preview {
    ContentView()
}
