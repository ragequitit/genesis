// deno-lint-ignore-file no-explicit-any
// [TILLAGT v5.1381.0] GENESIS-AI (Chris 2026-10-30): Claude i Genesis - Nixie svarar pa fragor, rapporterna sorteras,
// chatten granskas. Se cloud/ai-server.sql. Nyckeln ar hemligheten ANTHROPIC_API_KEY. Saknas den: Nixie svarar att
// hon vilar, chatten slapps direkt (fail-open) och rapporterna vantar.
import Anthropic from "npm:@anthropic-ai/sdk";
import { createClient } from "npm:@supabase/supabase-js@2";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SB_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const API_KEY = Deno.env.get("ANTHROPIC_API_KEY") || "";
const MODEL = "claude-opus-5-5";
const SITE = "https://games.chriswhippit.com";

const admin = createClient(SB_URL, SB_SERVICE, { auth: { persistSession: false } });
const client = API_KEY ? new Anthropic({ apiKey: API_KEY }) : null;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-genesis-session, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { ...CORS, "Content-Type": "application/json" } });

// ---------- kunskapen: How to play + de senaste patch notes, hamtas fran sajten och hals i 10 min ----------
let KNOW = { at: 0, text: "" };
async function knowledge(): Promise<string> {
  if (KNOW.text && Date.now() - KNOW.at < 600_000) return KNOW.text;
  try {
    const [htp, pn] = await Promise.all([
      fetch(SITE + "/htp.json").then((r) => r.json()),
      fetch(SITE + "/patchnotes.json").then((r) => r.json()),
    ]);
    const parts: string[] = ["# HOW TO PLAY (" + (htp.ver || "") + ")"];
    for (const s of htp.sections || []) parts.push("## " + s.title + "\n" + s.text);
    parts.push("\n# RECENT PATCH NOTES (newest first)");
    for (const e of (pn.entries || []).slice(0, 15)) {
      const lines = (e.en || []).map((g: { h: string; li: string[] }) => g.h + ": " + (g.li || []).join(" ")).join("\n");
      parts.push("## " + e.ver + " (" + e.date + ") " + (e.title_en || "") + "\n" + lines);
    }
    KNOW = { at: Date.now(), text: parts.join("\n\n") };
  } catch (_e) {
    if (!KNOW.text) KNOW = { at: Date.now(), text: "(The game guide could not be loaded right now.)" };
  }
  return KNOW.text;
}

type Usage = { input_tokens?: number; output_tokens?: number };
async function ask(system: any[], messages: any[],
                   maxTokens: number, effort: "low" | "medium" | "high") {
  // Claude Opus 5.5: tankandet ar alltid pa - djupet styrs med effort. Server-side fallback om en sakerhetsklassare nekar.
  const r = await client!.beta.messages.create({
    model: MODEL, max_tokens: maxTokens, system, messages,
    output_config: { effort },
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
  } as any) as any;
  const text = r.stop_reason === "refusal" ? "" :
    r.content.filter((b: any) => b.type === "text").map((b: any) => b.text).join("").trim();
  return { text, refusal: r.stop_reason === "refusal", usage: (r.usage || {}) as Usage };
}

// ---------- 1. NIXIE ----------
const NIXIE = `You are Nixie, the friendly guide inside the browser game Project Genesis (a calm idle MMO-RPG played in menus).
Players ask you questions while they play. Answer from the game guide and patch notes below - they are the truth about the game.
- Reply in the same language the player writes in (usually English or Swedish).
- Be short and warm: 1-4 short sentences, or a few bullets when steps are needed. Plain text, no markdown headings, no tables.
- Name the buttons, windows and places exactly as the guide does, so the player can find them.
- If the guide does not answer the question, say you are not sure and suggest asking in chat or sending it with "Bugs & ideas". Never invent features, numbers, drop rates or release dates.
- Never share hidden numbers, caps, odds or how to cheat or exploit the game. Do not promise future changes.
- Only talk about Project Genesis. Politely steer other topics back to the game.`;

