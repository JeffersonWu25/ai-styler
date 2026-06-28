import Foundation
import UIKit

@Observable
final class UserPhotos {
    private(set) var images: [PhotoSlot: UIImage] = [:]
    private(set) var validationErrors: [PhotoSlot: String] = [:]

    var isComplete: Bool {
        PhotoSlot.allCases.allSatisfy { images[$0] != nil && validationErrors[$0] == nil }
    }

    func image(for slot: PhotoSlot) -> UIImage? {
        images[slot]
    }

    func validationError(for slot: PhotoSlot) -> String? {
        validationErrors[slot]
    }

    func setImage(_ image: UIImage, for slot: PhotoSlot) {
        if let error = PhotoValidator.validate(image) {
            images[slot] = nil
            validationErrors[slot] = error
            return
        }

        guard let compressed = ImageCompressor.compress(image) else {
            images[slot] = nil
            validationErrors[slot] = "Could not process this photo. Try another image."
            return
        }

        images[slot] = compressed
        validationErrors[slot] = nil
    }

    func clear(slot: PhotoSlot) {
        images[slot] = nil
        validationErrors[slot] = nil
    }

    func jpegData(for slot: PhotoSlot) -> Data? {
        guard let image = images[slot] else { return nil }
        return image.jpegData(compressionQuality: 0.85)
    }
}
