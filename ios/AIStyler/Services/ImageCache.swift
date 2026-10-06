import UIKit

final class ImageCache {
    private var images: [String: UIImage] = [:]
    private let lock = NSLock()
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func image(forKey key: String, url: URL) async -> UIImage? {
        if let cached = image(for: key) {
            return cached
        }

        do {
            let data = try await apiClient.downloadImage(from: url)
            guard let image = UIImage(data: data) else { return nil }
            store(image, for: key)
            return image
        } catch {
            return nil
        }
    }

    func invalidate(key: String) {
        lock.lock()
        images.removeValue(forKey: key)
        lock.unlock()
    }

    private func image(for key: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return images[key]
    }

    private func store(_ image: UIImage, for key: String) {
        lock.lock()
        images[key] = image
        lock.unlock()
    }
}
