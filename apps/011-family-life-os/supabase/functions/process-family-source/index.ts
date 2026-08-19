import { createClient } from "@supabase/supabase-js";

type ProposalCandidate = {
  kind: "event" | "task" | "deadline" | "payment" | "preparation";
  title: string;
  starts_at: string | null;
  ends_at: string | null;
  due_at: string | null;
  all_day: boolean;
  location: string | null;
  notes: string | null;
  amount_minor: number | null;
  currency: string | null;
  assignee_names: string[];
  unresolved_fields: string[];
  reminder_at: string | null;
};

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

const allowedKinds = new Set(["event", "task", "deadline", "payment", "preparation"]);

const actionSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    proposals: {
      type: "array",
      maxItems: 20,
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          kind: { type: "string", enum: ["event", "task", "deadline", "payment", "preparation"] },
          title: { type: "string", minLength: 1, maxLength: 240 },
          starts_at: { type: ["string", "null"] },
          ends_at: { type: ["string", "null"] },
          due_at: { type: ["string", "null"] },
          all_day: { type: "boolean" },
          location: { type: ["string", "null"] },
          notes: { type: ["string", "null"] },
          amount_minor: { type: ["integer", "null"], minimum: 0 },
          currency: { type: ["string", "null"] },
          assignee_names: { type: "array", items: { type: "string" } },
          unresolved_fields: { type: "array", items: { type: "string" } },
          reminder_at: { type: ["string", "null"] },
        },
        required: [
          "kind", "title", "starts_at", "ends_at", "due_at", "all_day",
          "location", "notes", "amount_minor", "currency", "assignee_names",
          "unresolved_fields", "reminder_at",
        ],
      },
    },
  },
  required: ["proposals"],
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return response({ error: "method_not_allowed" }, 405);

  let serviceClient: ReturnType<typeof createClient> | null = null;
  let sourceID: string | null = null;
  let runID: string | null = null;

  try {
    const authorization = req.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return response({ error: "authentication_required" }, 401);

    const body = await req.json().catch(() => ({}));
    sourceID = typeof body.source_item_id === "string" ? body.source_item_id : null;
    const textOverride = typeof body.text_override === "string" ? body.text_override.trim() : "";
    if (!sourceID) return response({ error: "source_item_id_required" }, 400);

    const supabaseURL = requiredEnv("SUPABASE_URL");
    const anonKey = requiredEnv("SUPABASE_ANON_KEY");
    const serviceKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");

    const userClient = createClient(supabaseURL, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    serviceClient = createClient(supabaseURL, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return response({ error: "invalid_session" }, 401);

    const { data: source, error: sourceError } = await userClient
      .from("source_items")
      .select("id, household_id, source_type, display_title, original_text, extracted_text, storage_path, content_type, file_name")
      .eq("id", sourceID)
      .single();
    if (sourceError || !source) return response({ error: "source_not_found_or_forbidden" }, 404);

    const { data: household, error: householdError } = await userClient
      .from("households")
      .select("id, locale, timezone")
      .eq("id", source.household_id)
      .single();
    if (householdError || !household) return response({ error: "household_not_available" }, 403);

    const { data: members, error: membersError } = await userClient
      .from("household_members")
      .select("id, display_name, role, invite_status")
      .eq("household_id", source.household_id)
      .eq("invite_status", "active");
    if (membersError) throw new Error("member_lookup_failed");

    const providerKey = Deno.env.get("OPENAI_API_KEY")?.trim() ?? "";
    const configuredModel = Deno.env.get("OPENAI_MODEL")?.trim() || "gpt-5.6-luna";
    const provider = providerKey ? "openai" : "rules";
    const model = providerKey ? configuredModel : "family-rules-v1";

    await serviceClient
      .from("source_items")
      .update({
        processing_status: "processing",
        processing_error_code: null,
        last_processing_started_at: new Date().toISOString(),
      })
      .eq("id", sourceID);

    // A retry never overwrites extraction history. Old unconfirmed proposals stay
    // auditable but are retired before the new extraction run is created.
    await serviceClient
      .from("action_proposals")
      .update({ review_status: "rejected", is_included: false })
      .eq("source_item_id", sourceID)
      .eq("review_status", "proposed");

    const { data: run, error: runError } = await serviceClient
      .from("extraction_runs")
      .insert({
        source_item_id: sourceID,
        provider,
        model,
        schema_version: 2,
        status: "processing",
      })
      .select("id")
      .single();
    if (runError || !run) throw new Error("extraction_run_create_failed");
    runID = run.id;

    const sourceText = firstNonEmpty(textOverride, source.extracted_text, source.original_text);
    let candidates: ProposalCandidate[];
    let usedFileInput = false;

    if (providerKey) {
      let signedURL: string | null = null;
      if (!sourceText && source.storage_path) {
        const signed = await serviceClient.storage
          .from("family-sources")
          .createSignedUrl(source.storage_path, 300);
        signedURL = signed.data?.signedUrl ?? null;
      }

      const result = await extractWithOpenAI({
        apiKey: providerKey,
        model: configuredModel,
        sourceTitle: source.display_title,
        sourceText,
        sourceType: source.source_type,
        contentType: source.content_type,
        fileName: source.file_name,
        signedURL,
        locale: household.locale ?? "de-DE",
        timezone: household.timezone ?? "Europe/Berlin",
        members: (members ?? []).map((member: any) => ({ name: member.display_name, role: member.role })),
      });
      candidates = result;
      usedFileInput = !sourceText && !!signedURL;
    } else {
      candidates = fallbackExtract(sourceText || "", household.locale ?? "de-DE");
    }

    const validated = candidates.map(validateCandidate).filter((value): value is ProposalCandidate => value !== null);
    const memberMap = new Map<string, any>();
    for (const member of members ?? []) memberMap.set(normalizeName(member.display_name), member);

    let insertedCount = 0;
    for (const candidate of validated) {
      const unresolved: Record<string, string> = {};
      for (const field of candidate.unresolved_fields) unresolved[field] = "required";

      const matchedMemberIDs: string[] = [];
      for (const requestedName of candidate.assignee_names) {
        const match = memberMap.get(normalizeName(requestedName));
        if (match) matchedMemberIDs.push(match.id);
        else unresolved.member = "required";
      }

      const { data: proposal, error: proposalError } = await serviceClient
        .from("action_proposals")
        .insert({
          source_item_id: sourceID,
          extraction_run_id: runID,
          kind: candidate.kind,
          title: candidate.title,
          starts_at: candidate.starts_at,
          ends_at: candidate.ends_at,
          due_at: candidate.due_at,
          all_day: candidate.all_day,
          location: candidate.location,
          notes: candidate.notes,
          amount_minor: candidate.amount_minor,
          currency: candidate.currency,
          unresolved_fields: unresolved,
          is_included: true,
          review_status: "proposed",
          suggested_reminder_at: candidate.reminder_at,
        })
        .select("id")
        .single();
      if (proposalError || !proposal) throw new Error("proposal_insert_failed");

      if (matchedMemberIDs.length > 0) {
        const rows = [...new Set(matchedMemberIDs)].map((memberID) => ({
          proposal_id: proposal.id,
          member_id: memberID,
        }));
        const { error: assigneeError } = await serviceClient.from("action_proposal_assignees").insert(rows);
        if (assigneeError) throw new Error("proposal_assignee_insert_failed");
      }
      insertedCount += 1;
    }

    const finishedAt = new Date().toISOString();
    await serviceClient
      .from("extraction_runs")
      .update({
        status: "succeeded",
        completed_at: finishedAt,
        normalized_output: {
          schema_version: 2,
          proposal_count: insertedCount,
          provider,
          model,
          used_file_input: usedFileInput,
        },
      })
      .eq("id", runID);

    await serviceClient
      .from("source_items")
      .update({
        processing_status: insertedCount > 0 ? "review" : "done",
        processing_error_code: null,
        processed_at: finishedAt,
      })
      .eq("id", sourceID);

    await incrementUsage(serviceClient, source.household_id, providerKey ? 1 : 0);

    return response({
      source_item_id: sourceID,
      proposal_count: insertedCount,
      provider,
      model,
      used_file_input: usedFileInput,
    });
  } catch (error) {
    const errorCode = safeErrorCode(error);
    if (serviceClient && runID) {
      await serviceClient
        .from("extraction_runs")
        .update({ status: "failed", error_code: errorCode, completed_at: new Date().toISOString() })
        .eq("id", runID);
    }
    if (serviceClient && sourceID) {
      await serviceClient
        .from("source_items")
        .update({ processing_status: "failed", processing_error_code: errorCode })
        .eq("id", sourceID);
    }
    return response({ error: errorCode }, 500);
  }
});

