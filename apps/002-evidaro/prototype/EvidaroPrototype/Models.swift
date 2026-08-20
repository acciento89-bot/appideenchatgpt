import Foundation

enum EvidenceCaseKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case property = "Property"
    case delivery = "Delivery"
    case vehicle = "Vehicle"
    case contractor = "Contractor"
    case insurance = "Insurance"
    case workplace = "Workplace"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .property: "house"
        case .delivery: "shippingbox"
        case .vehicle: "car"
        case .contractor: "wrench.and.screwdriver"
        case .insurance: "shield"
        case .workplace: "briefcase"
        case .other: "folder"
        }
    }
}

enum EvidenceItemKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case observation = "Observation"
    case photo = "Photo"
    case document = "Document"
    case message = "Message"
    case callNote = "Call note"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .observation: "note.text"
        case .photo: "photo"
        case .document: "doc.text"
        case .message: "bubble.left.and.bubble.right"
        case .callNote: "phone"
        }
    }
}

struct EvidenceItem: Identifiable, Hashable, Codable {
    let id: UUID
    let kind: EvidenceItemKind
    let recordedAt: Date
    let source: String
    let note: String
    let contentHash: String
}

struct EvidenceSeal: Identifiable, Hashable, Codable {
    let id: UUID
    let createdAt: Date
    let itemCount: Int
    let manifestHash: String
}

struct EvidenceCase: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var kind: EvidenceCaseKind
    let createdAt: Date
    var evidence: [EvidenceItem]
    var seals: [EvidenceSeal]

    var lastActivity: Date {
        max(
            evidence.map(\.recordedAt).max() ?? createdAt,
            seals.map(\.createdAt).max() ?? createdAt
        )
    }
}
