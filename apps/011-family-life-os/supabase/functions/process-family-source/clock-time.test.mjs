import test from "node:test";
import assert from "node:assert/strict";
import { extractClockTime } from "./clock-time.mjs";

test("clock time ignores German dotted date and keeps explicit colon time", () => {
  assert.deepEqual(
    extractClockTime("Elternabend am 21.08.2026 um 18:00 Uhr."),
    [18, 0]
  );
});

test("clock time supports dotted time when marked as a clock time", () => {
  assert.deepEqual(
    extractClockTime("Elternabend am 21.08.2026 um 18.00 Uhr."),
    [18, 0]
  );
});

test("clock time supports full hour with Uhr", () => {
  assert.deepEqual(
    extractClockTime("Elternabend am 21.08.2026 um 18 Uhr."),
    [18, 0]
  );
});

test("clock time does not treat a dotted date as a time", () => {
  assert.equal(extractClockTime("Elternabend am 21.08.2026."), null);
});
