import Foundation
import Supabase

extension SupabaseFamilyRepository {
    func ingestSource(_ request: SourceIngestionRequest) async throws -> FamilySnapshot {
        let client = SupabaseEnvironment.client
        let created: [V1CreatedSourceRow] = try await client
            .rpc(
                "create_source_item",
                params: V1CreateSourceParams(
                    sourceType: request.kind.rawValue,
                    title: request.title,
                    originalText: request.text
                )
            )
            .execute()
            .value

        guard let source = created.first else { throw FamilyRepositoryError.invalidResponse }

        if let data = request.fileData {
            let fileName = V1Sanitizer.fileName(request.fileName ?? "Quelle")
            let path = "households/\(source.householdID.uuidString.lowercased())/sources/\(source.sourceItemID.uuidString.lowercased())/\(fileName)"
            let contentType = request.contentType ?? "application/octet-stream"

            try await client.storage
                .from("family-sources")
                .upload(
                    path: path,
                    file: data,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: contentType,
                        upsert: false
                    )
                )

            try await client
                .rpc(
                    "finalize_source_upload",
                    params: V1FinalizeUploadParams(
                        sourceItemID: source.sourceItemID,
                        storagePath: path,
                        fileName: fileName,
                        contentType: contentType,
                        sizeBytes: data.count,
                        extractedText: request.extractedText
                    )
                )
                .execute()
        }

        let _: V1ProcessResult = try await client.functions.invoke(
            "process-family-source",
            options: FunctionInvokeOptions(
                body: V1ProcessSourceBody(
                    sourceItemID: source.sourceItemID,
                    textOverride: request.text ?? request.extractedText
                )
            )
        )

