import { createClient } from "@supabase/supabase-js";
import {
  currentYearInTimezone,
  dateKey,
  endOfLocalDayISO,
  previousLocalEveningISO,
  resolveZonedDateTime
} from "./timezone.mjs";
import { extractClockTime } from "./clock-time.mjs";

type Candidate = {
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

const headers = { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" };
const kinds = new Set(["event", "task", "deadline", "payment", "preparation"]);
const unresolvedFieldNames = new Set(["member", "time", "starts_at", "due_at"]);

const schema = {
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
          unresolved_fields: {
            type: "array",
            items: { type: "string", enum: ["member", "time", "starts_at", "due_at"] }
          },
          reminder_at: { type: ["string", "null"] }
        },
        required: ["kind", "title", "starts_at", "ends_at", "due_at", "all_day", "location", "notes", "amount_minor", "currency", "assignee_names", "unresolved_fields", "reminder_at"]
      }
    }
  },
  required: ["proposals"]
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let admin: any = null;
  let sourceID: string | null = null;
  let runID: string | null = null;

  try {
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.startsWith("Bearer ")) return json({ error: "authentication_required" }, 401);

    const body = await req.json().catch(() => ({}));
    sourceID = typeof body.source_item_id === "string" ? body.source_item_id : null;
    const textOverride = typeof body.text_override === "string" ? body.text_override.trim() : "";
    if (!sourceID) return json({ error: "source_item_id_required" }, 400);

    const url = env("SUPABASE_URL");
    const anon = env("SUPABASE_ANON_KEY");
    const service = env("SUPABASE_SERVICE_ROLE_KEY");
    const user = createClient(url, anon, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });
    admin = createClient(url, service, { auth: { persistSession: false } });

    const { data: authData, error: authError } = await user.auth.getUser();
    if (authError || !authData.user) return json({ error: "invalid_session" }, 401);

    const { data: source, error: sourceError } = await user
      .from("source_items")
      .select("id, household_id, source_type, display_title, original_text, extracted_text, storage_path, content_type, file_name")
      .eq("id", sourceID)
      .single();
    if (sourceError || !source) return json({ error: "source_not_found_or_forbidden" }, 404);

    const { data: household } = await user.from("households").select("locale, timezone").eq("id", source.household_id).single();
    const { data: members, error: memberError } = await user
      .from("household_members")
      .select("id, display_name, role")
      .eq("household_id", source.household_id)
      .eq("invite_status", "active");
    if (memberError) throw new Error("member_lookup_failed");

    await admin.from("source_items").update({ processing_status: "processing", processing_error_code: null, last_processing_started_at: new Date().toISOString() }).eq("id", sourceID);
    await admin.from("action_proposals").update({ review_status: "rejected", is_included: false }).eq("source_item_id", sourceID).eq("review_status", "proposed");

    const apiKey = Deno.env.get("OPENAI_API_KEY")?.trim() ?? "";
    const model = Deno.env.get("OPENAI_MODEL")?.trim() || "gpt-5.6-luna";
    const provider = apiKey ? "openai" : "rules";
    const { data: run, error: runError } = await admin
      .from("extraction_runs")
      .insert({ source_item_id: sourceID, provider, model: apiKey ? model : "family-rules-v3", schema_version: 3, status: "processing" })
      .select("id")
      .single();
    if (runError || !run) throw new Error("extraction_run_create_failed");
    runID = run.id;

    const locale = household?.locale ?? "de-DE";
    const timezone = household?.timezone ?? "Europe/Berlin";
    const text = first(textOverride, source.extracted_text, source.original_text);
    let proposals: Candidate[];
    let usedFileInput = false;

    if (apiKey) {
      let signedURL: string | null = null;
      if (!text && source.storage_path) {
        const signed = await admin.storage.from("family-sources").createSignedUrl(source.storage_path, 300);
        signedURL = signed.data?.signedUrl ?? null;
      }
      proposals = await openAIExtract({
        apiKey,
        model,
        text,
        signedURL,
        contentType: source.content_type,
        fileName: source.file_name,
        title: source.display_title,
        sourceType: source.source_type,
        locale,
        timezone,
        members: (members ?? []).map((m: any) => ({ name: m.display_name, role: m.role }))
      });
      usedFileInput = !text && !!signedURL;
    } else {
      if (!text) throw new Error("ocr_or_provider_required");
      proposals = rulesExtract(text, locale, timezone);
    }

    const memberByName = new Map((members ?? []).map((m: any) => [normalize(m.display_name), m]));
    let count = 0;

    for (const raw of proposals) {
      const candidate = validate(raw);
      if (!candidate) continue;
      const unresolved: Record<string, string> = {};
      candidate.unresolved_fields.forEach((field) => unresolved[field] = "required");
      const memberIDs: string[] = [];
      for (const name of candidate.assignee_names) {
        const member: any = memberByName.get(normalize(name));
        if (member) memberIDs.push(member.id); else unresolved.member = "required";
      }

      const { data: proposal, error: proposalError } = await admin
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
          suggested_reminder_at: candidate.unresolved_fields.length ? null : candidate.reminder_at
        })
        .select("id")
        .single();
      if (proposalError || !proposal) throw new Error("proposal_insert_failed");

      if (memberIDs.length) {
        const rows = [...new Set(memberIDs)].map((member_id) => ({ proposal_id: proposal.id, member_id }));
        const { error } = await admin.from("action_proposal_assignees").insert(rows);
        if (error) throw new Error("proposal_assignee_insert_failed");
      }
      count += 1;
    }

    const finished = new Date().toISOString();
    await admin.from("extraction_runs").update({
      status: "succeeded",
      completed_at: finished,
      normalized_output: { schema_version: 3, proposal_count: count, provider, model: apiKey ? model : "family-rules-v3", used_file_input: usedFileInput, timezone }
    }).eq("id", runID);
    await admin.from("source_items").update({ processing_status: count ? "review" : "done", processing_error_code: null, processed_at: finished }).eq("id", sourceID);

    return json({ source_item_id: sourceID, proposal_count: count, provider, model: apiKey ? model : "family-rules-v3" });
  } catch (error) {
    const code = safe(error);
    if (admin && runID) await admin.from("extraction_runs").update({ status: "failed", error_code: code, completed_at: new Date().toISOString() }).eq("id", runID);
    if (admin && sourceID) await admin.from("source_items").update({ processing_status: "failed", processing_error_code: code }).eq("id", sourceID);
    return json({ error: code }, 500);
  }
});

