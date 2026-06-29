import Observation
import UIKit

struct TryOnResult {
    let generationId: String
    let compositeImage: UIImage
    let outfitName: String
    var isSaved: Bool
}

enum AppTab: Hashable {
    case home
    case explore
    case collections
}

enum TryOnDisplayState {
    case empty
    case loading
    case ready(TryOnResult)
    case failed(String)
}

@Observable
@MainActor
final class TryOnSession {
    var selectedTab: AppTab = .home
    private(set) var displayState: TryOnDisplayState = .empty
    private(set) var isSaving = false
    var saveMessage: String?

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var isGenerating: Bool {
        if case .loading = displayState { return true }
        return false
    }

    func generate(from userPhotos: UserPhotos) async {
        guard userPhotos.isComplete else {
            displayState = .failed("Missing one or more photos.")
            selectedTab = .explore
            return
        }

        displayState = .loading
        selectedTab = .explore
        saveMessage = nil

        do {
            let response = try await authService.apiClient.tryOn()
            guard let data = Data(base64Encoded: response.imageBase64),
                  let image = UIImage(data: data) else {
                displayState = .failed("Could not decode the generated image.")
                return
            }
            displayState = .ready(
                TryOnResult(
                    generationId: response.generationId,
                    compositeImage: image,
                    outfitName: response.outfitName,
                    isSaved: false
                )
            )
        } catch TryOnAPIError.unauthorized {
            authService.signOut()
            displayState = .failed("Your session expired. Please sign in again.")
        } catch {
            displayState = .failed(error.localizedDescription)
        }
    }

    func restoreLatestGenerationIfNeeded() async {
        guard case .empty = displayState else { return }

        do {
            let generations = try await authService.apiClient.fetchGenerations()
            guard let latest = generations.first else { return }

            let data = try await authService.apiClient.fetchGenerationImage(id: latest.id)
            guard let image = UIImage(data: data) else { return }

            displayState = .ready(
                TryOnResult(
                    generationId: latest.id,
                    compositeImage: image,
                    outfitName: latest.outfitName,
                    isSaved: latest.isSaved
                )
            )
        } catch TryOnAPIError.unauthorized {
            authService.signOut()
        } catch {
            return
        }
    }

    func saveCurrentGeneration() async {
        guard case .ready(var result) = displayState else { return }
        guard !result.isSaved else { return }

        isSaving = true
        saveMessage = nil
        defer { isSaving = false }

        do {
            _ = try await authService.apiClient.saveGeneration(id: result.generationId)
            result.isSaved = true
            displayState = .ready(result)
            saveMessage = "Saved to Collections."
        } catch TryOnAPIError.unauthorized {
            authService.signOut()
            saveMessage = "Your session expired. Please sign in again."
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    func dismissResult() {
        displayState = .empty
        saveMessage = nil
    }
}
