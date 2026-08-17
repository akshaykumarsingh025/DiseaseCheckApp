import { SignJWT, importPKCS8 } from "jose";

/**
 * Minimal Firestore REST client for the Worker.
 *
 * Only used to record entitlements the Worker itself has verified. The Flutter
 * app talks to Firestore directly with the user's own credentials for
 * everything else — this exists purely so a purchase record can be written by
 * something the user cannot impersonate.
 *
 * `firebase-admin` is not usable here (Node-only APIs), so we mint an OAuth
 * access token from the service account by hand, the same way the LiveKit token
 * is minted in livekit.js.
 */

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const SCOPE = "https://www.googleapis.com/auth/datastore";

// Cached per isolate. Google issues these for an hour; we refresh a minute
// early so an in-flight request never races the expiry.
let cachedToken = null;

export class FirestoreError extends Error {
  constructor(message) {
    super(message);
    this.name = "FirestoreError";
  }
}

function parseServiceAccount(env) {
  const raw = env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) return null;

  let parsed;
  try {
    parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
  } catch {
    throw new FirestoreError("FIREBASE_SERVICE_ACCOUNT is not valid JSON.");
  }

  const clientEmail = parsed.client_email;
  // Secrets set through the shell often arrive with the newlines escaped.
  const privateKey = String(parsed.private_key || "").replace(/\\n/g, "\n");

  if (!clientEmail || !privateKey) {
    throw new FirestoreError(
      "FIREBASE_SERVICE_ACCOUNT needs client_email and private_key.",
    );
  }
  return { clientEmail, privateKey };
}

/** True when the Worker is configured to write entitlements itself. */
export function canWriteFirestore(env) {
  return Boolean(env.FIREBASE_SERVICE_ACCOUNT);
}

async function getAccessToken(env) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return cachedToken.value;
  }

  const account = parseServiceAccount(env);
  if (!account) {
    throw new FirestoreError("FIREBASE_SERVICE_ACCOUNT is not set.");
  }

  const key = await importPKCS8(account.privateKey, "RS256");
  const assertion = await new SignJWT({ scope: SCOPE })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.clientEmail)
    .setAudience(TOKEN_URL)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    throw new FirestoreError(
      `Could not mint a Google access token (${response.status}).`,
    );
  }

  const body = await response.json();
  if (!body.access_token) {
    throw new FirestoreError("Google returned no access_token.");
  }

  cachedToken = {
    value: body.access_token,
    expiresAt: now + (Number(body.expires_in) || 3600),
  };
  return cachedToken.value;
}

/** Wraps a JS value in Firestore's typed-value envelope. */
function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  return { stringValue: String(value) };
}

function toFirestoreFields(data) {
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    fields[key] = toFirestoreValue(value);
  }
  return fields;
}

/**
 * Creates a document at `users/{uid}/purchases/{documentId}`.
 *
 * `documentId` is the Razorpay payment ID, which makes the write idempotent:
 * replaying the same verified payment overwrites one record instead of
 * granting the entitlement twice.
 */
export async function writePurchase(env, uid, documentId, data) {
  const projectId = (env.FIREBASE_PROJECT_ID || "").trim();
  if (!projectId) {
    throw new FirestoreError("FIREBASE_PROJECT_ID is not set.");
  }

  const token = await getAccessToken(env);
  const path = `projects/${projectId}/databases/(default)/documents/users/${encodeURIComponent(
    uid,
  )}/purchases/${encodeURIComponent(documentId)}`;

  const response = await fetch(`https://firestore.googleapis.com/v1/${path}`, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields: toFirestoreFields(data) }),
  });

  if (!response.ok) {
    const detail = await response.text();
    throw new FirestoreError(
      `Firestore write failed (${response.status}): ${detail.slice(0, 200)}`,
    );
  }
}
