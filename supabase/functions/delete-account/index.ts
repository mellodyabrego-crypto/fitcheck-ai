// Supabase Edge Function — delete-account.
//
// Soft-deletes a user: bans them via the auth admin API (so they can no longer
// log in) and stamps `deleted_at` on user_profiles. ALL OTHER DATA IS PRESERVED
// for analytics — wardrobe items, outfits, feedback rows stay intact.
//
// Why ban + flag, not actual delete:
//   * Owner explicitly asked to retain data for analytics & data parsing.
//   * Hard-deleting auth.users would cascade to profiles via FK; we want
//     orphaned rows kept in place so business intelligence queries still
//     compute LTV, churn, and cohort stats.
//
// Deploy:
//   npx supabase functions deploy delete-account --project-ref <YOUR_PROJECT_REF>
//
// Required secrets (auto-injected by Supabase):
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY

// deno-lint-ignore-file
// @ts-ignore Deno global provided by runtime
declare const Deno: {
  env: { get(name: string): string | undefined };
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
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
// requests into 401s.
function b64urlToB64(s: string): string {
  const std = s.replace(/-/g, "+").replace(/_/g, "/");
  const pad = std.length % 4;
  return pad === 0 ? std : std + "=".repeat(4 - pad);
}

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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse(500, {
      error: "Server misconfiguration — missing service role key.",
    });
  }

  const userId = decodeJwtSub(req.headers.get("authorization"));
  if (!userId) {
    return jsonResponse(401, { error: "Missing or invalid auth token." });
  }

  // Optional double-confirm token in body. Required to prevent accidental
  // CSRF-style submissions if the JWT ever leaks via XSS.
  let body: any = {};
  try {
    body = await req.json();
  } catch (_) {
    body = {};
  }
  if (body?.confirm !== "DELETE") {
    return jsonResponse(400, {
      error:
        'Pass {"confirm":"DELETE"} in the body to acknowledge this is intentional.',
    });
  }

  // 1. Ban the user via the auth admin API. `ban_duration: "876000h"` ≈ 100yr.
  //    Supabase has no "ban forever" but a 100-year ban is effectively perma.
  const banRes = await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
    },
    body: JSON.stringify({ ban_duration: "876000h" }),
  });
  if (!banRes.ok) {
    return jsonResponse(502, {
      error: `Could not ban user (auth admin returned ${banRes.status}).`,
    });
  }

  // 2. Sign out all active sessions so the in-flight tab is logged out
  //    immediately instead of waiting for token refresh.
  await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}/logout`, {
    method: "POST",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
    },
  }).catch(() => {});

  // 3. Stamp deleted_at on user_profiles (RLS lets the user see this row
  //    until ban kicks in; we use service-role bypass for the actual write).
  const profRes = await fetch(
    `${supabaseUrl}/rest/v1/user_profiles?user_id=eq.${userId}`,
    {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ deleted_at: new Date().toISOString() }),
    },
  );
  if (!profRes.ok) {
    // Profile flag failed but ban succeeded — return partial success.
    // The next nightly job can backfill the flag from the ban record.
    console.error("profile flag failed", profRes.status, await profRes.text());
    return jsonResponse(207, {
      banned: true,
      profile_flagged: false,
      message:
        "Account banned, but profile flag failed. Support can clean up.",
    });
  }

  return jsonResponse(200, {
    banned: true,
    profile_flagged: true,
    message:
      "Account deleted. Wardrobe and history retained per privacy policy.",
  });
});
