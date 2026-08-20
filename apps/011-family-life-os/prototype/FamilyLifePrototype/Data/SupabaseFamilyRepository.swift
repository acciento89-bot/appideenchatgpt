import Foundation
import Supabase

actor SupabaseFamilyRepository: FamilyRepository {
    private let client: SupabaseClient
    private let defaultHouseholdName: String
    private let defaultDisplayName: String

    init(
        client: SupabaseClient = SupabaseEnvironment.client,
        defaultHouseholdName: String = "Meine Familie",
        defaultDisplayName: String = "Ich"
    ) {
        self.client = client
        self.defaultHouseholdName = defaultHouseholdName
        self.defaultDisplayName = defaultDisplayName
    }

    func currentSnapshot() async throws -> FamilySnapshot {
        let bootstrap = try await ensureHousehold()

        let memberRows: [HouseholdMemberRow] = try await client
            .from("household_members")
            .select()
            .eq("household_id", value: bootstrap.householdID)
            .execute()
            .value

        let sourceRows: [SourceItemRow] = try await client
            .from("source_items")
            .select()
            .eq("household_id", value: bootstrap.householdID)
            .execute()
            .value

        let sourceIDs = Set(sourceRows.map(\.id))

        let allProposalRows: [ActionProposalRow] = try await client
            .from("action_proposals")
            .select()
            .execute()
            .value
        let proposalRows = allProposalRows.filter { sourceIDs.contains($0.sourceItemID) }
        let proposalIDs = Set(proposalRows.map(\.id))

        let allProposalAssignees: [ProposalAssigneeRow] = try await client
            .from("action_proposal_assignees")
            .select()
            .execute()
            .value
        let proposalAssignees = allProposalAssignees.filter { proposalIDs.contains($0.proposalID) }

        let planRows: [PlanItemRow] = try await client
            .from("plan_items")
            .select()
            .eq("household_id", value: bootstrap.householdID)
            .execute()
            .value
        let planIDs = Set(planRows.map(\.id))

        let allPlanAssignees: [PlanAssigneeRow] = try await client
            .from("plan_item_assignees")
            .select()
            .execute()
            .value
        let planAssignees = allPlanAssignees.filter { planIDs.contains($0.planItemID) }

        let proposalMemberIDs = Dictionary(grouping: proposalAssignees, by: \.proposalID)
            .mapValues { Set($0.map(\.memberID)) }
        let planMemberIDs = Dictionary(grouping: planAssignees, by: \.planItemID)
            .mapValues { Set($0.map(\.memberID)) }
        let proposalCountBySource = Dictionary(grouping: proposalRows, by: \.sourceItemID)
            .mapValues(\.count)

        let members = memberRows
            .map(Self.mapMember)
            .sorted { lhs, rhs in
                Self.roleOrder(lhs.role) == Self.roleOrder(rhs.role)
                    ? lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    : Self.roleOrder(lhs.role) < Self.roleOrder(rhs.role)
            }

        let proposals = proposalRows
            .map { row in
                ActionProposal(
                    id: row.id,
                    sourceID: row.sourceItemID,
                    kind: PlanKind(rawValue: row.kind) ?? .task,
                    title: row.title,
                    startsAt: Self.parseDate(row.startsAt),
                    endsAt: Self.parseDate(row.endsAt),
                    dueAt: Self.parseDate(row.dueAt),
                    memberIDs: proposalMemberIDs[row.id] ?? [],
                    location: row.location,
                    note: row.notes,
                    amountMinor: row.amountMinor,
                    currency: row.currency,
                    isIncluded: row.isIncluded,
                    requiresMemberResolution: row.unresolvedFields["member"] != nil,
                    unresolvedFields: row.unresolvedFields,
                    reviewStatus: ProposalReviewStatus(rawValue: row.reviewStatus) ?? .proposed
                )
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        let planItems = planRows
            .map { row in
                PlanItem(
                    id: row.id,
                    kind: PlanKind(rawValue: row.kind) ?? .task,
                    title: row.title,
                    startsAt: Self.parseDate(row.startsAt),
                    endsAt: Self.parseDate(row.endsAt),
                    dueAt: Self.parseDate(row.dueAt),
                    memberIDs: planMemberIDs[row.id] ?? [],
                    location: row.location,
                    note: row.notes,
                    amountMinor: row.amountMinor,
                    currency: row.currency,
                    sourceID: row.sourceItemID,
                    sourceProposalID: row.sourceProposalID,
                    isCompleted: row.status == "completed"
                )
            }
            .sorted { lhs, rhs in
                (lhs.startsAt ?? lhs.dueAt ?? .distantFuture) < (rhs.startsAt ?? rhs.dueAt ?? .distantFuture)
            }

        let inboxItems = sourceRows
            .map { row in
                InboxSource(
                    id: row.id,
                    title: row.displayTitle,
                    kind: Self.sourceKind(row.sourceType),
                    createdAt: Self.parseDate(row.createdAt) ?? .now,
                    status: InboxStatus(rawValue: row.processingStatus) ?? .processing,
                    proposalCount: proposalCountBySource[row.id] ?? 0,
                    sourceText: row.originalText,
                    errorMessage: row.processingErrorCode
                )
            }
            .sorted { $0.createdAt > $1.createdAt }

        return FamilySnapshot(
            members: members,
            planItems: planItems,
            inboxItems: inboxItems,
            proposals: proposals
        )
    }

    func ingestText(_ request: TextIngestionRequest) async throws -> FamilySnapshot {
        _ = try await ensureHousehold()

        let params = IngestTextParams(
            title: request.title,
            text: request.text
        )
        let _: UUID = try await client
            .rpc("ingest_text_fixture", params: params)
            .execute()
            .value

        return try await currentSnapshot()
    }

    func confirmReviewedProposals(
        sourceID: UUID,
        proposals: [ActionProposal]
    ) async throws -> FamilySnapshot {
        guard proposals.allSatisfy({ $0.sourceID == sourceID }) else {
            throw FamilyRepositoryError.invalidProposalSource
        }

        let included = proposals.filter { $0.isIncluded && $0.reviewStatus == .proposed }
        guard included.allSatisfy(\.isReadyToConfirm) else {
            throw FamilyRepositoryError.proposalsNotReady
        }

        for proposal in proposals where proposal.reviewStatus == .proposed {
            var unresolvedFields = proposal.unresolvedFields
            if proposal.requiresMemberResolution && proposal.memberIDs.isEmpty {
                unresolvedFields["member"] = "required"
            } else {
                unresolvedFields.removeValue(forKey: "member")
            }

            try await client
                .from("action_proposals")
                .update(
                    ProposalUpdate(
                        kind: proposal.kind.rawValue,
                        title: proposal.title,
                        startsAt: Self.encodeDate(proposal.startsAt),
                        endsAt: Self.encodeDate(proposal.endsAt),
                        dueAt: Self.encodeDate(proposal.dueAt),
                        location: proposal.location,
                        notes: proposal.note,
                        amountMinor: proposal.amountMinor,
                        currency: proposal.currency,
                        unresolvedFields: unresolvedFields,
                        isIncluded: proposal.isIncluded
                    )
                )
                .eq("id", value: proposal.id)
                .eq("source_item_id", value: sourceID)
                .execute()

            try await client
                .from("action_proposal_assignees")
                .delete()
                .eq("proposal_id", value: proposal.id)
                .execute()

            if !proposal.memberIDs.isEmpty {
                let assignees = proposal.memberIDs.map {
                    ProposalAssigneeInsert(proposalID: proposal.id, memberID: $0)
                }
                try await client
                    .from("action_proposal_assignees")
                    .insert(assignees)
                    .execute()
            }
        }

        if !included.isEmpty {
            let params = ConfirmParams(
                sourceItemID: sourceID,
                proposalIDs: included.map(\.id)
            )
            let _: [ConfirmedRow] = try await client
                .rpc("confirm_action_proposals", params: params)
                .execute()
                .value
        }

        return try await currentSnapshot()
    }

    func setPlanItemCompleted(
        _ itemID: UUID,
        isCompleted: Bool
    ) async throws -> FamilySnapshot {
        let payload: [String: String?] = [
            "status": isCompleted ? "completed" : "open",
            "completed_at": isCompleted ? Self.encodeDate(.now) : nil
        ]

        try await client
            .from("plan_items")
            .update(payload)
            .eq("id", value: itemID)
            .execute()

        return try await currentSnapshot()
    }

    func addChild(named name: String) async throws -> FamilySnapshot {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return try await currentSnapshot() }

        let bootstrap = try await ensureHousehold()
        let existing = try await currentSnapshot().members
        let accentPool: [MemberAccent] = [.orange, .purple, .teal, .indigo]
        let childCount = existing.filter { $0.role == .child }.count
        let accent = accentPool[childCount % accentPool.count]

        try await client
            .from("household_members")
            .insert(
                HouseholdMemberInsert(
                    householdID: bootstrap.householdID,
                    displayName: cleanName,
                    role: MemberRole.child.rawValue,
                    accentKey: accent.rawValue,
                    inviteStatus: "active"
                )
            )
            .execute()

        return try await currentSnapshot()
    }

    private func ensureHousehold() async throws -> BootstrapRow {
        do {
            let rows: [BootstrapRow] = try await client
                .rpc(
                    "bootstrap_household",
                    params: BootstrapParams(
                        householdName: defaultHouseholdName,
                        displayName: defaultDisplayName
                    )
                )
                .execute()
                .value

            guard let row = rows.first else {
                throw FamilyRepositoryError.householdUnavailable
            }
            return row
        } catch {
            if String(describing: error).localizedCaseInsensitiveContains("jwt") ||
                String(describing: error).localizedCaseInsensitiveContains("auth") {
                throw FamilyRepositoryError.unauthenticated
            }
            throw error
        }
    }

    private static func mapMember(_ row: HouseholdMemberRow) -> FamilyMember {
        let name = row.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()

        return FamilyMember(
            id: row.id,
            name: name,
            initials: initials.isEmpty ? "?" : initials,
            role: MemberRole(rawValue: row.role) ?? .guest,
            accent: MemberAccent(rawValue: row.accentKey) ?? .indigo
        )
    }

    private static func roleOrder(_ role: MemberRole) -> Int {
        switch role {
        case .owner: 0
        case .adult: 1
        case .child: 2
        case .guest: 3
        }
    }

    private static func sourceKind(_ raw: String) -> SourceKind {
        switch raw {
        case "image": .image
        case "pdf": .pdf
        case "voice": .voice
        default: .text
        }
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: raw)
    }

    private static func encodeDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

