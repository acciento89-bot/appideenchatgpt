export function extractClockTime(text) {
  if (typeof text !== "string" || !text.trim()) return null;

  const colon = text.match(/\b([01]?\d|2[0-3]):([0-5]\d)\s*(?:Uhr)?\b/i);
  if (colon) return [Number(colon[1]), Number(colon[2])];

  const dotWithUhr = text.match(/\b([01]?\d|2[0-3])\.([0-5]\d)\s*Uhr\b/i);
  if (dotWithUhr) return [Number(dotWithUhr[1]), Number(dotWithUhr[2])];

  const dotAfterUm = text.match(/\bum\s+([01]?\d|2[0-3])\.([0-5]\d)\b/i);
  if (dotAfterUm) return [Number(dotAfterUm[1]), Number(dotAfterUm[2])];

  const hourWithUhr = text.match(/\b([01]?\d|2[0-3])\s*Uhr\b/i);
  if (hourWithUhr) return [Number(hourWithUhr[1]), 0];

  return null;
}
