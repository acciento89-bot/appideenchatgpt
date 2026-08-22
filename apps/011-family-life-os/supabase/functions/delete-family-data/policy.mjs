export function parseDeletionRequest(body) {
  const scope = body?.scope === "household" || body?.scope === "account" ? body.scope : null;
  const householdID = typeof body?.household_id === "string" && body.household_id.trim()
    ? body.household_id.trim()
    : null;
  return {
    scope,
    householdID,
    confirmed: body?.confirm === true
  };
}

export function anonymizedMemberPatch() {
  return {
    user_id: null,
    display_name: "Ehemaliges Mitglied",
    invite_status: "revoked"
  };
}
