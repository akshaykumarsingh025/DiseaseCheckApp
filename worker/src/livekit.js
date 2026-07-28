import { AccessToken } from "livekit-server-sdk";
import { error, json, withinRateLimit } from "./http.js";

function csv(value) {
  return (value || "")
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);
}

/**
 * Decides whether this participant gets `roomAdmin` — the grant that lets
 * someone kick participants and end the room.
 *
 * Preference order:
 *   1. DOCTOR_EMAILS — matched against the token's *verified* email claim.
 *      This mirrors how the app itself identifies the doctor
 *      (`DoctorAccountService.isDoctorEmail`), so there is no UID to look up.
 *   2. DOCTOR_UIDS — matched against the Firebase UID, if you'd rather pin
 *      exact accounts.
 *   3. Neither set — fall back to the client's own `isModerator` flag, which
 *      is what the old Firebase callable did. Insecure, but preserved so the
 *      migration alone changes no behaviour.
 */
function resolveModerator(env, auth, body) {
  const doctorEmails = csv(env.DOCTOR_EMAILS).map((e) => e.toLowerCase());
  if (doctorEmails.length > 0) {
    const email = String(auth.claims?.email || "").toLowerCase();
    // An unverified email is attacker-controlled until Firebase confirms it,
    // so it must never grant privileges.
    const verified = auth.claims?.email_verified === true;
    return verified && doctorEmails.includes(email);
  }

  const doctorUids = csv(env.DOCTOR_UIDS);
  if (doctorUids.length > 0) {
    return doctorUids.includes(auth.uid);
  }

  return body?.isModerator === true;
}

/**
 * Mints a short-lived LiveKit access token.
 *
 * Port of the `getLiveKitToken` Firebase callable. The API secret stays in
 * Worker secrets and never reaches the shipped APK.
 */
export async function handleLiveKitToken(request, env, auth) {
  if (!env.LIVEKIT_API_KEY || !env.LIVEKIT_API_SECRET) {
    return error(
      request,
      env,
      500,
      "LiveKit credentials are not configured on the server.",
    );
  }

  if (!(await withinRateLimit(env.TOKEN_RATE_LIMITER, auth.uid))) {
    return error(
      request,
      env,
      429,
      "Too many join attempts. Please wait a moment and try again.",
    );
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return error(request, env, 400, "Request body must be JSON.");
  }

  const roomName = String(body?.roomName ?? "").trim();
  const participantName = String(body?.participantName ?? "").trim();
  const participantIdentity = String(body?.participantIdentity ?? "").trim();

  if (!roomName || !participantIdentity) {
    return error(
      request,
      env,
      400,
      "roomName and participantIdentity are required.",
    );
  }

  const isModerator = resolveModerator(env, auth, body);

  const at = new AccessToken(env.LIVEKIT_API_KEY, env.LIVEKIT_API_SECRET, {
    identity: participantIdentity,
    name: participantName || participantIdentity,
    ttl: "1h",
    metadata: JSON.stringify({
      name: participantName,
      isModerator,
      uid: auth.uid,
    }),
  });

  at.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
    roomAdmin: isModerator,
  });

  const token = await at.toJwt();
  return json(request, env, 200, { token });
}
