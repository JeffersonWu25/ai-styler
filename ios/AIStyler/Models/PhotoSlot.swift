import Foundation

enum PhotoSlot: String, CaseIterable, Identifiable {
    case front
    case side
    case back

    var id: String { rawValue }

    var title: String {
        switch self {
        case .front: "Front"
        case .side: "Side"
        case .back: "Back"
        }
    }

    var guidance: String {
        switch self {
        case .front: "Face the camera, full body visible"
        case .side: "Turn to your side, full body visible"
        case .back: "Face away from the camera, full body visible"
        }
    }

    var systemImageName: String {
        switch self {
        case .front: "person.fill"
        case .side: "person.fill.turn.right"
        case .back: "person.fill.turn.down"
        }
    }
}