async function extractWithOpenAI(input: {
  apiKey: string;
  model: string;
  sourceTitle: string;
  sourceText: string;
  sourceType: string;
  contentType: string | null;
  fileName: string | null;
  signedURL: string | null;
  locale: string;
  timezone: string;
  members: { name: string; role: string }[];
}): Promise<ProposalCandidate[]> {
  const today = new Date().toISOString();
  const memberText = input.members.length
    ? input.members.map((m) => `${m.name} (${m.role})`).join(", ")
    : "keine bekannten Personen";

  const developerInstruction = [
    "Du extrahierst ausschließlich konkrete Familienaktionen aus einer Quelle.",
    "Erfinde niemals Datum, Uhrzeit, Betrag, Ort oder Person.",
    "Wenn ein erforderliches Feld unklar ist, setze es auf null und nenne das Feld in unresolved_fields.",
    "assignee_names darf nur exakt Namen aus der bereitgestellten Mitgliederliste enthalten; sonst leer lassen und member als unresolved markieren.",
    "Mögliche Arten: event, task, deadline, payment, preparation.",
    "Ein Quelltext kann mehrere Aktionen erzeugen. Keine allgemeinen Ratschläge und kein Chat-Text.",
    `Haushalts-Locale: ${input.locale}. Zeitzone: ${input.timezone}. Aktueller Referenzzeitpunkt: ${today}.`,
    `Bekannte Haushaltsmitglieder: ${memberText}.`,
  ].join("\n");

  const userContent: any[] = [
    { type: "input_text", text: `Quelle: ${input.sourceTitle}\nTyp: ${input.sourceType}` },
  ];

  if (input.sourceText) {
    userContent.push({ type: "input_text", text: input.sourceText.slice(0, 60000) });
  } else if (input.signedURL) {
    if ((input.contentType ?? "").startsWith("image/")) {
      userContent.push({ type: "input_image", image_url: input.signedURL, detail: "high" });
    } else {
      userContent.push({
        type: "input_file",
        file_url: input.signedURL,
        filename: input.fileName || "familienquelle.pdf",
      });
    }
  } else {
    throw new Error("source_content_missing");
  }

  const openAIResponse = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${input.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: input.model,
      input: [
        { role: "developer", content: [{ type: "input_text", text: developerInstruction }] },
        { role: "user", content: userContent },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "family_action_proposals",
          strict: true,
          schema: actionSchema,
        },
      },
      max_output_tokens: 5000,
    }),
  });

  if (!openAIResponse.ok) throw new Error(`openai_http_${openAIResponse.status}`);
  const payload = await openAIResponse.json();
  const outputText = extractOutputText(payload);
  if (!outputText) throw new Error("openai_empty_output");

  const decoded = JSON.parse(outputText);
  if (!decoded || !Array.isArray(decoded.proposals)) throw new Error("openai_schema_decode_failed");
  return decoded.proposals as ProposalCandidate[];
}

