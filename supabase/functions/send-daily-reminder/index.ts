// Supabase Edge Function — send-daily-reminder.
//
// Fires every minute via pg_cron (see 20260425_device_tokens_and_reminder_cron.sql).
// Finds every user whose:
//   * notifications_enabled = true
//   * notification_time matches the current UTC minute (HH:MM)
//   * deleted_at is null
// And sends a Firebase Cloud Messaging push to every token registered in
// device_tokens for that user.
//
// FCM is contacted via the v1 HTTP API (oauth2 service-account flow). The
// service account JSON must be split into FCM_PROJECT_ID / FCM_CLIENT_EMAIL /
// FCM_PRIVATE_KEY edge-function secrets — see HANDOFF.md.
//
// Failure modes:
//   * No FCM secrets → function early-exits (logs a warning, returns 200 so
//     the cron retry loop doesn't spam errors).
//   * Token returns UNREGISTERED → token is deleted from device_tokens.
//   * Other FCM errors are logged but don't crash the run.

// deno-lint-ignore-file
declare const Deno: {
  env: { get(name: string): string | undefined };
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const REMINDER_TITLE = "Today’s look is ready";
const REMINDER_BODY =
  "Open Her Style Co. for an outfit picked for today’s weather and your style.";

interface ServiceAccount {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

function loadServiceAccount(): ServiceAccount | null {
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL");
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY");
  if (!projectId || !clientEmail || !privateKey) return null;
  // Replace literal \n with real newlines (Supabase secret store stores
  // multi-line values with literal \n if pasted as a single line).
  return {
    projectId,
    clientEmail,
    privateKey: privateKey.replace(/\\n/g, "\n"),
  };
}

// Mint a Google OAuth2 access token from a service account JWT.
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const claim = btoa(
    JSON.stringify({
      iss: sa.clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    }),
  )
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const toSign = new TextEncoder().encode(`${header}.${claim}`);

  // Import the PEM-formatted private key
  const pem = sa.privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, toSign);
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const jwt = `${header}.${claim}.${sig}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`oauth2 ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token as string;
}

async function sendFcm(
  sa: ServiceAccount,
  accessToken: string,
  token: string,
): Promise<{ ok: boolean; status: number; body: string }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: REMINDER_TITLE,
            body: REMINDER_BODY,
          },
          webpush: {
            fcm_options: {
              link: "https://her-style-co.pages.dev",
            },
          },
        },
      }),
    },
  );
  return { ok: res.ok, status: res.status, body: await res.text() };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse(500, { error: "missing supabase env" });
  }

  const sa = loadServiceAccount();
  if (!sa) {
    console.warn(
      "FCM secrets not set — daily reminders are inert. Set FCM_PROJECT_ID, " +
        "FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY in Edge Function secrets.",
    );
    return jsonResponse(200, {
      sent: 0,
      reason: "fcm_not_configured",
    });
  }

  // We match each user against THEIR local clock (Intl.DateTimeFormat with
  // their IANA TZ), not the UTC clock. This keeps reminders WYSIWYG across
  // DST and keeps the picker in user-local time. Pre-compute UTC HH:MM as a
  // fallback for users with no notification_tz stored (legacy rows).
  const now = new Date();
  const utcHh = String(now.getUTCHours()).padStart(2, "0");
  const utcMm = String(now.getUTCMinutes()).padStart(2, "0");
  const utcMatchTime = `${utcHh}:${utcMm}`;

  // Local HH:MM in a given IANA TZ. Returns null if the TZ is invalid.
  function localHHMM(tz: string): string | null {
    try {
      const fmt = new Intl.DateTimeFormat("en-US", {
        timeZone: tz,
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
      });
      const parts = fmt.formatToParts(now);
      const h = parts.find((p) => p.type === "hour")?.value ?? "";
      const m = parts.find((p) => p.type === "minute")?.value ?? "";
      // Intl can emit "24" for midnight in some locales — normalise to "00".
      const hh = h === "24" ? "00" : h.padStart(2, "0");
      const mm = m.padStart(2, "0");
      if (hh.length !== 2 || mm.length !== 2) return null;
      return `${hh}:${mm}`;
    } catch {
      return null;
    }
  }

  // Fetch eligible users + their tokens.
  const sb = (path: string, init?: RequestInit) =>
    fetch(`${supabaseUrl}/rest/v1/${path}`, {
      ...(init ?? {}),
      headers: {
        ...(init?.headers ?? {}),
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
    });

  // Pull all users with notifications enabled — we filter per-row in code
  // because the match depends on each user's TZ. Ok up to ~10k users; chunk
  // by `id > last_id` cursors when this gets larger.
  const usersRes = await sb(
    `user_profiles?notifications_enabled=eq.true&deleted_at=is.null` +
      `&select=user_id,notification_time,notification_tz`,
  );
  if (!usersRes.ok) {
    return jsonResponse(502, { error: "user query failed" });
  }
  const allUsers: {
    user_id: string;
    notification_time: string | null;
    notification_tz: string | null;
  }[] = await usersRes.json();

  const users = allUsers.filter((u) => {
    if (!u.notification_time) return false;
    const tz = u.notification_tz;
    const matchAgainst = tz ? localHHMM(tz) : utcMatchTime;
    return matchAgainst === u.notification_time;
  });
  if (users.length === 0) {
    return jsonResponse(200, { sent: 0, matched: 0, scanned: allUsers.length });
  }

  const userIds = users.map((u) => u.user_id);
  const tokensRes = await sb(
    `device_tokens?user_id=in.(${userIds.join(",")})&select=user_id,token`,
  );
  if (!tokensRes.ok) {
    return jsonResponse(502, { error: "token query failed" });
  }
  const tokens: { user_id: string; token: string }[] = await tokensRes.json();
  if (tokens.length === 0) {
    return jsonResponse(200, { sent: 0, matched: users.length });
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(sa);
  } catch (e) {
    console.error("oauth2 mint failed", e);
    return jsonResponse(500, { error: String(e) });
  }

  let sent = 0;
  let removed = 0;
  for (const t of tokens) {
    try {
      const r = await sendFcm(sa, accessToken, t.token);
      if (r.ok) {
        sent++;
      } else if (
        r.status === 404 ||
        r.body.includes("UNREGISTERED") ||
        r.body.includes("INVALID_ARGUMENT")
      ) {
        // Token is dead — purge it.
        await sb(
          `device_tokens?user_id=eq.${t.user_id}&token=eq.${
            encodeURIComponent(t.token)
          }`,
          { method: "DELETE" },
        );
        removed++;
      } else {
        console.error("fcm send failed", r.status, r.body);
      }
    } catch (e) {
      console.error("send error", e);
    }
  }

  return jsonResponse(200, {
    matched: users.length,
    tokens: tokens.length,
    sent,
    removed,
  });
});
