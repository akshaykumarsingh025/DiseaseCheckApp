# DiseaseCheck API Worker

Holds the **LiveKit** and **Groq** credentials so the Flutter app never ships them.

Firebase **Auth and Firestore stay on the free Spark plan** — only the two
secret-holding endpoints live here. This replaces the `getLiveKitToken` Cloud
Function (which required the Blaze plan) and the old arrangement where the Groq
key was read out of Firestore and used directly from the device.

## Endpoints

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| `POST` | `/livekit/token` | Firebase ID token | Mints a 1-hour LiveKit access token |
| `POST` | `/groq/chat/completions` | Firebase ID token | Proxies an OpenAI-shaped completion to Groq |
| `GET` | `/health` | none | Reports *whether* each secret is configured (never a value) |

Every authenticated route expects:

```
Authorization: Bearer <Firebase ID token>
```

The Worker verifies that token's RS256 signature against Google's published
JWKS and pins `iss`/`aud` to `FIREBASE_PROJECT_ID`, so tokens from any other
Firebase project are rejected. (`firebase-admin` is intentionally not used — it
depends on Node APIs the Workers runtime does not provide.)

## First-time setup

```bash
cd worker
npm install
npx wrangler login
```

Set the three secrets (these are stored by Cloudflare, never in git):

```bash
npx wrangler secret put LIVEKIT_API_KEY
npx wrangler secret put LIVEKIT_API_SECRET
npx wrangler secret put GROQ_API_KEY
```

Deploy:

```bash
npx wrangler deploy
```

Wrangler prints the deployed URL, e.g.
`https://diseasecheck-api.<your-subdomain>.workers.dev`. Put that value in
`lib/config/backend_config.dart` (or in Firestore `config/api_keys` →
`backend_base_url`, which overrides it without needing an app release).

Verify:

```bash
curl https://diseasecheck-api.<your-subdomain>.workers.dev/health
# {"ok":true,"livekit":true,"groq":true,"project":true}
```

All four must be `true` before the app will work.

## Local development

```bash
cp .dev.vars.example .dev.vars   # fill in the three secrets
npx wrangler dev
```

`.dev.vars` is gitignored. Rate-limit bindings are no-ops locally; the code
fails open when the binding is absent so the endpoints still work.

## Configuration (`wrangler.toml`)

| Var | Meaning |
| --- | --- |
| `FIREBASE_PROJECT_ID` | Pins which project's ID tokens are accepted |
| `GROQ_BASE_URL` | Groq's OpenAI-compatible base URL |
| `GROQ_ALLOWED_MODELS` | Allowlist; a client requesting anything else gets a 400 |
| `GROQ_MAX_TOKENS` | Hard ceiling on `max_tokens`, applied over the client's value |
| `ALLOWED_ORIGINS` | CORS allowlist — only relevant to the Flutter **web** build; mobile sends no `Origin` |
| `DOCTOR_EMAILS` | Who may hold `roomAdmin`. See below. |

### Moderator privileges

`roomAdmin` controls who can kick participants and end a LiveKit room. The
original Cloud Function granted it from an `isModerator` boolean **sent by the
client**, so any signed-in user could claim it.

`DOCTOR_EMAILS` closes that: the grant is made only when the Firebase ID token
carries a matching `email` **and** `email_verified` is true. An unverified email
is attacker-controlled until Firebase confirms it, so it never grants anything.
This mirrors `DoctorAccountService.isDoctorEmail` in the app, which is also
email-based — so no UID lookup is needed.

Resolution order in `resolveModerator` (`src/livekit.js`):

1. `DOCTOR_EMAILS` — verified email claim (currently used)
2. `DOCTOR_UIDS` — exact Firebase UIDs, if you prefer pinning accounts
3. neither set — falls back to the client's flag, i.e. the old insecure behaviour

> **Caveat:** `lib/services/doctor_account_service.dart` hardcodes the doctor's
> email *and password* in a public repo. Anyone can therefore sign in as the
> doctor and legitimately pass this check. Rotate that password and remove the
> constant to actually close the hole.

## Free-tier limits

- 100,000 requests/day
- 10 ms CPU per request — this is *CPU*, not wall-clock. Time spent waiting on
  Groq is not counted, which is why the proxy streams the upstream response
  straight through rather than buffering it.
- Commercial use is permitted on the free plan.

Per-user rate limits (`AI_RATE_LIMITER` 20/min, `TOKEN_RATE_LIMITER` 10/min) are
keyed on the Firebase UID so a single account cannot drain the shared quota.

## Rotating a key

```bash
npx wrangler secret put GROQ_API_KEY   # paste the new value
```

Takes effect on the next request. No app release required.
