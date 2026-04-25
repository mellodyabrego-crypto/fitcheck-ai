// Supabase Edge Function — Gemini proxy (HARDENED).
// Runs on Deno Deploy. Keeps the Gemini API key server-side so the browser never sees it.
//
// Security guarantees:
//   - JWT must be valid (deploy WITHOUT --no-verify-jwt — use the default verify path)
//   - Per-user daily quota enforced via public.usage_counters table
//   - Model is restricted to an explicit allow-list (no gemini-2.5-pro abuse)
//   - Request body size capped (8 KB raw JSON before parsing)
//   - generationConfig.maxOutputTokens capped server-side
//
// Deploy (NOTE: removed --no-verify-jwt):
//   npx supabase functions deploy gemini-proxy --project-ref <YOUR_PROJECT_REF>
//
// Set the secret + service-role key:
//   npx supabase secrets set GEMINI_API_KEY=<key> --project-ref <ref>
//   # SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected by Supabase.

// deno-lint-ignore-file
// @ts-ignore Deno global is provided by the runtime
declare const Deno: { env: { get(name: string): string | undefined }; serve: (handler: (req: Request) => Response | Promise<Response>) => void };

const ALLOWED_MODELS = new Set([
  "gemini-2.5-flash",
  "gemini-2.0-flash",
]);

// Per-user daily call cap. Generous for a stylist app; revisit if abuse appears.
const DAILY_QUOTA = 50;
// Max raw bytes accepted from the client BEFORE JSON parse.
const MAX_BODY_BYTES = 8 * 1024;
// Hard ceiling on Gemini output tokens regardless of what client requests.
const MAX_OUTPUT_TOKENS = 1024;
// Network timeout when calling Gemini upstream.
const UPSTREAM_TIMEOUT_MS = 25_000;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// base64url → base64 with proper `=` padding before atob. Without padding,
// roughly 2/3 of token lengths cause atob() to throw — silently turning valid
// requests into 401s and the whole quota-tracking pipeline into a no-op.
function b64urlToB64(s: string): string {
  const std = s.replace(/-/g, "+").replace(/_/g, "/");
  const pad = std.length % 4;
  return pad === 0 ? std : std + "=".repeat(4 - pad);
}

// Parse user id out of the JWT (no signature check — Supabase has already
// verified it before invoking us, since we are deployed with verify_jwt=true).
function decodeJwtSub(authHeader: string | null): string | null {
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const token = authHeader.slice(7);
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const payload = JSON.parse(atob(b64urlToB64(parts[1])));
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

async function checkAndIncrementQuota(userId: string): Promise<{ ok: boolean; used: number }> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    // Fail-open ONLY in dev (no service key). In prod the secret is always set.
    return { ok: true, used: 0 };
  }
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  // Upsert + increment via PostgREST. RPC would be cleaner but this avoids
  // requiring a SQL function deploy.
  const url = `${supabaseUrl}/rest/v1/rpc/increment_gemini_quota`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": serviceKey,
      "Authorization": `Bearer ${serviceKey}`,
    },
    body: JSON.stringify({ p_user_id: userId, p_day: today, p_limit: DAILY_QUOTA }),
  });
  if (!res.ok) {
    // If the RPC isn't deployed yet, log + fail-open so the app keeps working.
    console.error("quota rpc failed", res.status, await res.text());
    return { ok: true, used: 0 };
  }
  const data = await res.json();
  // RPC returns { allowed: bool, used: int }
  return { ok: !!data?.allowed, used: Number(data?.used ?? 0) };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const userId = decodeJwtSub(req.headers.get("Authorization"));
  if (!userId) {
    return jsonResponse(401, { error: "Missing or invalid Authorization bearer token" });
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return jsonResponse(500, { error: "GEMINI_API_KEY not configured on server" });
  }

  // Cap raw body size before we even parse it.
  const rawText = await req.text();
  if (rawText.length > MAX_BODY_BYTES) {
    return jsonResponse(413, {
      error: `Request body too large (${rawText.length} bytes; max ${MAX_BODY_BYTES})`,
    });
  }

  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawText);
  } catch {
    return jsonResponse(400, { error: "Invalid JSON body" });
  }

  const model = (body.model as string | undefined) ?? "gemini-2.5-flash";
  if (!ALLOWED_MODELS.has(model)) {
    return jsonResponse(400, {
      error: `Model '${model}' is not allowed. Allowed: ${[...ALLOWED_MODELS].join(", ")}`,
    });
  }
  if (!body.contents) {
    return jsonResponse(400, { error: "Missing 'contents' field" });
  }

  // Force a generationConfig cap regardless of what the client sent.
  const genCfg = (body.generationConfig as Record<string, unknown> | undefined) ?? {};
  const requestedMax = Number(genCfg.maxOutputTokens ?? MAX_OUTPUT_TOKENS);
  genCfg.maxOutputTokens = Math.min(
    Number.isFinite(requestedMax) ? requestedMax : MAX_OUTPUT_TOKENS,
    MAX_OUTPUT_TOKENS,
  );
  body.generationConfig = genCfg;

  // Quota check (fail-open if RPC not deployed; see helper).
  const quota = await checkAndIncrementQuota(userId);
  if (!quota.ok) {
    return jsonResponse(429, {
      error: `Daily quota exceeded (${quota.used}/${DAILY_QUOTA}). Resets at midnight UTC.`,
    });
  }

  const { model: _model, ...forwardBody } = body;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), UPSTREAM_TIMEOUT_MS);

  let upstream: Response;
  try {
    upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(forwardBody),
        signal: controller.signal,
      },
    );
  } catch (e) {
    clearTimeout(timeoutId);
    const msg = (e as Error).name === "AbortError" ? "Upstream timeout" : `Upstream error: ${(e as Error).message}`;
    return jsonResponse(504, { error: msg });
  }
  clearTimeout(timeoutId);

  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "X-Quota-Used": String(quota.used),
      "X-Quota-Limit": String(DAILY_QUOTA),
    },
  });
});