async function nixie(req: Request, body: Record<string, unknown>) {
  const auth = req.headers.get("authorization") || "";
  const sess = req.headers.get("x-genesis-session") || "";
  const character = String(body.character || "");
  const question = String(body.question || "").slice(0, 500);
  const user = createClient(SB_URL, SB_ANON, {
    auth: { persistSession: false },
    global: { headers: { Authorization: auth, ...(sess ? { "x-genesis-session": sess } : {}) } },
  });
  const begin = await user.rpc("ai_nixie_begin", { p_character: character, p_question: question });
  if (begin.error) return json({ error: begin.error.message, message: begin.error.message, detail: begin.error.details }, 400);
  const logId = begin.data as number;
  if (!client) {
    await admin.from("ai_log").update({ output: "(no key)", verdict: "off" }).eq("id", logId);
    return json({ answer: "Nixie is taking a little break right now. Try again later!", off: true });
  }
  const t0 = Date.now();
  const hist = Array.isArray(body.history) ? (body.history as { q: string; a: string }[]).slice(-4) : [];
  const messages: any[] = [];
  for (const h of hist) {
    if (!h || !h.q || !h.a) continue;
    messages.push({ role: "user", content: String(h.q).slice(0, 500) }, { role: "assistant", content: String(h.a).slice(0, 1500) });
  }
  messages.push({ role: "user", content: question });
  try {
    const kb = await knowledge();
    const r = await ask([{ type: "text", text: NIXIE }, { type: "text", text: kb, cache_control: { type: "ephemeral" } }], messages, 2000, "low");
    const answer = r.text || "Hmm, I am not sure about that one. Try asking in chat, or send it with Bugs & ideas!";
    await admin.from("ai_log").update({ output: answer, verdict: r.refusal ? "refusal" : "ok", tokens_in: r.usage.input_tokens ?? null,
      tokens_out: r.usage.output_tokens ?? null, ms: Date.now() - t0 }).eq("id", logId);
    return json({ answer });
  } catch (e) {
    await admin.from("ai_log").update({ output: String(e).slice(0, 500), verdict: "error", ms: Date.now() - t0 }).eq("id", logId);
    return json({ answer: "Nixie lost her train of thought. Try again in a moment!", error: true });
  }
}

// ---------- 2. RAPPORTERNA ----------
const TRIAGE = `Du sorterar bugg- och idérapporter från spelare i webbläsarspelet Project Genesis åt utvecklaren Chris.
Spelets guide och de senaste patch notes står nedan. Skriv på enkel svenska, högst fyra korta rader, i exakt den här formen:
Typ: <Bugg eller Idé> · <Viktigt / Mellan / Litet>
Spelaren ser: <vad spelaren beskriver, med egna ord>
Troligen: <vilken del av spelet det gäller och vad det kan bero på, utifrån guiden - gissa aldrig kod>
Förslag: <vad Chris kan göra eller fråga spelaren>
Titta på skärmbilden om den finns. Ingen kod, inga funktionsnamn.`;

async function triage() {
  if (!client) return json({ skipped: "no key" });
  const { data: rows } = await admin.from("bug_reports")
    .select("id, kind, area, what, expected, ctx, shot").eq("status", "new").is("ai_note", null).order("created_at").limit(5);
  const kb = await knowledge();
  let n = 0;
  for (const r of rows || []) {
    const t0 = Date.now();
    const ctx = { ...(r.ctx || {}) } as Record<string, unknown>;
    const content: any[] = [];
    const m = typeof r.shot === "string" ? r.shot.match(/^data:(image\/(?:webp|png|jpeg|gif));base64,(.+)$/) : null;
    if (m) content.push({ type: "image", source: { type: "base64", media_type: m[1], data: m[2] } });
    content.push({ type: "text", text: JSON.stringify({ kind: r.kind, area: r.area, what: r.what, expected: r.expected,
      version: ctx.ver, zone: ctx.zone, region: ctx.region, open_windows: ctx.open, screen: [ctx.w, ctx.h], touch: ctx.coarse, browser: ctx.ua }) });
    try {
      const a = await ask([{ type: "text", text: TRIAGE }, { type: "text", text: kb, cache_control: { type: "ephemeral" } }],
        [{ role: "user", content }], 3000, "medium");
      const note = a.text || "(Claude kunde inte sammanfatta rapporten)";
      await admin.from("bug_reports").update({ ai_note: note, ai_at: new Date().toISOString() }).eq("id", r.id);
      await admin.from("ai_log").insert({ kind: "triage", ref: String(r.id), output: note, verdict: a.refusal ? "refusal" : "ok",
        tokens_in: a.usage.input_tokens ?? null, tokens_out: a.usage.output_tokens ?? null, ms: Date.now() - t0 });
      n++;
    } catch (e) {
      await admin.from("ai_log").insert({ kind: "triage", ref: String(r.id), output: String(e).slice(0, 500), verdict: "error", ms: Date.now() - t0 });
    }
  }
  return json({ done: n });
}

