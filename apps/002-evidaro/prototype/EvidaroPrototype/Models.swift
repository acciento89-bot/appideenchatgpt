import Foundation
import SwiftData

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

@Model
final class EvidenceItem {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var recordedAt: Date
    var source: String
    var note: String
    var contentHash: String
    var mediaFileName: String?
    var mediaOriginalName: String?
    var mediaUTType: String?
    var mediaHash: String?

    init(
        id: UUID = UUID(),
        kind: EvidenceItemKind,
        recordedAt: Date,
        source: String,
        note: String,
        contentHash: String,
        mediaFileName: String? = nil,
        mediaOriginalName: String? = nil,
        mediaUTType: String? = nil,
        mediaHash: String? = nil
    ) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.recordedAt = recordedAt
        self.source = source
        self.note = note
        self.contentHash = contentHash
        self.mediaFileName = mediaFileName
        self.mediaOriginalName = mediaOriginalName
        self.mediaUTType = mediaUTType
        self.mediaHash = mediaHash
    }

    var kind: EvidenceItemKind {
        EvidenceItemKind(rawValue: kindRawValue) ?? .observation
    }

    var hasMedia: Bool {
        mediaFileName != nil && mediaHash != nil
    }
}

@Model
final class EvidenceSeal {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var itemCount: Int
    var manifestHash: String

    init(id: UUID = UUID(), createdAt: Date, itemCount: Int, manifestHash: String) {
        self.id = id
        self.createdAt = createdAt
        self.itemCount = itemCount
        self.manifestHash = manifestHash
    }
}

@Model
final class EvidenceCase {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRawValue: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var evidence: [EvidenceItem]

    @Relationship(deleteRule: .cascade)
    var seals: [EvidenceSeal]

    init(
        id: UUID = UUID(),
        title: String,
        kind: EvidenceCaseKind,
        createdAt: Date,
        evidence: [EvidenceItem] = [],
        seals: [EvidenceSeal] = []
    ) {
        self.id = id
        self.title = title
        self.kindRawValue = kind.rawValue
        self.createdAt = createdAt
        self.evidence = evidence
        self.seals = seals
    }

    var kind: EvidenceCaseKind {
        EvidenceCaseKind(rawValue: kindRawValue) ?? .other
    }

    var lastActivity: Date {
        max(
            evidence.map(\.recordedAt).max() ?? createdAt,
            seals.map(\.createdAt).max() ?? createdAt
        )
    }
}

struct EvidenceMediaDraft: Sendable {
    let data: Data
    let originalName: String
    let utTypeIdentifier: String
}
