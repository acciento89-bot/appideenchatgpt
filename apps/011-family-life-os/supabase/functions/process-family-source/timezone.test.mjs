import assert from "node:assert/strict";
import test from "node:test";
import {
  endOfLocalDayISO,
  previousLocalEveningISO,
  resolveZonedDateTime
} from "./timezone.mjs";

test("Berlin summer time keeps the source wall clock", () => {
  const result = resolveZonedDateTime("2026-08-20", 18, 0, "Europe/Berlin");
  assert.equal(result.iso, "2026-08-20T16:00:00.000Z");
  assert.equal(result.ambiguous, false);
});

test("Berlin winter time keeps the source wall clock", () => {
  const result = resolveZonedDateTime("2026-01-20", 18, 0, "Europe/Berlin");
  assert.equal(result.iso, "2026-01-20T17:00:00.000Z");
  assert.equal(result.ambiguous, false);
});

test("local day end does not spill into the next Berlin day", () => {
  assert.equal(endOfLocalDayISO("2026-08-20", "Europe/Berlin"), "2026-08-20T21:59:00.000Z");
  assert.equal(endOfLocalDayISO("2026-01-20", "Europe/Berlin"), "2026-01-20T22:59:00.000Z");
});

test("previous-evening preparation survives DST changes", () => {
  assert.equal(previousLocalEveningISO("2026-03-30", "Europe/Berlin"), "2026-03-29T17:00:00.000Z");
  assert.equal(previousLocalEveningISO("2026-10-26", "Europe/Berlin"), "2026-10-25T18:00:00.000Z");
});

test("nonexistent spring-forward wall clock is rejected", () => {
  const result = resolveZonedDateTime("2026-03-29", 2, 30, "Europe/Berlin");
  assert.equal(result.iso, null);
  assert.equal(result.ambiguous, false);
});

test("fall-back duplicate wall clock is flagged as ambiguous", () => {
  const result = resolveZonedDateTime("2026-10-25", 2, 30, "Europe/Berlin");
  assert.equal(result.iso, "2026-10-25T00:30:00.000Z");
  assert.equal(result.ambiguous, true);
});