// ---------- 3. CHATTEN ----------
const GUARD = `You moderate the public chat of a friendly online game (players are teens and adults, chat is in English and Swedish).
Decide if one chat message may be shown. Be lenient: when in doubt, allow it.
ALLOW: normal talk, jokes, banter between friends, mild swearing, frustration with the game, criticism of the game or the developer, game trash talk.
BLOCK only: slurs or hate against a group; harassment, insults or threats aimed at a person; sexual content; sharing personal information (phone numbers, addresses, emails, real full names of others); scam or phishing links; advertising other games or services; spam.
Answer with JSON only: {"allow": true or false, "reason": "<at most 8 words, English>"}`;

async function chatguard(body: Record<string, unknown>) {
  const id = Number(body.id);
  const { data: msg } = await admin.from("chat_messages").select("id, body, channel, sender_profile, sender_char, status").eq("id", id).maybeSingle();
  if (!msg || msg.status !== "review") return json({ skipped: true });
  const release = (status: "ok" | "deleted", reason?: string) =>
    admin.from("chat_messages").update(status === "ok" ? { status } : { status, deleted_at: new Date().toISOString(), deleted_reason: "ai: " + (reason || "") })
      .eq("id", id).eq("status", "review");
  if (!client) { await release("ok"); return json({ allow: true, off: true }); }
  const t0 = Date.now();
  try {
    const a = await ask([{ type: "text", text: GUARD }], [{ role: "user", content: "Channel: " + msg.channel + "\nMessage: " + msg.body }], 1500, "low");
    let allow = true, reason = "";
    try { const j = JSON.parse((a.text.match(/\{[\s\S]*\}/) || ["{}"])[0]); allow = j.allow !== false; reason = String(j.reason || ""); } catch (_e) { allow = true; }
    if (a.refusal) allow = true;   // fail-open
    await release(allow ? "ok" : "deleted", reason);
    if (!allow) await admin.from("ai_log").insert({ kind: "chat", profile_id: msg.sender_profile, character_id: msg.sender_char, ref: String(id),
      input: msg.body, output: reason, verdict: "blocked", tokens_in: a.usage.input_tokens ?? null, tokens_out: a.usage.output_tokens ?? null, ms: Date.now() - t0 });
    return json({ allow, reason });
  } catch (e) {
    await release("ok");   // fail-open
    await admin.from("ai_log").insert({ kind: "chat", ref: String(id), output: String(e).slice(0, 500), verdict: "error", ms: Date.now() - t0 });
    return json({ allow: true, error: true });
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method" }, 405);
  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch (_e) { return json({ error: "bad_json" }, 400); }
  const action = String(body.action || "");
  if (action === "nixie") return nixie(req, body);
  // triage och chatguard anropas bara av databasen (pg_net) med den hemliga token
  const ok = await admin.rpc("ai_hook_ok", { p_token: req.headers.get("x-ai-token") || "" });
  if (ok.error || ok.data !== true) return json({ error: "forbidden" }, 403);
  if (action === "triage") return triage();
  if (action === "chatguard") return chatguard(body);
  return json({ error: "unknown_action" }, 400);
});