        return try await currentSnapshot()
    }

    func createPlanItem(_ draft: PlanItemDraft) async throws -> FamilySnapshot {
        let client = SupabaseEnvironment.client
        let membership = try await V1HostedLookup.currentMembership(client: client)
        let row: V1IDRow = try await client
            .from("plan_items")
            .insert(
                V1PlanInsert(
                    householdID: membership.householdID,
                    kind: draft.kind.rawValue,
                    title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    startsAt: V1Date.encode(draft.startsAt),
                    endsAt: V1Date.encode(draft.endsAt),
                    dueAt: V1Date.encode(draft.dueAt),
                    location: draft.location,
                    notes: draft.note,
                    amountMinor: draft.amountMinor,
                    currency: draft.amountMinor == nil ? nil : (draft.currency ?? "EUR"),
                    createdByMemberID: membership.id
                )
            )
            .select("id")
            .single()
            .execute()
            .value

        try await V1HostedLookup.replaceAssignees(
            client: client,
            planItemID: row.id,
            memberIDs: draft.memberIDs
        )
        return try await currentSnapshot()
    }

    func updatePlanItem(
        _ itemID: UUID,
        expectedVersion: Int,
        draft: PlanItemDraft
    ) async throws -> FamilySnapshot {
        let client = SupabaseEnvironment.client
        let rows: [V1IDRow] = try await client
            .from("plan_items")
            .update(
                V1PlanUpdate(
                    kind: draft.kind.rawValue,
                    title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    startsAt: V1Date.encode(draft.startsAt),
                    endsAt: V1Date.encode(draft.endsAt),
                    dueAt: V1Date.encode(draft.dueAt),
                    location: draft.location,
                    notes: draft.note,
                    amountMinor: draft.amountMinor,
                    currency: draft.amountMinor == nil ? nil : (draft.currency ?? "EUR")
                )
            )
            .eq("id", value: itemID)
            .eq("version", value: expectedVersion)
            .select("id")
            .execute()
            .value

        guard !rows.isEmpty else { throw FamilyRepositoryError.conflict }
        try await V1HostedLookup.replaceAssignees(client: client, planItemID: itemID, memberIDs: draft.memberIDs)
        return try await currentSnapshot()
    }

    func deletePlanItem(_ itemID: UUID) async throws -> FamilySnapshot {
        try await SupabaseEnvironment.client
            .from("plan_items")
            .delete()
            .eq("id", value: itemID)
            .execute()
        return try await currentSnapshot()
    }

    func updateMember(_ member: FamilyMember) async throws -> FamilySnapshot {
        try await SupabaseEnvironment.client
            .from("household_members")
            .update(
                V1MemberUpdate(
                    displayName: member.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    role: member.role.rawValue,
                    accentKey: member.accent.rawValue
                )
            )
            .eq("id", value: member.id)
            .execute()
        return try await currentSnapshot()
    }

    func createInvite(role: MemberRole) async throws -> HouseholdInvite {
        guard role == .adult || role == .guest else { throw FamilyRepositoryError.invalidResponse }
        let membership = try await V1HostedLookup.currentMembership(client: SupabaseEnvironment.client)
        let rows: [V1InviteRow] = try await SupabaseEnvironment.client
            .rpc(
                "create_household_invite",
                params: V1CreateInviteParams(
                    householdID: membership.householdID,
                    role: role.rawValue,
                    expiresHours: 168
                )
            )
            .execute()
            .value
        guard let row = rows.first,
              let expiresAt = V1Date.parse(row.expiresAt) else {
            throw FamilyRepositoryError.invalidResponse
        }
        return HouseholdInvite(id: row.inviteID, token: row.inviteToken, role: role, expiresAt: expiresAt)
    }

    func acceptInvite(token: String, displayName: String) async throws -> FamilySnapshot {
        let _: [V1AcceptedInviteRow] = try await SupabaseEnvironment.client
            .rpc(
                "accept_household_invite",
                params: V1AcceptInviteParams(token: token, displayName: displayName)
            )
            .execute()
            .value
        return try await currentSnapshot()
    }

    func archiveSource(_ sourceID: UUID, archived: Bool) async throws -> FamilySnapshot {
        try await SupabaseEnvironment.client
            .rpc(
                "set_source_archived",
                params: V1ArchiveSourceParams(sourceItemID: sourceID, archived: archived)
            )
            .execute()
        return try await currentSnapshot()
    }

    func retrySource(_ sourceID: UUID, extractedText: String?) async throws -> FamilySnapshot {
        try await SupabaseEnvironment.client
            .rpc(
                "retry_source_processing",
                params: V1RetrySourceParams(sourceItemID: sourceID, extractedText: extractedText)
            )
            .execute()

        let _: V1ProcessResult = try await SupabaseEnvironment.client.functions.invoke(
            "process-family-source",
            options: FunctionInvokeOptions(
                body: V1ProcessSourceBody(sourceItemID: sourceID, textOverride: extractedText)
            )
        )
        return try await currentSnapshot()
    }

    func sourceDocument(_ sourceID: UUID) async throws -> SourceDocumentData? {
        let rows: [V1SourceDocumentRow] = try await SupabaseEnvironment.client
            .from("source_items")
            .select("storage_path,file_name,content_type")
            .eq("id", value: sourceID)
            .execute()
            .value
        guard let row = rows.first, let path = row.storagePath else { return nil }
        let data = try await SupabaseEnvironment.client.storage
            .from("family-sources")
            .download(path: path)
        return SourceDocumentData(
            data: data,
            fileName: row.fileName ?? "Quelle",
            contentType: row.contentType ?? "application/octet-stream"
        )
    }

    func loadNotificationPreferences() async throws -> NotificationPreferences {
        let client = SupabaseEnvironment.client
        let membership = try await V1HostedLookup.currentMembership(client: client)
        let userID = try await client.auth.session.user.id
        let rows: [V1NotificationRow] = try await client
            .from("notification_preferences")
            .select()
            .eq("household_id", value: membership.householdID)
            .eq("user_id", value: userID)
            .execute()
            .value
        guard let row = rows.first else { return .init() }
        return row.preferences
    }

    func saveNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        let client = SupabaseEnvironment.client
        let membership = try await V1HostedLookup.currentMembership(client: client)
        let userID = try await client.auth.session.user.id
        try await client
            .from("notification_preferences")
            .upsert(V1NotificationUpsert(householdID: membership.householdID, userID: userID, preferences: preferences))
            .execute()
    }

    func deleteHousehold() async throws {
        let membership = try await V1HostedLookup.currentMembership(client: SupabaseEnvironment.client)
        guard membership.role == MemberRole.owner.rawValue else { throw FamilyRepositoryError.unauthenticated }
        try await SupabaseEnvironment.client
            .from("households")
            .delete()
            .eq("id", value: membership.householdID)
            .execute()
    }
}

