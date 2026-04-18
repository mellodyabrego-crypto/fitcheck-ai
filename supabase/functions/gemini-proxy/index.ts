// Supabase Edge Function — Gemini proxy.
// Runs on Deno Deploy. Keeps the Gemini API key server-side so the browser never sees it.
//
// Deploy:
//   npx supabase functions deploy gemini-proxy --no-verify-jwt \
//       --project-ref fgwrnlibomamlzbzibol
//
// Set the secret:
//   npx supabase secrets set GEMINI_API_KEY=<new-key> --project-ref fgwrnlibomamlzbzibol
//
// Client usage:
//   POST https://fgwrnlibomamlzbzibol.supabase.co/functions/v1/gemini-proxy
//   Body: { "model": "gemini-2.0-flash", "contents": [ ... ] }
//   Header: Authorization: Bearer <SUPABASE_ANON_KEY>

// deno-lint-ignore-file
// @ts-ignore Deno global is provided by the runtime
declare const Deno: { env: { get(name: string): string | undefined }; serve: (handler: (req: Request) => Response | Promise<Response>) => void };

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "GEMINI_API_KEY not configured on server" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const model = (body.model as string | undefined) ?? "gemini-2.5-flash";
  if (!body.contents) {
    return new Response(JSON.stringify({ error: "Missing 'contents' field" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Forward everything EXCEPT the model field (which becomes the URL path)
  const { model: _model, ...forwardBody } = body;

  const upstream = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(forwardBody),
    },
  );

  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
