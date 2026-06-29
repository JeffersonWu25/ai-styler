import Observation
import UIKit

struct TryOnResult {
    let compositeImage: UIImage
    let outfitName: String
}

enum AppTab: Hashable {
    case home
    case explore
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

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var isGenerating: Bool {
        if case .loading = displayState { return true }
        return false
    }

    func generate(from userPhotos: UserPhotos) async {
        guard let front = userPhotos.jpegData(for: .front),
              let side = userPhotos.jpegData(for: .side),
              let back = userPhotos.jpegData(for: .back) else {
            displayState = .failed("Missing one or more photos.")
            selectedTab = .explore
            return
        }

        displayState = .loading
        selectedTab = .explore

        do {
            let response = try await authService.apiClient.tryOn(
                front: front,
                side: side,
                back: back
            )
            guard let data = Data(base64Encoded: response.imageBase64),
                  let image = UIImage(data: data) else {
                displayState = .failed("Could not decode the generated image.")
                return
            }
            displayState = .ready(
                TryOnResult(compositeImage: image, outfitName: response.outfitName)
            )
        } catch TryOnAPIError.unauthorized {
            authService.signOut()
            displayState = .failed("Your session expired. Please sign in again.")
        } catch {
            displayState = .failed(error.localizedDescription)
        }
    }

    func dismissResult() {
        displayState = .empty
    }
}
