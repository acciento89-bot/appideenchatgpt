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
        case .guest: "Gast / Betreuung"
        }
    }
}

enum MemberAccent: String, CaseIterable, Codable, Sendable {
    case indigo
    case teal
    case orange
    case purple
}

struct HouseholdSummary: Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var locale: String
    var timezone: String
}

struct FamilyMember: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var initials: String
    var role: MemberRole
    var accent: MemberAccent
    var userID: UUID? = nil
    var inviteStatus: String = "active"
    var avatarPath: String? = nil
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
    var sourceProposalID: UUID? = nil
    var isCompleted: Bool
    var version: Int = 1

    var referenceDate: Date? { startsAt ?? dueAt }
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
    case share

    var displayName: String {
        switch self {
        case .image: "Bild"
        case .pdf: "PDF"
        case .text: "Text"
        case .voice: "Sprache"
        case .share: "Geteilt"
        }
    }

    var systemImage: String {
        switch self {
        case .image: "photo"
        case .pdf: "doc.richtext"
        case .text: "text.alignleft"
        case .voice: "waveform"
        case .share: "square.and.arrow.down"
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
    var storagePath: String? = nil
    var contentType: String? = nil
    var fileName: String? = nil
    var sizeBytes: Int? = nil
    var isArchived: Bool = false
    var clientRequestID: UUID? = nil
    var isLocalOnly: Bool = false
}

enum ProposalReviewStatus: String, CaseIterable, Codable, Sendable {
    case proposed
    case confirmed
    case rejected
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
    var unresolvedFields: [String: String] = [:]
    var reviewStatus: ProposalReviewStatus = .proposed
    var suggestedReminderAt: Date? = nil

    var isReadyToConfirm: Bool {
        unresolvedFields.isEmpty && (!requiresMemberResolution || !memberIDs.isEmpty)
    }

    var unresolvedDisplayNames: [String] {
        unresolvedFields.keys.sorted().map { field in
            switch field {
            case "member": "Person"
            case "time": "Uhrzeit"
            case "starts_at": "Datum und Uhrzeit"
            case "due_at": "Fälligkeit"
            default: field.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }
    }

    mutating func resolveUncertainty(_ field: String) {
        unresolvedFields.removeValue(forKey: field)
        if field == "member" {
            requiresMemberResolution = false
        }
    }
}

struct ReminderSnapshot: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var planItemID: UUID
    var targetMemberID: UUID
    var triggerAt: Date
    var deliveryState: String
    var kind: String
}

struct ActivityEntry: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var actorMemberID: UUID?
    var entityType: String
    var entityID: UUID
    var action: String
    var createdAt: Date

    var displayText: String {
        switch (entityType, action) {
        case ("plan_item", "created"): "Plan-Eintrag erstellt"
        case ("plan_item", "updated"): "Plan-Eintrag geändert"
        case ("plan_item", "completed"): "Plan-Eintrag erledigt"
        case ("plan_item", "reopened"): "Plan-Eintrag wieder geöffnet"
        case ("plan_item", "deleted"): "Plan-Eintrag gelöscht"
        case ("source_item", "created"): "Quelle hinzugefügt"
        case ("source_item", "archived"): "Quelle archiviert"
        case ("source_item", "restored"): "Quelle wiederhergestellt"
        case ("invite", "created"): "Einladung erstellt"
        case ("invite", "accepted"): "Einladung angenommen"
        case ("member", "insert"): "Familienmitglied hinzugefügt"
        case ("member", "update"): "Familienmitglied geändert"
        case ("member", "delete"): "Familienmitglied entfernt"
        default: "Familie aktualisiert"
        }
    }
}

struct FamilyEntitlement: Hashable, Codable, Sendable {
    enum Tier: String, Codable, Sendable { case free, pro }
    var tier: Tier
    var productID: String?
    var expiresAt: Date?

    static let free = FamilyEntitlement(tier: .free, productID: nil, expiresAt: nil)
}

enum FamilyProPolicy {
    static let monthlyID = "de.kamilunavo.family.familypro.monthly"
    static let annualID = "de.kamilunavo.family.familypro.annual"
    static let productIDs = [monthlyID, annualID]

    static func productRank(_ productID: String) -> Int {
        switch productID {
        case monthlyID: 0
        case annualID: 1
        default: 2
        }
    }

    static func isEntitled(
        productID: String,
        revocationDate: Date?,
        expirationDate: Date?,
        now: Date = .now
    ) -> Bool {
        guard productIDs.contains(productID), revocationDate == nil else { return false }
        guard let expirationDate else { return true }
        return expirationDate > now
    }
}

struct NotificationPreferences: Hashable, Codable, Sendable {
    var eventReminders = true
    var taskReminders = true
    var preparationReminders = true
    var assignmentUpdates = true
    var inboxReview = true
    var dailyDigest = true
}

struct HouseholdInvite: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var token: String
    var role: MemberRole
    var expiresAt: Date

    var url: URL? {
        URL(string: "de.kamilunavo.familyprototype://invite?token=\(token)")
    }
}

struct PlanItemDraft: Hashable, Codable, Sendable {
    var kind: PlanKind = .task
    var title = ""
    var startsAt: Date?
    var endsAt: Date?
    var dueAt: Date?
    var memberIDs: Set<UUID> = []
    var location: String?
    var note: String?
    var amountMinor: Int?
    var currency: String? = "EUR"

    init() {}

    init(item: PlanItem) {
        kind = item.kind
        title = item.title
        startsAt = item.startsAt
        endsAt = item.endsAt
        dueAt = item.dueAt
        memberIDs = item.memberIDs
        location = item.location
        note = item.note
        amountMinor = item.amountMinor
        currency = item.currency
    }
}

struct SourceIngestionRequest: Sendable {
    var kind: SourceKind
    var title: String
    var text: String?
    var fileData: Data?
    var fileName: String?
    var contentType: String?
    var extractedText: String?
    var clientRequestID: UUID? = nil
    var targetHouseholdID: UUID? = nil
}

struct SourceDocumentData: Sendable {
    var data: Data
    var fileName: String
    var contentType: String
}

struct ConnectivityResumePolicy: Sendable {
    private var previousAvailability: Bool?

    mutating func shouldResumeSync(isNetworkAvailable: Bool) -> Bool {
        defer { previousAvailability = isNetworkAvailable }
        guard let previousAvailability else { return false }
        return !previousAvailability && isNetworkAvailable
    }
}
