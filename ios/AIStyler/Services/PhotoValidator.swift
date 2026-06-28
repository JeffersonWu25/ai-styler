import UIKit

enum PhotoValidator {
    private static let minLongEdge: CGFloat = 600
    private static let maxBytes = 15 * 1024 * 1024

    static func validate(_ image: UIImage) -> String? {
        let size = image.size
        let longEdge = max(size.width, size.height)

        if longEdge < minLongEdge {
            return "Photo is too small. Use a higher resolution image."
        }

        if let data = image.jpegData(compressionQuality: 0.85), data.count > maxBytes {
            return "Photo is too large after compression."
        }

        return nil
    }
}
