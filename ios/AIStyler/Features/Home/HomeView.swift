import SwiftUI

struct HomeView: View {
    @Bindable var userPhotosStore: UserPhotosStore
    @Bindable var tryOnSession: TryOnSession
    @Bindable var authService: AuthService

    private var userPhotos: UserPhotos { userPhotosStore.userPhotos }

    @State private var showOnboarding = false
    @State private var backendConnected: Bool?
    @State private var isCheckingBackend = false
    @State private var backendError: String?

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
                            onImageSelected: { image in
                                Task { await userPhotosStore.setImage(image, for: slot) }
                            },
                            onClear: {
                                Task { await userPhotosStore.clear(slot: slot) }
                            }
                        )
                    }

                    if let syncError = userPhotosStore.syncError {
                        Text(syncError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if userPhotosStore.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading your photos…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    generateSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") {
                        authService.signOut()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tips") { showOnboarding = true }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .task {
                await refreshBackendStatus()
            }
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

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outfit")
                .font(.headline)
            Text(AppConfig.defaultOutfitName)
                .font(.title3.bold())

            Button {
                Task { await tryOnSession.generate(from: userPhotos) }
            } label: {
                Text(tryOnSession.isGenerating ? "Generating…" : "Generate")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyToGenerate)

            if !userPhotos.isComplete {
                Text("Add valid front, side, and back photos to continue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if backendConnected != true {
                Text("Connect to the backend before generating.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Your look will appear in Explore.")
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

    private var isReadyToGenerate: Bool {
        userPhotos.isComplete && backendConnected == true && !tryOnSession.isGenerating
    }

    @MainActor
    private func refreshBackendStatus() async {
        isCheckingBackend = true
        backendError = nil
        defer { isCheckingBackend = false }

        do {
            backendConnected = try await authService.apiClient.checkHealth()
        } catch {
            backendConnected = false
            backendError = error.localizedDescription
        }
    }
}

#Preview {
    let authService = AuthService()
    HomeView(
        userPhotosStore: UserPhotosStore(authService: authService),
        tryOnSession: TryOnSession(authService: authService),
        authService: authService
    )
}
