import Observation
import UIKit

@Observable
@MainActor
final class CollectionsStore {
    private(set) var looks: [SavedLook] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private var compositeCache: [UUID: UIImage] = [:]
    private let apiClient: APIClient
    private let imageCache: ImageCache

    init(apiClient: APIClient, imageCache: ImageCache) {
        self.apiClient = apiClient
        self.imageCache = imageCache
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            looks = try await apiClient.fetchSavedLooks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func upsert(_ look: SavedLook) {
        if let index = looks.firstIndex(where: { $0.id == look.id }) {
            looks[index] = look
        } else {
            looks.insert(look, at: 0)
        }
    }

    func compositeImage(for look: SavedLook) async -> UIImage? {
        if let cached = compositeCache[look.id] {
            return cached
        }

        guard let image = await imageCache.image(
            forKey: "saved-look-\(look.id.uuidString)",
            url: look.imageUrl
        ) else {
            return nil
        }

        compositeCache[look.id] = image
        return image
    }

    func frontPanel(for look: SavedLook) async -> UIImage? {
        guard let composite = await compositeImage(for: look) else { return nil }
        return TryOnCompositeImage.panels(from: composite)[.front] ?? composite
    }

    func panels(for look: SavedLook) async -> [PhotoSlot: UIImage] {
        guard let composite = await compositeImage(for: look) else { return [:] }
        let panels = TryOnCompositeImage.panels(from: composite)
        return panels.isEmpty ? [.front: composite] : panels
    }

    func itemImage(lookId: UUID, index: Int, url: URL) async -> UIImage? {
        await imageCache.image(forKey: "saved-look-\(lookId.uuidString)-item-\(index)", url: url)
    }
}
