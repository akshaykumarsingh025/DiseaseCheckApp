import { error, passthrough, withinRateLimit } from "./http.js";

// Fields we are willing to forward. Building a clean payload beats forwarding
// the client's body verbatim: an unknown field can't be used to steer our Groq
// account somewhere expensive.
const ALLOWED_FIELDS = [
  "messages",
  "temperature",
  "top_p",
  "stop",
  "stream",
  "response_format",
  "presence_penalty",
  "frequency_penalty",
];

// Guards the shared Groq quota against a single oversized prompt.
const MAX_BODY_BYTES = 128 * 1024;

/**
 * Proxies an OpenAI-shaped chat completion to Groq, injecting the API key
 * server-side. The key never ships in the app.
 */
export async function handleGroqChat(request, env, auth) {
  if (!env.GROQ_API_KEY) {
    return error(
      request,
      env,
      500,
      "AI is not configured on the server.",
    );
  }

  if (!(await withinRateLimit(env.AI_RATE_LIMITER, auth.uid))) {
    return error(
      request,
      env,
      429,
      "You're sending requests too quickly. Please wait a moment.",
    );
  }

  const raw = await request.text();
  if (raw.length > MAX_BODY_BYTES) {
    return error(request, env, 413, "Prompt is too large.");
  }

  let body;
  try {
    body = JSON.parse(raw);
  } catch {
    return error(request, env, 400, "Request body must be JSON.");
  }

  if (!Array.isArray(body?.messages) || body.messages.length === 0) {
    return error(request, env, 400, "messages must be a non-empty array.");
  }

  const allowedModels = (env.GROQ_ALLOWED_MODELS || "")
    .split(",")
    .map((m) => m.trim())
    .filter(Boolean);
  const requestedModel = String(body.model ?? "").trim();
  // Fall back to the first allowed model when the client doesn't ask for one.
  const model = requestedModel || allowedModels[0];

  if (!model) {
    return error(request, env, 500, "No AI model is configured on the server.");
  }
  if (allowedModels.length > 0 && !allowedModels.includes(model)) {
    return error(request, env, 400, `Model '${model}' is not allowed.`);
  }

  const payload = { model };
  for (const field of ALLOWED_FIELDS) {
    if (body[field] !== undefined) payload[field] = body[field];
  }

  // Hard ceiling on output length regardless of what the client asked for.
  const ceiling = Number.parseInt(env.GROQ_MAX_TOKENS || "8192", 10);
  const requested = Number.parseInt(body.max_tokens, 10);
  payload.max_tokens = Number.isFinite(requested)
    ? Math.min(requested, ceiling)
    : ceiling;

  const baseUrl = (env.GROQ_BASE_URL || "https://api.groq.com/openai/v1")
    .replace(/\/+$/, "");

  let upstream;
  try {
    upstream = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
  } catch (err) {
    return error(
      request,
      env,
      502,
      "AI service is unreachable. Please try again.",
    );
  }

  // Stream the response straight through — this also keeps `stream: true`
  // working, and means we spend wall-clock time waiting on I/O rather than CPU.
  return passthrough(request, env, upstream);
}
