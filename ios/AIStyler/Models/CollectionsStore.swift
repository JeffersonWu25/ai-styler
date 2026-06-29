import Observation
import UIKit

@Observable
@MainActor
final class CollectionsStore {
    private(set) var generations: [GenerationResponse] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private var compositeCache: [String: UIImage] = [:]
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            generations = try await authService.apiClient.fetchSavedGenerations()
        } catch TryOnAPIError.unauthorized {
            authService.signOut()
            errorMessage = "Your session expired. Please sign in again."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func compositeImage(for generationId: String) async -> UIImage? {
        if let cached = compositeCache[generationId] {
            return cached
        }

        do {
            let data = try await authService.apiClient.fetchGenerationImage(id: generationId)
            guard let image = UIImage(data: data) else { return nil }
            compositeCache[generationId] = image
            return image
        } catch {
            return nil
        }
    }

    func frontPanel(for generationId: String) async -> UIImage? {
        guard let composite = await compositeImage(for: generationId) else { return nil }
        return TryOnCompositeImage.panels(from: composite)[.front] ?? composite
    }

    func panels(for generationId: String) async -> [PhotoSlot: UIImage] {
        guard let composite = await compositeImage(for: generationId) else { return [:] }
        let panels = TryOnCompositeImage.panels(from: composite)
        return panels.isEmpty ? [.front: composite] : panels
    }
}
