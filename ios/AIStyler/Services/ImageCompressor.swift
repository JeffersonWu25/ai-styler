import UIKit

enum ImageCompressor {
    private static let maxLongEdge: CGFloat = 2048
    private static let jpegQuality: CGFloat = 0.85

    static func compress(_ image: UIImage) -> UIImage? {
        let resized = resize(image, maxLongEdge: maxLongEdge)
        guard let data = resized.jpegData(compressionQuality: jpegQuality),
              let compressed = UIImage(data: data) else {
            return nil
        }
        return compressed
    }

    private static func resize(_ image: UIImage, maxLongEdge: CGFloat) -> UIImage {
        let size = image.size
        let longEdge = max(size.width, size.height)

        guard longEdge > maxLongEdge else { return image }

        let scale = maxLongEdge / longEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