async function openAIExtract(input: any): Promise<Candidate[]> {
  const people = input.members.length ? input.members.map((m: any) => `${m.name} (${m.role})`).join(", ") : "keine";
  const instruction = [
    "Extrahiere ausschließlich konkrete Familienaktionen aus der Quelle.",
    "Erfinde niemals Datum, Uhrzeit, Betrag, Ort oder Person.",
    `Alle lokalen Datums-/Uhrzeitangaben gelten in ${input.timezone}. Gib Zeitstempel immer als ISO 8601 mit Z oder explizitem UTC-Offset zurück.`,
    "unresolved_fields darf nur member, time, starts_at oder due_at enthalten.",
    "Bei einem Termin mit bekanntem Datum aber fehlender Uhrzeit: setze starts_at auf 00:00 dieses Datums in der Haushaltszeitzone als reinen Review-Platzhalter, setze time in unresolved_fields und reminder_at auf null.",
    "Fehlt bei einem Termin das Datum vollständig, setze starts_at null und starts_at in unresolved_fields.",
    "Fehlt bei Frist/Zahlung/Vorbereitung die Fälligkeit, setze due_at null und due_at in unresolved_fields.",
    "Ein Review-Platzhalter ist niemals eine bestätigte Information und muss über unresolved_fields blockiert bleiben.",
    "assignee_names darf nur exakte Namen aus der bekannten Mitgliederliste enthalten; wenn eine Person gemeint ist, aber nicht eindeutig zugeordnet werden kann, member als unresolved markieren.",
    "Arten: event, task, deadline, payment, preparation. Keine Ratschläge und kein Chat-Text.",
    `Locale ${input.locale}, Zeitzone ${input.timezone}, Referenz ${new Date().toISOString()}.`,
    `Mitglieder: ${people}.`
  ].join("\n");

  const content: any[] = [{ type: "input_text", text: `Quelle: ${input.title}\nTyp: ${input.sourceType}` }];
  if (input.text) content.push({ type: "input_text", text: input.text.slice(0, 60000) });
  else if (input.signedURL && (input.contentType ?? "").startsWith("image/")) content.push({ type: "input_image", image_url: input.signedURL, detail: "high" });
  else if (input.signedURL) content.push({ type: "input_file", file_url: input.signedURL, filename: input.fileName || "familienquelle.pdf" });
  else throw new Error("source_content_missing");

  const res = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: { Authorization: `Bearer ${input.apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: input.model,
      input: [
        { role: "developer", content: [{ type: "input_text", text: instruction }] },
        { role: "user", content }
      ],
      text: { format: { type: "json_schema", name: "family_action_proposals", strict: true, schema } },
      max_output_tokens: 5000
    })
  });
  if (!res.ok) throw new Error(`openai_http_${res.status}`);
  const payload = await res.json();
  const output = typeof payload.output_text === "string"
    ? payload.output_text
    : (payload.output ?? []).flatMap((item: any) => item.content ?? []).find((part: any) => part.type === "output_text")?.text;
  if (!output) throw new Error("openai_empty_output");
  const decoded = JSON.parse(output);
  if (!Array.isArray(decoded?.proposals)) throw new Error("openai_schema_decode_failed");
  return decoded.proposals;
}

function rulesExtract(text: string, locale: string, timezone: string): Candidate[] {
  const clean = text.replace(/\r/g, " ").replace(/\s+/g, " ").trim();
  if (!clean) return [];
  const dates = extractDates(clean, timezone);
  const time = extractClockTime(clean);
  const amount = clean.match(/\b(\d{1,6})(?:[,.](\d{2}))?\s*(?:€|EUR)\b/i);
  const result: Candidate[] = [];

  if (/klassenfahrt|ausflug|zahnarzt|arzt|training|elternabend|termin|aufführung|treffen/i.test(clean) && dates[0]) {
    const wall = time
      ? resolveZonedDateTime(dates[0], time[0], time[1], timezone)
      : resolveZonedDateTime(dates[0], 0, 0, timezone);
    const unresolved = !wall.iso ? ["starts_at"] : (!time || wall.ambiguous ? ["time"] : []);
    const reminder = wall.iso && unresolved.length === 0 ? offset(wall.iso, -60) : null;
    result.push(base("event", /klassenfahrt|ausflug/i.test(clean) ? "Klassenfahrt / Ausflug" : short(clean, "Termin"), {
      starts_at: wall.iso,
      reminder_at: reminder,
      unresolved_fields: unresolved
    }));
  }

  const consent = sentence(clean, /einverständ|genehmig|unterschr|abgeben/i);
  const consentDate = extractDates(consent ?? "", timezone)[0] ?? dates[1] ?? null;
  if (consent && consentDate) {
    const due = endOfLocalDayISO(consentDate, timezone);
    result.push(base("deadline", /einverständ/i.test(consent) ? "Einverständniserklärung abgeben" : short(consent, "Frist erledigen"), {
      due_at: due,
      reminder_at: due ? offset(due, -1440) : null,
      unresolved_fields: due ? [] : ["due_at"]
    }));
  }

  if (amount) {
    const minor = +amount[1] * 100 + +(amount[2] ?? 0);
    const paymentText = sentence(clean, /€|EUR|bezahlen|überweisen|kosten/i) ?? clean;
    const dueDate = extractDates(paymentText, timezone)[0] ?? dates.at(-1) ?? null;
    const due = dueDate ? endOfLocalDayISO(dueDate, timezone) : null;
    result.push(base("payment", `${euro(minor, locale)} bezahlen`, {
      due_at: due,
      amount_minor: minor,
      currency: "EUR",
      reminder_at: due ? offset(due, -1440) : null,
      unresolved_fields: due ? [] : ["due_at"]
    }));
  }

  const prep = sentence(clean, /mitbringen|einpacken|vorbereiten|lunchpaket|trinkflasche|kleidung|material/i);
  if (prep) {
    const due = dates[0] ? previousLocalEveningISO(dates[0], timezone) : null;
    result.push(base("preparation", short(prep, "Vorbereitung erledigen"), {
      due_at: due,
      reminder_at: due ? offset(due, -120) : null,
      unresolved_fields: due ? [] : ["due_at"]
    }));
  }

  if (!result.length && /muss|soll|bitte|erledigen|abholen|anrufen/i.test(clean)) {
    result.push(base("task", short(clean, "Aufgabe")));
  }
  return result;
}

function validate(value: any): Candidate | null {
  if (!value || !kinds.has(value.kind)) return null;
  const title = typeof value.title === "string" ? value.title.trim().slice(0, 240) : "";
  if (!title) return null;

  const startsAt = iso(value.starts_at);
  const endsAt = iso(value.ends_at);
  const dueAt = iso(value.due_at);
  const unresolved = new Set<string>(
    Array.isArray(value.unresolved_fields)
      ? value.unresolved_fields.filter((field: unknown) => typeof field === "string" && unresolvedFieldNames.has(field))
      : []
  );

  if (value.kind === "event" && !startsAt) unresolved.add("starts_at");
  if (["deadline", "payment", "preparation"].includes(value.kind) && !dueAt) unresolved.add("due_at");
  if (unresolved.has("time") && !startsAt) {
    unresolved.delete("time");
    unresolved.add("starts_at");
  }

  return {
    kind: value.kind,
    title,
    starts_at: startsAt,
    ends_at: endsAt,
    due_at: dueAt,
    all_day: value.all_day === true,
    location: str(value.location),
    notes: str(value.notes),
    amount_minor: Number.isInteger(value.amount_minor) && value.amount_minor >= 0 ? value.amount_minor : null,
    currency: typeof value.currency === "string" && /^[A-Z]{3}$/.test(value.currency) ? value.currency : null,
    assignee_names: Array.isArray(value.assignee_names) ? value.assignee_names.filter((v: unknown) => typeof v === "string").slice(0, 12) : [],
    unresolved_fields: [...unresolved].slice(0, 12),
    reminder_at: unresolved.size === 0 ? iso(value.reminder_at) : null
  };
}

function base(kind: Candidate["kind"], title: string, extra: Partial<Candidate> = {}): Candidate {
  return {
    kind,
    title,
    starts_at: null,
    ends_at: null,
    due_at: null,
    all_day: false,
    location: null,
    notes: null,
    amount_minor: null,
    currency: null,
    assignee_names: [],
    unresolved_fields: [],
    reminder_at: null,
    ...extra
  };
}

function extractDates(text: string, timezone: string): string[] {
  const found: { i: number; d: string }[] = [];
  const year = currentYearInTimezone(timezone);

  for (const m of text.matchAll(/\b(\d{1,2})[.\-/](\d{1,2})(?:[.\-/](\d{2,4}))?\b/g)) {
    let y = m[3] ? +m[3] : year;
    if (y < 100) y += 2000;
    const d = dateKey(y, +m[2], +m[1]);
    if (d) found.push({ i: m.index ?? 0, d });
  }

  const months: Record<string, number> = {
    januar: 1, februar: 2, märz: 3, maerz: 3, april: 4, mai: 5, juni: 6,
    juli: 7, august: 8, september: 9, oktober: 10, november: 11, dezember: 12
  };
  for (const m of text.matchAll(/\b(\d{1,2})\.\s*(Januar|Februar|März|Maerz|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)(?:\s+(\d{4}))?/gi)) {
    const d = dateKey(m[3] ? +m[3] : year, months[m[2].toLowerCase()], +m[1]);
    if (d) found.push({ i: m.index ?? 0, d });
  }

  return found.sort((a, b) => a.i - b.i).map((item) => item.d);
}

function offset(value: string, minutes: number) {
  return new Date(new Date(value).getTime() + minutes * 60000).toISOString();
}

function sentence(text: string, pattern: RegExp) {
  return text.split(/(?<=[.!?])\s+/).map((value) => value.trim()).find((value) => pattern.test(value)) ?? null;
}

function short(text: string, fallback: string) {
  const value = text.replace(/\s+/g, " ").trim();
  return !value ? fallback : value.length > 100 ? `${value.slice(0, 97)}…` : value;
}

function euro(value: number, locale: string) {
  try {
    return new Intl.NumberFormat(locale || "de-DE", { style: "currency", currency: "EUR" }).format(value / 100);
  } catch {
    return `${(value / 100).toFixed(2)} €`;
  }
}

function first(...values: any[]) {
  return values.find((value) => typeof value === "string" && value.trim())?.trim() ?? "";
}

function normalize(value: string) {
  return value.trim().toLocaleLowerCase("de-DE").replace(/\s+/g, " ");
}

function str(value: any) {
  return typeof value === "string" && value.trim() ? value.trim().slice(0, 1000) : null;
}

function iso(value: any) {
  if (typeof value !== "string") return null;
  const clean = value.trim();
  if (!/(?:Z|[+-]\d{2}:\d{2})$/i.test(clean)) return null;
  return Number.isFinite(Date.parse(clean)) ? new Date(clean).toISOString() : null;
}

function env(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`missing_${name.toLowerCase()}`);
  return value;
}

function safe(error: any) {
  return (error instanceof Error ? error.message : String(error))
    .toLowerCase()
    .replace(/[^a-z0-9_\-]/g, "_")
    .slice(0, 120) || "processing_failed";
}

function json(value: any, status = 200) {
  return new Response(JSON.stringify(value), { status, headers });
}
