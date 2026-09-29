import Observation
import UIKit

@Observable
@MainActor
final class UserPhotosStore {
    let userPhotos = UserPhotos()
    private(set) var isLoading = false
    var syncError: String?

    private let apiClient: TryOnAPIClient

    init(apiClient: TryOnAPIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        syncError = nil
        defer { isLoading = false }

        do {
            let assets = try await apiClient.fetchMeAssets()
            for photo in assets.userPhotos {
                guard let slot = PhotoSlot(rawValue: photo.slot) else { continue }
                let data = try await apiClient.fetchUserPhotoImage(slot: photo.slot)
                guard let image = UIImage(data: data) else { continue }
                userPhotos.setImage(image, for: slot)
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
            _ = try await apiClient.uploadUserPhoto(
                slot: slot.rawValue,
                jpegData: data
            )
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
