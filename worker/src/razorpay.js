import { error, json, withinRateLimit } from "./http.js";
import { canWriteFirestore, writePurchase } from "./firestore.js";

/**
 * Razorpay order creation and payment verification.
 *
 * Why this exists: Razorpay's client-side checkout alone proves nothing. The
 * app's success callback is just a function call inside an APK an attacker
 * controls, so a patched build can invoke it without paying. The only thing
 * that actually proves a payment happened is the HMAC signature Razorpay
 * returns, checked against the key SECRET — and the secret can never ship in
 * the app. Hence: orders are created here, and payments are verified here.
 *
 *   POST /razorpay/order  { feature }                        -> { orderId, ... }
 *   POST /razorpay/verify { orderId, paymentId, signature }  -> { verified }
 */

const API_BASE = "https://api.razorpay.com/v1";

/**
 * Server-side price list, in rupees. This is the authoritative one — the client
 * never sends an amount, because a client that can name its own price can name
 * ₹1. `PaymentService` in the app keeps matching constants purely to render the
 * button label; if the two ever disagree, this file wins and the user is
 * charged what it says.
 *
 * `removeAds` is deliberately absent. Google Play requires an ad-free upgrade
 * to be sold through Play Billing, so it must never be purchasable here — and
 * enforcing that server-side means a stale client build cannot bypass it.
 */
const FEATURES = {
  opdConsult: { rupees: 111, label: "Online OPD Consultation" },
};

function credentials(env) {
  const keyId = (env.RAZORPAY_KEY_ID || "").trim();
  const keySecret = (env.RAZORPAY_KEY_SECRET || "").trim();
  if (!keyId || !keySecret) return null;
  return { keyId, keySecret, basic: btoa(`${keyId}:${keySecret}`) };
}

async function hmacSha256Hex(secret, message) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(message),
  );
  return [...new Uint8Array(signature)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Compares two hex digests without leaking where they first differ. A plain
 * `===` on a secret-derived value returns fractionally sooner on an early
 * mismatch, which is enough to brute-force a signature byte by byte.
 */
function timingSafeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

/** POST /razorpay/order — creates an order bound to the calling user. */
export async function handleRazorpayOrder(request, env, auth) {
  const creds = credentials(env);
  if (!creds) {
    return error(
      request,
      env,
      500,
      "Payments are not configured on the server.",
    );
  }

  if (!(await withinRateLimit(env.TOKEN_RATE_LIMITER, auth.uid))) {
    return error(
      request,
      env,
      429,
      "Too many payment attempts. Please wait a moment and try again.",
    );
  }

  const body = await readJson(request);
  if (!body) return error(request, env, 400, "Request body must be JSON.");

  const feature = String(body.feature ?? "").trim();
  const priced = FEATURES[feature];
  if (!priced) {
    return error(request, env, 400, "Unknown or unavailable product.");
  }

  const amountPaise = priced.rupees * 100;

  const response = await fetch(`${API_BASE}/orders`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${creds.basic}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: "INR",
      // Truncated because Razorpay caps receipts at 40 characters.
      receipt: `${feature}_${Date.now()}`.slice(0, 40),
      // These notes are what bind the order to one user. /verify refuses any
      // payment whose order was created for somebody else, so a captured
      // order/payment/signature triple cannot be replayed on another account.
      notes: { uid: auth.uid, feature },
    }),
  });

  if (!response.ok) {
    const detail = await response.text();
    console.error("Razorpay order creation failed:", response.status, detail);
    return error(
      request,
      env,
      502,
      "Could not start the payment. Please try again.",
    );
  }

  const order = await response.json();
  return json(request, env, 200, {
    orderId: order.id,
    amount: order.amount,
    currency: order.currency,
    // The Key ID is public by design — Razorpay checkout sends it from the
    // client on every payment. Returning it here means the app does not need a
    // hardcoded copy that could drift from whatever the server is using.
    keyId: creds.keyId,
    feature,
    description: priced.label,
  });
}

/** POST /razorpay/verify — proves a payment really happened, then records it. */
export async function handleRazorpayVerify(request, env, auth) {
  const creds = credentials(env);
  if (!creds) {
    return error(
      request,
      env,
      500,
      "Payments are not configured on the server.",
    );
  }

  const body = await readJson(request);
  if (!body) return error(request, env, 400, "Request body must be JSON.");

  const orderId = String(body.orderId ?? "").trim();
  const paymentId = String(body.paymentId ?? "").trim();
  const signature = String(body.signature ?? "").trim().toLowerCase();

  if (!orderId || !paymentId || !signature) {
    return error(
      request,
      env,
      400,
      "orderId, paymentId and signature are required.",
    );
  }

  // 1. The signature must be one only Razorpay could have produced, because
  //    only Razorpay and this Worker know the key secret.
  const expected = await hmacSha256Hex(
    creds.keySecret,
    `${orderId}|${paymentId}`,
  );
  if (!timingSafeEqual(expected, signature)) {
    console.warn(`Signature mismatch for order ${orderId} (uid ${auth.uid})`);
    return json(request, env, 400, {
      verified: false,
      error: { message: "Payment could not be verified." },
    });
  }

  // 2. A valid signature proves the payment is real, not that it was this
  //    user's or that money actually moved. Ask Razorpay directly.
  const orderResponse = await fetch(`${API_BASE}/orders/${orderId}`, {
    headers: { Authorization: `Basic ${creds.basic}` },
  });
  if (!orderResponse.ok) {
    console.error("Razorpay order lookup failed:", orderResponse.status);
    return error(
      request,
      env,
      502,
      "Could not confirm the payment. Please try again.",
    );
  }

  const order = await orderResponse.json();
  const feature = String(order.notes?.feature ?? "");
  const priced = FEATURES[feature];

  if (order.notes?.uid !== auth.uid) {
    console.warn(`Order ${orderId} belongs to ${order.notes?.uid}, not ${auth.uid}`);
    return json(request, env, 403, {
      verified: false,
      error: { message: "This payment belongs to a different account." },
    });
  }

  if (order.status !== "paid") {
    return json(request, env, 400, {
      verified: false,
      error: { message: "Payment has not completed." },
    });
  }

  if (!priced || order.amount !== priced.rupees * 100) {
    console.warn(`Order ${orderId} amount ${order.amount} != expected`);
    return json(request, env, 400, {
      verified: false,
      error: { message: "Payment amount did not match the product." },
    });
  }

  // 3. Record the entitlement from here, where the client cannot forge it.
  let recorded = false;
  if (canWriteFirestore(env)) {
    try {
      await writePurchase(env, auth.uid, paymentId, {
        feature,
        amount: priced.rupees,
        paymentId,
        orderId,
        status: "completed",
        verifiedBy: "worker",
        purchasedAt: new Date(),
      });
      recorded = true;
    } catch (err) {
      // The payment is genuine and the user has been charged, so never fail the
      // request over a bookkeeping problem — the app still unlocks the feature
      // locally and hasPurchased() will pick the record up on a later sync.
      console.error("Could not record verified purchase:", err);
    }
  }

  return json(request, env, 200, {
    verified: true,
    feature,
    amount: priced.rupees,
    recorded,
  });
}