private struct BootstrapParams: Encodable, Sendable {
    let householdName: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case householdName = "p_household_name"
        case displayName = "p_display_name"
    }
}

private struct BootstrapRow: Decodable, Sendable {
    let householdID: UUID
    let memberID: UUID

    enum CodingKeys: String, CodingKey {
        case householdID = "household_id"
        case memberID = "member_id"
    }
}

private struct IngestTextParams: Encodable, Sendable {
    let title: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case title = "p_title"
        case text = "p_text"
    }
}

private struct ConfirmParams: Encodable, Sendable {
    let sourceItemID: UUID
    let proposalIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case sourceItemID = "p_source_item_id"
        case proposalIDs = "p_proposal_ids"
    }
}

private struct ConfirmedRow: Decodable, Sendable {
    let proposalID: UUID
    let planItemID: UUID

    enum CodingKeys: String, CodingKey {
        case proposalID = "proposal_id"
        case planItemID = "plan_item_id"
    }
}

private struct HouseholdMemberRow: Decodable, Sendable {
    let id: UUID
    let householdID: UUID
    let displayName: String
    let role: String
    let accentKey: String

    enum CodingKeys: String, CodingKey {
        case id
        case householdID = "household_id"
        case displayName = "display_name"
        case role
        case accentKey = "accent_key"
    }
}