private enum V1HostedLookup {
    static func currentMembership(client: SupabaseClient) async throws -> V1MembershipRow {
        let userID = try await client.auth.session.user.id
        let rows: [V1MembershipRow] = try await client
            .from("household_members")
            .select("id,household_id,role")
            .eq("user_id", value: userID)
            .eq("invite_status", value: "active")
            .execute()
            .value
        guard let row = rows.first else { throw FamilyRepositoryError.householdUnavailable }
        return row
    }

    static func replaceAssignees(
        client: SupabaseClient,
        planItemID: UUID,
        memberIDs: Set<UUID>
    ) async throws {
        try await client
            .from("plan_item_assignees")
            .delete()
            .eq("plan_item_id", value: planItemID)
            .execute()
        guard !memberIDs.isEmpty else { return }
        try await client
            .from("plan_item_assignees")
            .insert(memberIDs.map { V1PlanAssigneeInsert(planItemID: planItemID, memberID: $0) })
            .execute()
    }
}

private enum V1Sanitizer {
    static func fileName(_ value: String) -> String {
        let clean = value
            .replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-"))
        return String((clean.isEmpty ? "Quelle" : clean).prefix(120))
    }
}

private enum V1Date {
    static func encode(_ value: Date?) -> String? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: value)
    }

    static func parse(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }
}

private struct V1CreateSourceParams: Encodable, Sendable {
    let sourceType: String
    let title: String
    let originalText: String?
    enum CodingKeys: String, CodingKey {
        case sourceType = "p_source_type"
        case title = "p_title"
        case originalText = "p_original_text"
    }
}

private struct V1CreatedSourceRow: Decodable, Sendable {
    let sourceItemID: UUID
    let householdID: UUID
    let memberID: UUID
    enum CodingKeys: String, CodingKey {
        case sourceItemID = "source_item_id"
        case householdID = "household_id"
        case memberID = "member_id"
    }
}

private struct V1FinalizeUploadParams: Encodable, Sendable {
    let sourceItemID: UUID
    let storagePath: String
    let fileName: String
    let contentType: String
    let sizeBytes: Int
    let extractedText: String?
    enum CodingKeys: String, CodingKey {
        case sourceItemID = "p_source_item_id"
        case storagePath = "p_storage_path"
        case fileName = "p_file_name"
        case contentType = "p_content_type"
        case sizeBytes = "p_size_bytes"
        case extractedText = "p_extracted_text"
    }
}

private struct V1ProcessSourceBody: Encodable, Sendable {
    let sourceItemID: UUID
    let textOverride: String?
    enum CodingKeys: String, CodingKey {
        case sourceItemID = "source_item_id"
        case textOverride = "text_override"
    }
}

private struct V1ProcessResult: Decodable, Sendable {
    let sourceItemID: UUID
    let proposalCount: Int
    let provider: String
    let model: String
    enum CodingKeys: String, CodingKey {
        case sourceItemID = "source_item_id"
        case proposalCount = "proposal_count"
        case provider
        case model
    }
}

private struct V1MembershipRow: Decodable, Sendable {
    let id: UUID
    let householdID: UUID
    let role: String
    enum CodingKeys: String, CodingKey {
        case id
        case householdID = "household_id"
        case role
    }
}

private struct V1PlanInsert: Encodable, Sendable {
    let householdID: UUID
    let kind: String
    let title: String
    let startsAt: String?
    let endsAt: String?
    let dueAt: String?
    let location: String?
    let notes: String?
    let amountMinor: Int?
    let currency: String?
    let createdByMemberID: UUID
    enum CodingKeys: String, CodingKey {
        case householdID = "household_id"
        case kind, title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case dueAt = "due_at"
        case location, notes
        case amountMinor = "amount_minor"
        case currency
        case createdByMemberID = "created_by_member_id"
    }
}

private struct V1PlanUpdate: Encodable, Sendable {
    let kind: String
    let title: String
    let startsAt: String?
    let endsAt: String?
    let dueAt: String?
    let location: String?
    let notes: String?
    let amountMinor: Int?
    let currency: String?
    enum CodingKeys: String, CodingKey {
        case kind, title
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case dueAt = "due_at"
        case location, notes
        case amountMinor = "amount_minor"
        case currency
    }
}

private struct V1IDRow: Decodable, Sendable { let id: UUID }

