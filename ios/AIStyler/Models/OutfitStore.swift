import Observation
import UIKit

struct GeneratedLook {
    let tryOnId: UUID
    let compositeImage: UIImage
    var isSaved: Bool
}

@Observable
@MainActor
final class OutfitStore {
    private(set) var outfits: [OutfitSummary] = []
    private(set) var isLoading = false
    private(set) var looks: [UUID: GeneratedLook] = [:]
    private(set) var generatingOutfitId: UUID?
    private(set) var savingOutfitId: UUID?
    var errorMessage: String?

    private var details: [UUID: OutfitDetail] = [:]
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
            outfits = try await apiClient.fetchOutfits()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func outfit(id: UUID) async throws -> OutfitDetail {
        if let cached = details[id] {
            return cached
        }

        let detail = try await apiClient.fetchOutfit(id: id)
        details[id] = detail
        return detail
    }

    func image(forKey key: String, url: URL) async -> UIImage? {
        await imageCache.image(forKey: key, url: url)
    }

    func generate(outfitId: UUID) async throws {
        generatingOutfitId = outfitId
        defer { generatingOutfitId = nil }

        let response = try await apiClient.createTryOn(outfitId: outfitId)
        guard let image = await imageCache.image(
            forKey: "try-on-\(response.id.uuidString)",
            url: response.imageUrl
        ) else {
            throw APIError.apiError("Could not load the generated image.")
        }

        looks[outfitId] = GeneratedLook(
            tryOnId: response.id,
            compositeImage: image,
            isSaved: false
        )
    }

    func save(outfitId: UUID, into collections: CollectionsStore) async throws {
        guard var look = looks[outfitId], !look.isSaved else { return }

        savingOutfitId = outfitId
        defer { savingOutfitId = nil }

        let saved = try await apiClient.saveLook(tryOnId: look.tryOnId)
        look.isSaved = true
        looks[outfitId] = look
        collections.upsert(saved)
    }
}
