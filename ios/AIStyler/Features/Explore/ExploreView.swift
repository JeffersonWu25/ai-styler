import SwiftUI

struct ExploreView: View {
    @Bindable var tryOnSession: TryOnSession

    var body: some View {
        NavigationStack {
            Group {
                switch tryOnSession.displayState {
                case .empty:
                    emptyState
                case .loading:
                    loadingState
                case .ready(let result):
                    TryOnResultView(
                        compositeImage: result.compositeImage,
                        outfitName: result.outfitName,
                        isSaved: result.isSaved,
                        isSaving: tryOnSession.isSaving,
                        saveMessage: tryOnSession.saveMessage,
                        onSave: {
                            Task { await tryOnSession.saveCurrentGeneration() }
                        },
                        onDismiss: { tryOnSession.dismissResult() }
                    )
                case .failed(let message):
                    failedState(message)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No looks yet", systemImage: "sparkles")
        } description: {
            Text("Generate a look from Home to see it here.")
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Creating your look…")
                .font(.headline)
            Text("This can take up to 2 minutes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func failedState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Generation failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Dismiss") {
                tryOnSession.dismissResult()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ExploreView(tryOnSession: TryOnSession(authService: AuthService()))
}
