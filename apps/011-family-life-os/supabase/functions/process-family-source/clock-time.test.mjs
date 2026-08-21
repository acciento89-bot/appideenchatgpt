import { assertEquals } from "jsr:@std/assert@1";
import { extractClockTime } from "./clock-time.mjs";

Deno.test("clock time ignores German dotted date and keeps explicit colon time", () => {
  assertEquals(
    extractClockTime("Elternabend am 21.08.2026 um 18:00 Uhr."),
    [18, 0]
  );
});

Deno.test("clock time supports dotted time when marked as a clock time", () => {
  assertEquals(
    extractClockTime("Elternabend am 21.08.2026 um 18.00 Uhr."),
    [18, 0]
  );
});

Deno.test("clock time supports full hour with Uhr", () => {
  assertEquals(
    extractClockTime("Elternabend am 21.08.2026 um 18 Uhr."),
    [18, 0]
  );
});

Deno.test("clock time does not treat a dotted date as a time", () => {
  assertEquals(extractClockTime("Elternabend am 21.08.2026."), null);
});