private struct HouseholdMemberInsert: Encodable, Sendable {
    let householdID: UUID
    let displayName: String
    let role: String
    let accentKey: String
    let inviteStatus: String

    enum CodingKeys: String, CodingKey {
        case householdID = "household_id"
        case displayName = "display_name"
        case role
        case accentKey = "accent_key"
        case inviteStatus = "invite_status"
    }
}

private struct SourceItemRow: Decodable, Sendable {
    let id: UUID
    let sourceType: String
    let displayTitle: String
    let originalText: String?
    let processingStatus: String
    let processingErrorCode: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case sourceType = "source_type"
        case displayTitle = "display_title"
        case originalText = "original_text"
        case processingStatus = "processing_status"
        case processingErrorCode = "processing_error_code"
        case createdAt = "created_at"
    }
}

private struct ActionProposalRow: Decodable, Sendable {
    let id: UUID
    let sourceItemID: UUID
    let kind: String
    let title: String
    let startsAt: String?
    let endsAt: String?
    let dueAt: String?
    let location: String?
    let notes: String?
    let amountMinor: Int?
    let currency: String?
    let unresolvedFields: [String: String]
    let isIncluded: Bool
    let reviewStatus: String

    enum CodingKeys: String, CodingKey {
        case id
        case sourceItemID = "source_item_id"
        case kind
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case dueAt = "due_at"
        case location
        case notes
        case amountMinor = "amount_minor"
        case currency
        case unresolvedFields = "unresolved_fields"
        case isIncluded = "is_included"
        case reviewStatus = "review_status"
    }
}

