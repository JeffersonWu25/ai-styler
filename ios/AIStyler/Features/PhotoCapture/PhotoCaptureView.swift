import SwiftUI

struct PhotoCaptureView: View {
    @Bindable var userPhotos: UserPhotos

    @State private var showOnboarding = false
    @State private var backendConnected: Bool?
    @State private var isCheckingBackend = false
    @State private var backendError: String?

    @State private var isGenerating = false
    @State private var tryOnError: String?
    @State private var resultImage: UIImage?
    @State private var resultOutfitName: String?
    @State private var showResult = false

    private let apiClient = TryOnAPIClient()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    backendStatusCard

                    ForEach(PhotoSlot.allCases) { slot in
                        PhotoSlotCard(
                            slot: slot,
                            image: userPhotos.image(for: slot),
                            validationError: userPhotos.validationError(for: slot),
                            onImageSelected: { userPhotos.setImage($0, for: slot) },
                            onClear: { userPhotos.clear(slot: slot) }
                        )
                    }

                    tryOnSection
                }
                .padding()
            }
            .navigationTitle("Your Photos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tips") { showOnboarding = true }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .fullScreenCover(isPresented: $showResult) {
                if let resultImage, let resultOutfitName {
                    TryOnResultView(
                        image: resultImage,
                        outfitName: resultOutfitName,
                        onDone: { showResult = false }
                    )
                }
            }
            .overlay {
                if isGenerating {
                    generatingOverlay
                }
            }
            .task {
                await refreshBackendStatus()
            }
        }
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Creating your look…")
                    .font(.headline)
                Text("This can take up to 2 minutes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private var backendStatusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Backend")
                    .font(.headline)
                Spacer()
                if isCheckingBackend {
                    ProgressView()
                } else if backendConnected == true {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else {
                    Label("Offline", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            Text(AppConfig.apiBaseURL.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let backendError {
                Text(backendError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Check Connection") {
                Task { await refreshBackendStatus() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var tryOnSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outfit")
                .font(.headline)
            Text(AppConfig.defaultOutfitName)
                .font(.title3.bold())

            Button {
                Task { await runTryOn() }
            } label: {
                Text(isGenerating ? "Generating…" : "Try On Outfit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyForTryOn)

            if let tryOnError {
                Text(tryOnError)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if !userPhotos.isComplete {
                Text("Add valid front, side, and back photos to continue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if backendConnected != true {
                Text("Connect to the backend before trying on an outfit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Uses your front photo plus the hardcoded outfit references.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var isReadyForTryOn: Bool {
        userPhotos.isComplete && backendConnected == true && !isGenerating
    }

    @MainActor
    private func refreshBackendStatus() async {
        isCheckingBackend = true
        backendError = nil
        defer { isCheckingBackend = false }

        do {
            backendConnected = try await apiClient.checkHealth()
        } catch {
            backendConnected = false
            backendError = error.localizedDescription
        }
    }

    @MainActor
    private func runTryOn() async {
        guard let front = userPhotos.jpegData(for: .front),
              let side = userPhotos.jpegData(for: .side),
              let back = userPhotos.jpegData(for: .back) else {
            tryOnError = "Missing one or more photos."
            return
        }

        isGenerating = true
        tryOnError = nil
        defer { isGenerating = false }

        do {
            let response = try await apiClient.tryOn(front: front, side: side, back: back)
            guard let data = Data(base64Encoded: response.imageBase64),
                  let image = UIImage(data: data) else {
                tryOnError = "Could not decode the generated image."
                return
            }
            resultImage = image
            resultOutfitName = response.outfitName
            showResult = true
        } catch {
            tryOnError = error.localizedDescription
        }
    }
}

#Preview {
    PhotoCaptureView(userPhotos: UserPhotos())
}
