import test from "node:test";
import assert from "node:assert/strict";
import { anonymizedMemberPatch, parseDeletionRequest } from "./policy.mjs";

test("account deletion requires explicit confirmation", () => {
  assert.deepEqual(parseDeletionRequest({ scope: "account" }), {
    scope: "account",
    householdID: null,
    confirmed: false
  });
  assert.equal(parseDeletionRequest({ scope: "account", confirm: true }).confirmed, true);
});

test("household deletion keeps the requested household id", () => {
  assert.deepEqual(parseDeletionRequest({ scope: "household", household_id: "abc", confirm: true }), {
    scope: "household",
    householdID: "abc",
    confirmed: true
  });
});

test("unknown scope is rejected", () => {
  assert.equal(parseDeletionRequest({ scope: "everything", confirm: true }).scope, null);
});

test("departed memberships are anonymized and revoked", () => {
  assert.deepEqual(anonymizedMemberPatch(), {
    user_id: null,
    display_name: "Ehemaliges Mitglied",
    invite_status: "revoked"
  });
});
