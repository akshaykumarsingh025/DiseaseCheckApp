import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { AccessToken } from "livekit-server-sdk";

initializeApp();

// Secrets are stored in Google Secret Manager, never in source.
// Set them with:
//   firebase functions:secrets:set LIVEKIT_API_KEY
//   firebase functions:secrets:set LIVEKIT_API_SECRET
const LIVEKIT_API_KEY = defineSecret("LIVEKIT_API_KEY");
const LIVEKIT_API_SECRET = defineSecret("LIVEKIT_API_SECRET");

/**
 * Callable function that mints a short-lived LiveKit access token.
 *
 * The client sends the room name, its display name, identity and whether it
 * is the moderator (doctor). The API secret never leaves the server, so it
 * can no longer be extracted from the shipped APK.
 */
export const getLiveKitToken = onCall(
  {
    region: "us-central1",
    secrets: [LIVEKIT_API_KEY, LIVEKIT_API_SECRET],
  },
  async (request) => {
    // Require an authenticated Firebase user.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to join a video call.",
      );
    }

    const roomName = (request.data?.roomName ?? "").toString().trim();
    const participantName = (request.data?.participantName ?? "").toString().trim();
    const participantIdentity = (request.data?.participantIdentity ?? "").toString().trim();
    const isModerator = request.data?.isModerator === true;

    if (!roomName || !participantIdentity) {
      throw new HttpsError(
        "invalid-argument",
        "roomName and participantIdentity are required.",
      );
    }

    const at = new AccessToken(
      LIVEKIT_API_KEY.value(),
      LIVEKIT_API_SECRET.value(),
      {
        identity: participantIdentity,
        name: participantName || participantIdentity,
        // Token valid for 1 hour.
        ttl: "1h",
        metadata: JSON.stringify({
          name: participantName,
          isModerator,
          uid: request.auth.uid,
        }),
      },
    );

    at.addGrant({
      room: roomName,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
      // Only the doctor/moderator may administer the room.
      roomAdmin: isModerator,
    });

    const token = await at.toJwt();
    return { token };
  },
);
