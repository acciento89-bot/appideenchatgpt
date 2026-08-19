import Foundation
import Supabase

extension SupabaseFamilyRepository {
    func completeSnapshot() async throws -> FamilySnapshot {
        var snapshot = try await currentSnapshot()
        let client = SupabaseEnvironment.client
        let userID = try await client.auth.session.user.id

        let membershipRows: [CompleteMembershipRow] = try await client
            .from("household_members")
            .select("id,household_id")
            .eq("user_id", value: userID)
            .eq("invite_status", value: "active")
            .execute()
            .value
        guard let membership = membershipRows.first else { return snapshot }

        let householdRows: [CompleteHouseholdRow] = try await client
            .from("households")
            .select("id,name,locale,timezone")
            .eq("id", value: membership.householdID)
            .execute()
            .value
        if let row = householdRows.first {
            snapshot.household = HouseholdSummary(id: row.id, name: row.name, locale: row.locale, timezone: row.timezone)
        }

        let reminderRows: [CompleteReminderRow] = try await client
            .from("reminders")
            .select("id,plan_item_id,target_member_id,trigger_at,delivery_state,kind")
            .execute()
            .value
        snapshot.reminders = reminderRows.compactMap { row in
            guard let trigger = CompleteDate.parse(row.triggerAt) else { return nil }
            return ReminderSnapshot(
                id: row.id,
                planItemID: row.planItemID,
                targetMemberID: row.targetMemberID,
                triggerAt: trigger,
                deliveryState: row.deliveryState,
                kind: row.kind
            )
        }

        let activityRows: [CompleteActivityRow] = try await client
            .from("activity_log")
            .select("id,actor_member_id,entity_type,entity_id,action,created_at")
            .eq("household_id", value: membership.householdID)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        snapshot.activity = activityRows.compactMap { row in
            guard let date = CompleteDate.parse(row.createdAt) else { return nil }
            return ActivityEntry(
                id: row.id,
                actorMemberID: row.actorMemberID,
                entityType: row.entityType,
                entityID: row.entityID,
                action: row.action,
                createdAt: date
            )
        }

        let entitlementRows: [CompleteEntitlementRow] = try await client
            .from("household_entitlements")
            .select("tier,product_id,expires_at")
            .eq("household_id", value: membership.householdID)
            .execute()
            .value
        if let row = entitlementRows.first {
            snapshot.entitlement = FamilyEntitlement(
                tier: FamilyEntitlement.Tier(rawValue: row.tier) ?? .free,
                productID: row.productID,
                expiresAt: CompleteDate.parse(row.expiresAt)
            )
        }

        snapshot.notificationPreferences = (try? await loadNotificationPreferences()) ?? .init()
        return snapshot
    }
}

private struct CompleteMembershipRow: Decodable {
    let id: UUID
    let householdID: UUID
    enum CodingKeys: String, CodingKey { case id; case householdID = "household_id" }
}

private struct CompleteHouseholdRow: Decodable {
    let id: UUID
    let name: String
    let locale: String
    let timezone: String
}

private struct CompleteReminderRow: Decodable {
    let id: UUID
    let planItemID: UUID
    let targetMemberID: UUID
    let triggerAt: String
    let deliveryState: String
    let kind: String
    enum CodingKeys: String, CodingKey {
        case id
        case planItemID = "plan_item_id"
        case targetMemberID = "target_member_id"
        case triggerAt = "trigger_at"
        case deliveryState = "delivery_state"
        case kind
    }
}

private struct CompleteActivityRow: Decodable {
    let id: UUID
    let actorMemberID: UUID?
    let entityType: String
    let entityID: UUID
    let action: String
    let createdAt: String
    enum CodingKeys: String, CodingKey {
        case id
        case actorMemberID = "actor_member_id"
        case entityType = "entity_type"
        case entityID = "entity_id"
        case action
        case createdAt = "created_at"
    }
}

private struct CompleteEntitlementRow: Decodable {
    let tier: String
    let productID: String?
    let expiresAt: String?
    enum CodingKeys: String, CodingKey {
        case tier
        case productID = "product_id"
        case expiresAt = "expires_at"
    }
}

private enum CompleteDate {
    static func parse(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = fractional.date(from: raw) { return value }
        return ISO8601DateFormatter().date(from: raw)
    }
}