function extractOutputText(payload: any): string | null {
  if (typeof payload?.output_text === "string" && payload.output_text.trim()) return payload.output_text;
  for (const item of payload?.output ?? []) {
    for (const content of item?.content ?? []) {
      if (content?.type === "output_text" && typeof content.text === "string") return content.text;
    }
  }
  return null;
}

function validateCandidate(candidate: any): ProposalCandidate | null {
  if (!candidate || !allowedKinds.has(candidate.kind)) return null;
  const title = typeof candidate.title === "string" ? candidate.title.trim().slice(0, 240) : "";
  if (!title) return null;

  const currency = typeof candidate.currency === "string" && /^[A-Z]{3}$/.test(candidate.currency)
    ? candidate.currency
    : null;
  const amountMinor = Number.isInteger(candidate.amount_minor) && candidate.amount_minor >= 0
    ? candidate.amount_minor
    : null;

  return {
    kind: candidate.kind,
    title,
    starts_at: validDateString(candidate.starts_at),
    ends_at: validDateString(candidate.ends_at),
    due_at: validDateString(candidate.due_at),
    all_day: candidate.all_day === true,
    location: nullableString(candidate.location),
    notes: nullableString(candidate.notes),
    amount_minor: amountMinor,
    currency,
    assignee_names: Array.isArray(candidate.assignee_names)
      ? candidate.assignee_names.filter((v: unknown) => typeof v === "string").slice(0, 12)
      : [],
    unresolved_fields: Array.isArray(candidate.unresolved_fields)
      ? candidate.unresolved_fields.filter((v: unknown) => typeof v === "string").slice(0, 12)
      : [],
    reminder_at: validDateString(candidate.reminder_at),
  };
}

