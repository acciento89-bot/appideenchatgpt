import Foundation

enum MemberRole: String, CaseIterable, Codable, Sendable {
    case owner
    case adult
    case child
    case guest

    var displayName: String {
        switch self {
        case .owner: "Owner"
        case .adult: "Erwachsen"
        case .child: "Kind"
        case .guest: "Gast"
        }
    }
}

enum MemberAccent: String, CaseIterable, Codable, Sendable {
    case indigo
    case teal
    case orange
    case purple
}

struct FamilyMember: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var initials: String
    var role: MemberRole
    var accent: MemberAccent
}

enum PlanKind: String, CaseIterable, Codable, Sendable {
    case event
    case task
    case deadline
    case payment
    case preparation

    var displayName: String {
        switch self {
        case .event: "Termin"
        case .task: "Aufgabe"
        case .deadline: "Frist"
        case .payment: "Zahlung"
        case .preparation: "Vorbereitung"
        }
    }

    var systemImage: String {
        switch self {
        case .event: "calendar"
        case .task: "checkmark.circle"
        case .deadline: "clock.badge.exclamationmark"
        case .payment: "eurosign.circle"
        case .preparation: "backpack"
        }
    }
}

struct PlanItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var kind: PlanKind
    var title: String
    var startsAt: Date?
    var endsAt: Date?
    var dueAt: Date?
    var memberIDs: Set<UUID>
    var location: String?
    var note: String?
    var amountMinor: Int?
    var currency: String?
    var sourceID: UUID?
    var isCompleted: Bool
}

enum InboxStatus: String, CaseIterable, Codable, Sendable {
    case queued
    case uploading
    case processing
    case review
    case partial
    case done
    case failed

    var displayName: String {
        switch self {
        case .queued: "Wartet auf Upload"
        case .uploading: "Wird hochgeladen"
        case .processing: "Wird analysiert"
        case .review: "Prüfen"
        case .partial: "Teilweise übernommen"
        case .done: "Erledigt"
        case .failed: "Analyse fehlgeschlagen"
        }
    }
}

enum SourceKind: String, CaseIterable, Codable, Sendable {
    case image
    case pdf
    case text
    case voice

    var displayName: String {
        switch self {
        case .image: "Bild"
        case .pdf: "PDF"
        case .text: "Text"
        case .voice: "Sprache"
        }
    }

    var systemImage: String {
        switch self {
        case .image: "photo"
        case .pdf: "doc.richtext"
        case .text: "text.alignleft"
        case .voice: "waveform"
        }
    }
}

struct InboxSource: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var title: String
    var kind: SourceKind
    var createdAt: Date
    var status: InboxStatus
    var proposalCount: Int
    var sourceText: String?
    var errorMessage: String?
}

struct ActionProposal: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let sourceID: UUID
    var kind: PlanKind
    var title: String
    var startsAt: Date?
    var endsAt: Date?
    var dueAt: Date?
    var memberIDs: Set<UUID>
    var location: String?
    var note: String?
    var amountMinor: Int?
    var currency: String?
    var isIncluded: Bool
    var requiresMemberResolution: Bool

    var isReadyToConfirm: Bool {
        !requiresMemberResolution || !memberIDs.isEmpty
    }
}
