import UIKit

enum TryOnCompositeImage {
    /// Splits a horizontal triptych (front | side | back) into individual panel images.
    static func panels(from composite: UIImage) -> [PhotoSlot: UIImage] {
        guard let cgImage = composite.cgImage else { return [:] }

        let width = cgImage.width
        let height = cgImage.height
        guard width >= 3, height > 0 else { return [:] }

        let panelWidth = width / 3
        let slots: [PhotoSlot] = [.front, .side, .back]
        var result: [PhotoSlot: UIImage] = [:]

        for (index, slot) in slots.enumerated() {
            let rect = CGRect(
                x: index * panelWidth,
                y: 0,
                width: panelWidth,
                height: height
            )
            guard let cropped = cgImage.cropping(to: rect) else { continue }
            result[slot] = UIImage(
                cgImage: cropped,
                scale: composite.scale,
                orientation: composite.imageOrientation
            )
        }

        return result
    }
}
