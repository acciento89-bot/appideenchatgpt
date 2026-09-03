import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return json({ error: "service_not_configured" }, 503);

  const body = await request.json().catch(() => null);
  const rawText = typeof body?.rawText === "string" ? body.rawText.trim() : "";
  if (rawText.length < 3 || rawText.length > 8_000) return json({ error: "invalid_input" }, 400);

  const tone = ["factual", "customerFriendly", "insurance"].includes(body?.tone) ? body.tone : "factual";
  const prompt = [
    "Du formulierst deutsche Arbeitsrapporte für Handwerksbetriebe unterschiedlicher Gewerke.",
    "Formuliere ausschließlich aus den gelieferten Tatsachen. Erfinde niemals Messwerte, Material, Ursachen, Diagnosen oder ausgeführte Arbeiten.",
    "Schreibe präzise, professionell, neutral und gut verständlich. Entferne Füllwörter. Unsichere Aussagen bleiben als Feststellung oder Empfehlung gekennzeichnet.",
    `Stil: ${tone}`,
    `Gewerk: ${safe(body?.trade)}`,
    `Kunde: ${safe(body?.customer)}`,
    `Einsatzort: ${safe(body?.location)}`,
    `Anlage: ${safe(body?.system)}`,
    `Rohtext: ${rawText}`,
    "Gib nur den fertigen Rapporttext zurück, ohne Markdown und ohne erfundene Überschrift.",
  ].join("\n");

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_MODEL") ?? "gpt-5-mini",
      input: prompt,
      max_output_tokens: 900,
    }),
  });

  if (!response.ok) return json({ error: "generation_failed" }, 502);
  const result = await response.json();
  const report = extractOutputText(result);
  if (!report) return json({ error: "empty_generation" }, 502);
  return json({ report }, 200);
});

function safe(value: unknown): string {
  return typeof value === "string" && value.trim() ? value.trim().slice(0, 300) : "nicht angegeben";
}

function extractOutputText(value: any): string {
  if (typeof value?.output_text === "string") return value.output_text.trim();
  for (const item of value?.output ?? []) {
    for (const content of item?.content ?? []) {
      if (content?.type === "output_text" && typeof content?.text === "string") return content.text.trim();
    }
  }
  return "";
}

function json(value: unknown, status: number): Response {
  return new Response(JSON.stringify(value), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}
