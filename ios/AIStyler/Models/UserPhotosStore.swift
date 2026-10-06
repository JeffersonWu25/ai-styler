import Observation
import UIKit

@Observable
@MainActor
final class UserPhotosStore {
    let userPhotos = UserPhotos()
    private(set) var isLoading = false
    var syncError: String?

    private let apiClient: APIClient
    private let imageCache: ImageCache

    init(apiClient: APIClient, imageCache: ImageCache) {
        self.apiClient = apiClient
        self.imageCache = imageCache
    }

    func load() async {
        isLoading = true
        syncError = nil
        defer { isLoading = false }

        do {
            let user = try await apiClient.fetchUser()
            var failed = false

            for slot in PhotoSlot.allCases {
                guard let photo = user.photos.photo(for: slot) else {
                    userPhotos.clear(slot: slot)
                    continue
                }

                if let image = await imageCache.image(
                    forKey: "user-photo-\(slot.rawValue)",
                    url: photo.imageUrl
                ) {
                    userPhotos.restore(image, for: slot)
                } else {
                    failed = true
                }
            }

            if failed {
                syncError = "Could not load one or more photos."
            }
        } catch {
            syncError = error.localizedDescription
        }
    }

    func setImage(_ image: UIImage, for slot: PhotoSlot) async {
        userPhotos.setImage(image, for: slot)
        guard userPhotos.validationError(for: slot) == nil,
              let data = userPhotos.jpegData(for: slot) else {
            return
        }

        syncError = nil
        do {
            _ = try await apiClient.uploadUserPhoto(slot: slot.rawValue, jpegData: data)
            imageCache.invalidate(key: "user-photo-\(slot.rawValue)")
        } catch {
            syncError = error.localizedDescription
        }
    }

    func clear(slot: PhotoSlot) async {
        userPhotos.clear(slot: slot)
        syncError = nil

        do {
            try await apiClient.deleteUserPhoto(slot: slot.rawValue)
        } catch {
            syncError = error.localizedDescription
        }
    }
}
