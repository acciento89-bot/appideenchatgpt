const formatterCache = new Map();

function formatter(timeZone) {
  if (!formatterCache.has(timeZone)) {
    formatterCache.set(
      timeZone,
      new Intl.DateTimeFormat("en-CA", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hourCycle: "h23"
      })
    );
  }
  return formatterCache.get(timeZone);
}

function zonedParts(value, timeZone) {
  const parts = formatter(timeZone).formatToParts(value);
  const bag = Object.fromEntries(parts.filter((part) => part.type !== "literal").map((part) => [part.type, part.value]));
  return {
    year: Number(bag.year),
    month: Number(bag.month),
    day: Number(bag.day),
    hour: Number(bag.hour),
    minute: Number(bag.minute),
    second: Number(bag.second)
  };
}

function parseDateKey(dateKey) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateKey ?? "");
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const probe = new Date(Date.UTC(year, month - 1, day, 12));
  if (probe.getUTCFullYear() !== year || probe.getUTCMonth() !== month - 1 || probe.getUTCDate() !== day) return null;
  return { year, month, day };
}

function matchesWallClock(timestamp, target, timeZone) {
  const actual = zonedParts(new Date(timestamp), timeZone);
  return actual.year === target.year &&
    actual.month === target.month &&
    actual.day === target.day &&
    actual.hour === target.hour &&
    actual.minute === target.minute;
}

export function dateKey(year, month, day) {
  const probe = new Date(Date.UTC(year, month - 1, day, 12));
  if (probe.getUTCFullYear() !== year || probe.getUTCMonth() !== month - 1 || probe.getUTCDate() !== day) return null;
  return `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

export function currentYearInTimezone(timeZone, now = new Date()) {
  return zonedParts(now, timeZone).year;
}

export function shiftDateKey(value, days) {
  const parsed = parseDateKey(value);
  if (!parsed) return null;
  const shifted = new Date(Date.UTC(parsed.year, parsed.month - 1, parsed.day + days, 12));
  return dateKey(shifted.getUTCFullYear(), shifted.getUTCMonth() + 1, shifted.getUTCDate());
}

export function resolveZonedDateTime(dateValue, hour, minute, timeZone) {
  const parsed = parseDateKey(dateValue);
  if (!parsed || !Number.isInteger(hour) || hour < 0 || hour > 23 || !Number.isInteger(minute) || minute < 0 || minute > 59) {
    return { iso: null, ambiguous: false };
  }

  const target = { ...parsed, hour, minute };
  const desiredAsUTC = Date.UTC(parsed.year, parsed.month - 1, parsed.day, hour, minute, 0, 0);
  let instant = desiredAsUTC;

  for (let attempt = 0; attempt < 4; attempt += 1) {
    const actual = zonedParts(new Date(instant), timeZone);
    const actualAsUTC = Date.UTC(actual.year, actual.month - 1, actual.day, actual.hour, actual.minute, 0, 0);
    const delta = desiredAsUTC - actualAsUTC;
    if (delta === 0) break;
    instant += delta;
  }

  const candidates = [instant - 3_600_000, instant, instant + 3_600_000]
    .filter((candidate) => matchesWallClock(candidate, target, timeZone));
  const unique = [...new Set(candidates)].sort((a, b) => a - b);
  if (unique.length === 0) return { iso: null, ambiguous: false };

  return {
    iso: new Date(unique[0]).toISOString(),
    ambiguous: unique.length > 1
  };
}

export function endOfLocalDayISO(dateValue, timeZone) {
  return resolveZonedDateTime(dateValue, 23, 59, timeZone).iso;
}

export function previousLocalEveningISO(dateValue, timeZone) {
  const previous = shiftDateKey(dateValue, -1);
  return previous ? resolveZonedDateTime(previous, 19, 0, timeZone).iso : null;
}
