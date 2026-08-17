import { AuthError, verifyFirebaseToken } from "./firebase-auth.js";
import { error, json, preflight } from "./http.js";
import { handleGroqChat } from "./groq.js";
import { handleLiveKitToken } from "./livekit.js";
import { handleRazorpayOrder, handleRazorpayVerify } from "./razorpay.js";

/**
 * DiseaseCheck API Worker.
 *
 * Holds the LiveKit and Groq credentials so the Flutter app never has to. Every
 * route requires a valid Firebase ID token from project FIREBASE_PROJECT_ID —
 * Firebase Auth and Firestore stay on the free Spark plan, only the secret-
 * holding endpoints moved here.
 *
 *   POST /livekit/token       -> { token }
 *   POST /groq/chat/completions -> OpenAI-shaped completion
 *   POST /razorpay/order      -> { orderId, amount, keyId }
 *   POST /razorpay/verify     -> { verified }
 *   GET  /health              -> { ok: true }   (unauthenticated)
 */

const ROUTES = {
  "/livekit/token": handleLiveKitToken,
  "/groq/chat/completions": handleGroqChat,
  "/razorpay/order": handleRazorpayOrder,
  "/razorpay/verify": handleRazorpayVerify,
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return preflight(request, env);
    }

    if (url.pathname === "/health") {
      // Deliberately reports only whether config is present, never any value.
      return json(request, env, 200, {
        ok: true,
        livekit: Boolean(env.LIVEKIT_API_KEY && env.LIVEKIT_API_SECRET),
        groq: Boolean(env.GROQ_API_KEY),
        project: Boolean(env.FIREBASE_PROJECT_ID),
        razorpay: Boolean(env.RAZORPAY_KEY_ID && env.RAZORPAY_KEY_SECRET),
        // Whether verified purchases can be recorded server-side. False means
        // the app still writes its own purchase records and they are forgeable.
        purchaseWrites: Boolean(env.FIREBASE_SERVICE_ACCOUNT),
      });
    }

    const handler = ROUTES[url.pathname];
    if (!handler) {
      return error(request, env, 404, "Not found.");
    }
    if (request.method !== "POST") {
      return error(request, env, 405, "Method not allowed.");
    }

    let auth;
    try {
      auth = await verifyFirebaseToken(request, env.FIREBASE_PROJECT_ID);
    } catch (err) {
      if (err instanceof AuthError) {
        return error(request, env, 401, err.message);
      }
      throw err;
    }

    try {
      return await handler(request, env, auth);
    } catch (err) {
      // Never leak internals (and never a key) to the client.
      console.error(`${url.pathname} failed:`, err);
      return error(request, env, 500, "Something went wrong. Please try again.");
    }
  },
};
