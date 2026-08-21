import { createClient } from "@supabase/supabase-js";
import { anonymizedMemberPatch, parseDeletionRequest } from "./policy.mjs";

const headers = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store"
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const authorization = req.headers.get("Authorization") ?? "";
    if (!authorization.startsWith("Bearer ")) {
      return json({ error: "authentication_required" }, 401);
    }

    const request = parseDeletionRequest(await req.json().catch(() => ({})));
    if (!request.scope) return json({ error: "invalid_scope" }, 400);
    if (!request.confirmed) return json({ error: "explicit_confirmation_required" }, 400);

    const url = env("SUPABASE_URL");
    const anon = env("SUPABASE_ANON_KEY");
    const service = env("SUPABASE_SERVICE_ROLE_KEY");
    const user = createClient(url, anon, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false }
    });
    const admin = createClient(url, service, { auth: { persistSession: false } });

    const { data: authData, error: authError } = await user.auth.getUser();
    if (authError || !authData.user) return json({ error: "invalid_session" }, 401);
    const userID = authData.user.id;

    if (request.scope === "household") {
      if (!request.householdID) return json({ error: "household_id_required" }, 400);

      const { data: membership, error: membershipError } = await user
        .from("household_members")
        .select("id,household_id,role")
        .eq("household_id", request.householdID)
        .eq("user_id", userID)
        .eq("invite_status", "active")
        .maybeSingle();

      if (membershipError) throw new Error("membership_lookup_failed");
      if (!membership || membership.role !== "owner") {
        return json({ error: "owner_required" }, 403);
      }

      await deleteHouseholdData(admin, request.householdID);
      return json({ deleted: "household", household_id: request.householdID });
    }

    const { data: memberships, error: membershipError } = await admin
      .from("household_members")
      .select("id,household_id,role")
      .eq("user_id", userID);
    if (membershipError) throw new Error("membership_lookup_failed");

    const { data: createdHouseholds, error: createdHouseholdError } = await admin
      .from("households")
      .select("id")
      .eq("created_by", userID);
    if (createdHouseholdError) throw new Error("created_household_lookup_failed");

    const ownedHouseholdIDs = new Set<string>((createdHouseholds ?? []).map((row: any) => row.id));
    for (const membership of memberships ?? []) {
      if (membership.role === "owner") ownedHouseholdIDs.add(membership.household_id);
    }

    for (const householdID of ownedHouseholdIDs) {
      await deleteHouseholdData(admin, householdID);
    }

    const remainingMembershipIDs = (memberships ?? [])
      .filter((membership: any) => !ownedHouseholdIDs.has(membership.household_id))
      .map((membership: any) => membership.id);

    if (remainingMembershipIDs.length) {
      const { error } = await admin
        .from("household_members")
        .update(anonymizedMemberPatch())
        .in("id", remainingMembershipIDs);
      if (error) throw new Error("membership_anonymization_failed");
    }

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(userID);
    if (deleteUserError) throw new Error("auth_user_delete_failed");

    return json({
      deleted: "account",
      deleted_households: ownedHouseholdIDs.size,
      anonymized_memberships: remainingMembershipIDs.length
    });
  } catch (error) {
    console.error("delete-family-data", safe(error));
    return json({ error: safe(error) }, 500);
  }
});

async function deleteHouseholdData(admin: any, householdID: string) {
  await removeHouseholdStorage(admin, householdID);
  const { error } = await admin.from("households").delete().eq("id", householdID);
  if (error) throw new Error("household_delete_failed");
}

async function removeHouseholdStorage(admin: any, householdID: string) {
  const bucket = admin.storage.from("family-sources");
  const paths = new Set<string>();

  for (const path of await listStoragePaths(bucket, `households/${householdID}`)) {
    paths.add(path);
  }

  const { data: sources, error: sourceError } = await admin
    .from("source_items")
    .select("storage_path")
    .eq("household_id", householdID)
    .not("storage_path", "is", null);
  if (sourceError) throw new Error("source_storage_lookup_failed");
  for (const row of sources ?? []) {
    if (row.storage_path) paths.add(row.storage_path);
  }

  const { data: attachments, error: attachmentError } = await admin
    .from("source_attachments")
    .select("storage_path")
    .eq("household_id", householdID);
  if (attachmentError) throw new Error("attachment_storage_lookup_failed");
  for (const row of attachments ?? []) {
    if (row.storage_path) paths.add(row.storage_path);
  }

  const allPaths = [...paths];
  for (let index = 0; index < allPaths.length; index += 100) {
    const { error } = await bucket.remove(allPaths.slice(index, index + 100));
    if (error) throw new Error("storage_delete_failed");
  }
}

async function listStoragePaths(bucket: any, prefix: string): Promise<string[]> {
  const result: string[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await bucket.list(prefix, {
      limit: 1000,
      offset,
      sortBy: { column: "name", order: "asc" }
    });
    if (error) throw new Error("storage_list_failed");
    const entries = data ?? [];

    for (const entry of entries) {
      const path = `${prefix}/${entry.name}`;
      if (entry.id || entry.metadata) {
        result.push(path);
      } else {
        result.push(...await listStoragePaths(bucket, path));
      }
    }

    if (entries.length < 1000) break;
    offset += entries.length;
  }

  return result;
}

function env(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`missing_${name.toLowerCase()}`);
  return value;
}

function safe(error: unknown) {
  return error instanceof Error ? error.message.slice(0, 240) : "unknown_error";
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers });
}