private struct ProposalAssigneeRow: Decodable, Sendable {
    let proposalID: UUID
    let memberID: UUID

    enum CodingKeys: String, CodingKey {
        case proposalID = "proposal_id"
        case memberID = "member_id"
    }
}

private struct ProposalAssigneeInsert: Encodable, Sendable {
    let proposalID: UUID
    let memberID: UUID

    enum CodingKeys: String, CodingKey {
        case proposalID = "proposal_id"
        case memberID = "member_id"
    }
}

private struct ProposalUpdate: Encodable, Sendable {
    let kind: String
    let title: String
    let startsAt: String?
    let endsAt: String?
    let dueAt: String?
    let location: String?
    let notes: String?
    let amountMinor: Int?
    let currency: String?
    let unresolvedFields: [String: String]
    let isIncluded: Bool

    enum CodingKeys: String, CodingKey {
        case kind
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case dueAt = "due_at"
        case location
        case notes
        case amountMinor = "amount_minor"
        case currency
        case unresolvedFields = "unresolved_fields"
        case isIncluded = "is_included"
    }
}

private struct PlanItemRow: Decodable, Sendable {
    let id: UUID
    let kind: String
    let title: String
    let startsAt: String?
    let endsAt: String?
    let dueAt: String?
    let location: String?
    let notes: String?
    let amountMinor: Int?
    let currency: String?
    let status: String
    let sourceItemID: UUID?
    let sourceProposalID: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case dueAt = "due_at"
        case location
        case notes
        case amountMinor = "amount_minor"
        case currency
        case status
        case sourceItemID = "source_item_id"
        case sourceProposalID = "source_proposal_id"
    }
}

private struct PlanAssigneeRow: Decodable, Sendable {
    let planItemID: UUID
    let memberID: UUID

    enum CodingKeys: String, CodingKey {
        case planItemID = "plan_item_id"
        case memberID = "member_id"
    }
}
