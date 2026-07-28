import { createRemoteJWKSet, jwtVerify } from "jose";

/**
 * Verifies Firebase Auth ID tokens.
 *
 * The Firebase callable this replaced got `request.auth` for free. Off-platform
 * we do the same check by hand: Firebase ID tokens are ordinary RS256 JWTs
 * signed by Google, so we validate the signature against Google's published
 * JWKS and then assert the issuer/audience belong to *our* project.
 *
 * `firebase-admin` is deliberately not used here — it depends on Node APIs that
 * do not exist on the Workers runtime.
 */

const JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";

// Cached per isolate. jose handles refetching when it sees an unknown `kid`,
// with `cooldownDuration` preventing a stampede against Google.
let jwks;

function getJwks() {
  if (!jwks) {
    jwks = createRemoteJWKSet(new URL(JWKS_URL), {
      cooldownDuration: 30_000,
      cacheMaxAge: 600_000,
    });
  }
  return jwks;
}

export class AuthError extends Error {
  constructor(message) {
    super(message);
    this.name = "AuthError";
  }
}

/**
 * Extracts and verifies the bearer token on a request.
 *
 * @returns {Promise<{uid: string, email: string|undefined, claims: object}>}
 * @throws {AuthError} when the header is missing or the token does not verify.
 */
export async function verifyFirebaseToken(request, projectId) {
  const header = request.headers.get("Authorization") || "";
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  if (!match) {
    throw new AuthError("Missing Authorization: Bearer <Firebase ID token>");
  }

  const projectIdTrimmed = (projectId || "").trim();
  if (!projectIdTrimmed) {
    // Misconfiguration, not a client problem — but failing closed is the only
    // safe option, since without an audience to pin we would accept ID tokens
    // minted for any other Firebase project.
    throw new AuthError("Server is missing FIREBASE_PROJECT_ID");
  }

  let payload;
  try {
    ({ payload } = await jwtVerify(match[1], getJwks(), {
      algorithms: ["RS256"],
      issuer: `https://securetoken.google.com/${projectIdTrimmed}`,
      audience: projectIdTrimmed,
      // Small tolerance so a device with slightly fast clock isn't locked out.
      clockTolerance: 60,
    }));
  } catch (err) {
    throw new AuthError(`Invalid or expired session (${err.code || err.name})`);
  }

  // `sub` is the Firebase UID. jose already enforced exp/nbf/iss/aud.
  const uid = typeof payload.sub === "string" ? payload.sub.trim() : "";
  if (!uid) {
    throw new AuthError("Token has no subject");
  }

  // auth_time is when the user actually authenticated; a token claiming a
  // future sign-in is malformed.
  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.auth_time === "number" && payload.auth_time > now + 60) {
    throw new AuthError("Token auth_time is in the future");
  }

  return { uid, email: payload.email, claims: payload };
}
