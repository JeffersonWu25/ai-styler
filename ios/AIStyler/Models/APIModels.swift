import Foundation

struct PhotoResponse: Decodable, Hashable {
    let slot: String
    let imageUrl: URL
}

struct UserPhotosResponse: Decodable, Hashable {
    let front: PhotoResponse?
    let side: PhotoResponse?
    let back: PhotoResponse?

    func photo(for slot: PhotoSlot) -> PhotoResponse? {
        switch slot {
        case .front: front
        case .side: side
        case .back: back
        }
    }
}

struct UserResponse: Decodable {
    let id: UUID
    let username: String
    let email: String
    let photos: UserPhotosResponse
}

struct OutfitSummary: Decodable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let referenceImageUrl: URL?
    let createdAt: Date
}

struct ClothingItem: Decodable, Identifiable, Hashable {
    let id: UUID
    let category: String
    let name: String
    let brand: String
    let listingUrl: String
    let imageUrl: URL
    let createdAt: Date
}

struct OutfitDetail: Decodable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let referenceImageUrl: URL?
    let createdAt: Date
    let items: [ClothingItem]
}

struct TryOnResponse: Decodable {
    let id: UUID
    let outfitId: UUID?
    let outfitName: String
    let imageUrl: URL
    let createdAt: Date
}

struct SavedLookItem: Decodable, Hashable {
    let category: String
    let name: String
    let brand: String
    let listingUrl: String
    let imageUrl: URL
}

struct SavedLookOutfit: Decodable, Hashable {
    let name: String
    let items: [SavedLookItem]
}

struct SavedLook: Decodable, Identifiable, Hashable {
    let id: UUID
    let tryOnId: UUID?
    let imageUrl: URL
    let createdAt: Date
    let outfit: SavedLookOutfit
}
