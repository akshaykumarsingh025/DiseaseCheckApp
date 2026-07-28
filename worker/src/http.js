/** Small helpers shared by the route handlers. */

function corsHeaders(request, env) {
  const origin = request.headers.get("Origin");
  // The Flutter mobile app sends no Origin header, so it never needs CORS.
  // Only the web build does, and only for origins we explicitly allow.
  if (!origin) return {};

  const allowed = (env.ALLOWED_ORIGINS || "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);

  if (!allowed.includes(origin)) return {};

  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

export function json(request, env, status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...corsHeaders(request, env),
    },
  });
}

export function error(request, env, status, message) {
  return json(request, env, status, { error: { message } });
}

export function preflight(request, env) {
  return new Response(null, { status: 204, headers: corsHeaders(request, env) });
}

export function passthrough(request, env, upstream) {
  const headers = new Headers(corsHeaders(request, env));
  const contentType = upstream.headers.get("Content-Type");
  if (contentType) headers.set("Content-Type", contentType);
  headers.set("Cache-Control", "no-store");
  return new Response(upstream.body, { status: upstream.status, headers });
}

/**
 * Applies a Cloudflare rate-limit binding, keyed per user.
 *
 * Returns true when the request may proceed. If the binding is absent (e.g. a
 * local `wrangler dev` run without the unsafe binding) we fail open rather than
 * bricking the endpoint.
 */
export async function withinRateLimit(limiter, key) {
  if (!limiter || typeof limiter.limit !== "function") return true;
  try {
    const { success } = await limiter.limit({ key });
    return success;
  } catch {
    return true;
  }
}