function fallbackExtract(text: string, locale: string): ProposalCandidate[] {
  const clean = text.replace(/\r/g, "").trim();
  if (!clean) return [];

  const dates = extractDates(clean);
  const time = clean.match(/\b([01]?\d|2[0-3])[:.]([0-5]\d)\s*(?:Uhr)?\b/i);
  const amount = clean.match(/\b(\d{1,6})(?:[,.](\d{2}))?\s*(?:€|EUR)\b/i);
  const proposals: ProposalCandidate[] = [];

  const classTrip = /klassenfahrt|ausflug|fahrt/i.test(clean);
  if ((classTrip || /zahnarzt|arzt|training|elternabend|termin|aufführung|treffen/i.test(clean)) && dates[0]) {
    const starts = withTime(dates[0], time ? Number(time[1]) : 9, time ? Number(time[2]) : 0);
    proposals.push(baseCandidate({
      kind: "event",
      title: classTrip ? "Klassenfahrt / Ausflug" : conciseTitle(clean, "Termin"),
      starts_at: starts,
      reminder_at: offsetISO(starts, -60),
      unresolved_fields: time ? [] : ["time"],
    }));
  }

  const consentSentence = sentenceContaining(clean, /einverständ|genehmig|unterschr|abgeben/i);
  const consentDate = extractDates(consentSentence ?? "")[0] ?? (dates.length > 1 ? dates[1] : null);
  if (consentSentence && consentDate) {
    proposals.push(baseCandidate({
      kind: "deadline",
      title: /einverständ/i.test(consentSentence) ? "Einverständniserklärung abgeben" : conciseTitle(consentSentence, "Frist erledigen"),
      due_at: endOfDay(consentDate),
      reminder_at: offsetISO(endOfDay(consentDate), -24 * 60),
    }));
  }

  if (amount) {
    const amountMinor = Number(amount[1]) * 100 + Number(amount[2] ?? "0");
    const paymentSentence = sentenceContaining(clean, /€|EUR|bezahlen|überweisen|kosten/i) ?? clean;
    const paymentDates = extractDates(paymentSentence);
    const due = paymentDates[0] ?? (dates.length > 2 ? dates[2] : dates.at(-1) ?? null);
    proposals.push(baseCandidate({
      kind: "payment",
      title: `${formatEuro(amountMinor, locale)} bezahlen`,
      due_at: due ? endOfDay(due) : null,
      amount_minor: amountMinor,
      currency: "EUR",
      reminder_at: due ? offsetISO(endOfDay(due), -24 * 60) : null,
      unresolved_fields: due ? [] : ["due_at"],
    }));
  }

  const prepSentence = sentenceContaining(clean, /mitbringen|einpacken|vorbereiten|lunchpaket|trinkflasche|kleidung|material/i);
  if (prepSentence) {
    const eventDate = dates[0] ?? null;
    const due = eventDate ? previousEvening(eventDate) : null;
    proposals.push(baseCandidate({
      kind: "preparation",
      title: conciseTitle(prepSentence, "Vorbereitung erledigen"),
      due_at: due,
      reminder_at: due ? offsetISO(due, -120) : null,
      unresolved_fields: due ? [] : ["due_at"],
    }));
  }

  if (proposals.length === 0 && /muss|soll|bitte|erledigen|abholen|anrufen/i.test(clean)) {
    proposals.push(baseCandidate({ kind: "task", title: conciseTitle(clean, "Aufgabe") }));
  }

  const seen = new Set<string>();
  return proposals.filter((proposal) => {
    const key = [proposal.kind, proposal.title, proposal.starts_at, proposal.due_at, proposal.amount_minor].join("|");
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function baseCandidate(overrides: Partial<ProposalCandidate> & Pick<ProposalCandidate, "kind" | "title">): ProposalCandidate {
  return {
    kind: overrides.kind,
    title: overrides.title,
    starts_at: overrides.starts_at ?? null,
    ends_at: overrides.ends_at ?? null,
    due_at: overrides.due_at ?? null,
    all_day: overrides.all_day ?? false,
    location: overrides.location ?? null,
    notes: overrides.notes ?? null,
    amount_minor: overrides.amount_minor ?? null,
    currency: overrides.currency ?? null,
    assignee_names: overrides.assignee_names ?? [],
    unresolved_fields: overrides.unresolved_fields ?? [],
    reminder_at: overrides.reminder_at ?? null,
  };
}

function extractDates(text: string): string[] {
  const results: { index: number; iso: string }[] = [];
  const currentYear = new Date().getUTCFullYear();
  const numeric = /\b(\d{1,2})[.\-/](\d{1,2})(?:[.\-/](\d{2,4}))?\b/g;
  for (const match of text.matchAll(numeric)) {
    let year = match[3] ? Number(match[3]) : currentYear;
    if (year < 100) year += 2000;
    const iso = dateOnlyISO(year, Number(match[2]), Number(match[1]));
    if (iso) results.push({ index: match.index ?? 0, iso });
  }

  const monthMap: Record<string, number> = {
    januar: 1, februar: 2, märz: 3, maerz: 3, april: 4, mai: 5, juni: 6,
    juli: 7, august: 8, september: 9, oktober: 10, november: 11, dezember: 12,
  };
  const named = /\b(\d{1,2})\.\s*(Januar|Februar|März|Maerz|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)(?:\s+(\d{4}))?/gi;
  for (const match of text.matchAll(named)) {
    const month = monthMap[match[2].toLowerCase()];
    const year = match[3] ? Number(match[3]) : currentYear;
    const iso = dateOnlyISO(year, month, Number(match[1]));
    if (iso) results.push({ index: match.index ?? 0, iso });
  }

  return results.sort((a, b) => a.index - b.index).map((r) => r.iso);
}

function dateOnlyISO(year: number, month: number, day: number): string | null {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  const date = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null;
  return date.toISOString();
}

function withTime(dateISO: string, hour: number, minute: number): string {
  const date = new Date(dateISO);
  date.setUTCHours(hour, minute, 0, 0);
  return date.toISOString();
}

function endOfDay(dateISO: string): string {
  const date = new Date(dateISO);
  date.setUTCHours(23, 59, 0, 0);
  return date.toISOString();
}

function previousEvening(dateISO: string): string {
  const date = new Date(dateISO);
  date.setUTCDate(date.getUTCDate() - 1);
  date.setUTCHours(19, 0, 0, 0);
  return date.toISOString();
}

function offsetISO(dateISO: string, minutes: number): string {
  return new Date(new Date(dateISO).getTime() + minutes * 60_000).toISOString();
}

function sentenceContaining(text: string, pattern: RegExp): string | null {
  const parts = text.split(/\n+|(?<=[.!?])\s+/).map((part) => part.trim()).filter(Boolean);
  return parts.find((part) => pattern.test(part)) ?? null;
}

function conciseTitle(text: string, fallback: string): string {
  const clean = text.replace(/\s+/g, " ").trim().replace(/^[\-•]+\s*/, "");
  if (!clean) return fallback;
  return clean.length > 100 ? `${clean.slice(0, 97)}…` : clean;
}

function formatEuro(amountMinor: number, locale: string): string {
  try {
    return new Intl.NumberFormat(locale || "de-DE", { style: "currency", currency: "EUR" }).format(amountMinor / 100);
  } catch {
    return `${(amountMinor / 100).toFixed(2)} €`;
  }
}

function firstNonEmpty(...values: unknown[]): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return "";
}

function normalizeName(value: string): string {
  return value.trim().toLocaleLowerCase("de-DE").replace(/\s+/g, " ");
}

function nullableString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const clean = value.trim();
  return clean ? clean.slice(0, 1000) : null;
}

function validDateString(value: unknown): string | null {
  if (typeof value !== "string" || !value.trim()) return null;
  const timestamp = Date.parse(value);
  return Number.isFinite(timestamp) ? value : null;
}

async function incrementUsage(client: ReturnType<typeof createClient>, householdID: string, aiIncrement: number) {
  const periodStart = `${new Date().toISOString().slice(0, 7)}-01`;
  const { data } = await client
    .from("household_usage_monthly")
    .select("ai_imports, storage_bytes")
    .eq("household_id", householdID)
    .eq("period_start", periodStart)
    .maybeSingle();

  await client.from("household_usage_monthly").upsert({
    household_id: householdID,
    period_start: periodStart,
    ai_imports: Number(data?.ai_imports ?? 0) + aiIncrement,
    storage_bytes: Number(data?.storage_bytes ?? 0),
    updated_at: new Date().toISOString(),
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`missing_${name.toLowerCase()}`);
  return value;
}

function safeErrorCode(error: unknown): string {
  const raw = error instanceof Error ? error.message : String(error);
  return raw.toLowerCase().replace(/[^a-z0-9_\-]/g, "_").slice(0, 120) || "processing_failed";
}

function response(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), { status, headers: jsonHeaders });
}