private struct V1PlanAssigneeInsert: Encodable, Sendable {
    let planItemID: UUID
    let memberID: UUID
    enum CodingKeys: String, CodingKey {
        case planItemID = "plan_item_id"
        case memberID = "member_id"
    }
}

private struct V1MemberUpdate: Encodable, Sendable {
    let displayName: String
    let role: String
    let accentKey: String
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case role
        case accentKey = "accent_key"
    }
}

private struct V1CreateInviteParams: Encodable, Sendable {
    let householdID: UUID
    let role: String
    let expiresHours: Int
    enum CodingKeys: String, CodingKey {
        case householdID = "p_household_id"
        case role = "p_role"
        case expiresHours = "p_expires_hours"
    }
}

private struct V1InviteRow: Decodable, Sendable {
    let inviteID: UUID
    let inviteToken: String
    let expiresAt: String
    enum CodingKeys: String, CodingKey {
        case inviteID = "invite_id"
        case inviteToken = "invite_token"
        case expiresAt = "expires_at"
    }
}

private struct V1AcceptInviteParams: Encodable, Sendable {
    let token: String
    let displayName: String
    enum CodingKeys: String, CodingKey {
        case token = "p_token"
        case displayName = "p_display_name"
    }
}

private struct V1AcceptedInviteRow: Decodable, Sendable {
    let householdID: UUID
    let memberID: UUID
    let role: String
    enum CodingKeys: String, CodingKey {
        case householdID = "household_id"
        case memberID = "member_id"
        case role
    }
}

private struct V1ArchiveSourceParams: Encodable, Sendable {
    let sourceItemID: UUID
    let archived: Bool
    enum CodingKeys: String, CodingKey {
        case sourceItemID = "p_source_item_id"
        case archived = "p_archived"
    }
}

private struct V1RetrySourceParams: Encodable, Sendable {
    let sourceItemID: UUID
    let extractedText: String?
    enum CodingKeys: String, CodingKey {
        case sourceItemID = "p_source_item_id"
        case extractedText = "p_extracted_text"
    }
}

private struct V1SourceDocumentRow: Decodable, Sendable {
    let storagePath: String?
    let fileName: String?
    let contentType: String?
    enum CodingKeys: String, CodingKey {
        case storagePath = "storage_path"
        case fileName = "file_name"
        case contentType = "content_type"
    }
}

private struct V1NotificationRow: Decodable, Sendable {
    let eventReminders: Bool
    let taskReminders: Bool
    let preparationReminders: Bool
    let assignmentUpdates: Bool
    let inboxReview: Bool
    let dailyDigest: Bool
    enum CodingKeys: String, CodingKey {
        case eventReminders = "event_reminders"
        case taskReminders = "task_reminders"
        case preparationReminders = "preparation_reminders"
        case assignmentUpdates = "assignment_updates"
        case inboxReview = "inbox_review"
        case dailyDigest = "daily_digest"
    }
    var preferences: NotificationPreferences {
        .init(
            eventReminders: eventReminders,
            taskReminders: taskReminders,
            preparationReminders: preparationReminders,
            assignmentUpdates: assignmentUpdates,
            inboxReview: inboxReview,
            dailyDigest: dailyDigest
        )
    }
}

private struct V1NotificationUpsert: Encodable, Sendable {
    let householdID: UUID
    let userID: UUID
    let eventReminders: Bool
    let taskReminders: Bool
    let preparationReminders: Bool
    let assignmentUpdates: Bool
    let inboxReview: Bool
    let dailyDigest: Bool

    init(householdID: UUID, userID: UUID, preferences: NotificationPreferences) {
        self.householdID = householdID
        self.userID = userID
        eventReminders = preferences.eventReminders
        taskReminders = preferences.taskReminders
        preparationReminders = preferences.preparationReminders
        assignmentUpdates = preferences.assignmentUpdates
        inboxReview = preferences.inboxReview
        dailyDigest = preferences.dailyDigest
    }

    enum CodingKeys: String, CodingKey {
        case householdID = "household_id"
        case userID = "user_id"
        case eventReminders = "event_reminders"
        case taskReminders = "task_reminders"
        case preparationReminders = "preparation_reminders"
        case assignmentUpdates = "assignment_updates"
        case inboxReview = "inbox_review"
        case dailyDigest = "daily_digest"
    }
}
