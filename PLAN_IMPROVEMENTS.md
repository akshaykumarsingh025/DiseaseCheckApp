# DiseaseCheck — Growth, Monetization & Improvement Plan

**Created:** 2026-07-08
**Status:** Approved scope — awaiting go-ahead per phase
**Scope chosen:** Ads (balanced frequency + "Remove Ads" upsell), Retention/Engagement, Growth/Conversion, Trust/Quality/Security, New Health Tools

> This is a *new* plan focused on making people want to use the app and on monetizing via ads.
> The original security-hardening plan lives in `PLAN.md` and is still relevant (see Phase 4).

---

## PHASE 0 — Ads & Monetization (headline feature)

### 0.1 Add AdMob
- Add `google_mobile_ads` to `pubspec.yaml`.
- Add AdMob App ID to `AndroidManifest.xml` (`<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">`).
- Initialize `MobileAds.instance.initialize()` in `main.dart`.
- Store ad unit IDs and a global `adsEnabled` kill-switch in `RemoteConfigService` (so ads can be turned off remotely without a release).

### 0.2 Usage counter service — `lib/services/usage_counter_service.dart`
- Counts **successful** generations of: AI report **and** AI diet plan (combined counter).
- Persist in SharedPreferences, keyed per user UID.
- API:
  - `incrementGeneration()` — call only after a report/diet plan is successfully produced.
  - `int get totalGenerations`
  - `bool shouldShowAd()` — see rule below.

### 0.3 Ad frequency rule (BALANCED — chosen)
- Generations **1–4:** no ads (let the user fall in love with the app).
- **5th generation:** show first interstitial.
- **After the 5th:** show an interstitial on **every 3rd** generation (i.e. gen 5, 8, 11, 14 …).
- Never block the result — preload the interstitial, show it, then navigate to the report/diet plan.
- Fallback: if the ad fails to load, skip it silently (never make the user wait).

### 0.4 Banner ads (low-value screens only)
- Banner on: `report_history_screen`, `trends_screen`, `diet_plans_screen`, `courses_screen`.
- **Never** on: data entry, processing, payment, video call, or the report/diet result itself.

### 0.5 "Remove Ads" upsell (chosen)
- New `PaymentFeature.removeAds` in `payment_service.dart` (one-time purchase, suggested ₹149).
- `AdService.adsAreDisabledForUser()` returns true if:
  - user bought `removeAds`, OR
  - user has any active paid purchase (diet plan / OPD) — reward paying users.
- All ad-show calls check this first.
- Add a small "Remove Ads" card on the dashboard + a menu entry.

### 0.6 `AdService` — `lib/services/ad_service.dart`
- `loadInterstitial()`, `showInterstitialIfDue()`, `getBannerAd()`.
- Central gate: respects `RemoteConfig.adsEnabled` + `adsAreDisabledForUser()`.
- Hook `showInterstitialIfDue()` into report generation (`processing_screen`/report flow) and diet plan generation.

**Deliverable:** ads appear from the 5th AI report/diet plan, every 3rd after; paid users are ad-free; remotely killable.

---

## PHASE 1 — Retention & Engagement

### 1.1 Push notifications (FCM)
- Add `firebase_messaging`. You already have `flutter_local_notifications` for scheduling.
- Server/remote push for: report ready, appointment reminders, re-engagement ("You haven't checked in for 7 days").

### 1.2 Daily health streak + gamification
- `StreakService`: increments when the user logs any health metric / opens a tool that day.
- Dashboard streak badge ("🔥 7-day streak"), milestone badges (7/30/100 days).
- Local reminder notification at a user-set time.

### 1.3 Medicine reminder system
- New model + screen: user adds medicines with schedule (times/days).
- Local scheduled notifications; mark taken/skipped; simple adherence view.
- Strong daily-open driver; complements the diet plan.

### 1.4 Health Score (single 0–100)
- Compute from latest report + trends + streak.
- Big number on dashboard with up/down trend arrow; tap → breakdown.

### 1.5 Home-screen widget (Android)
- Shows next medicine or today's health tip. (`home_widget` package.)

---

## PHASE 2 — Growth & Conversion

### 2.1 Onboarding tutorial (first launch)
- 3–4 slide walkthrough: Enter data → Scan report → AI report → Diet plan.
- Skippable; shown once (SharedPreferences flag).

### 2.2 Share report as image
- Use existing `screenshot` + `share_plus`; render report card via `RepaintBoundary` → PNG → WhatsApp share.
- Add app watermark/branding on the image for organic growth.

### 2.3 Referral system
- Unique referral code per user (Firestore).
- Reward: inviter + invitee both get a free diet plan or 1 ad-free week when invitee signs up.
- Deep link / share message with code.

### 2.4 Hindi + regional localization
- Add `flutter_localizations` + `.arb` files; start with Hindi.
- Auto-detect device language; in-app language switch.

### 2.5 In-app rating prompt
- Add `in_app_review`. Trigger after a *positive* moment (report generated, streak milestone) — **never** right after an ad.

---

## PHASE 3 — New Health Tools

### 3.1 Symptom checker
- Guided Q&A → possible conditions + "see a doctor" CTA (routes into Online OPD → conversion).
- Clear "not a diagnosis" disclaimer.

### 3.2 Lab value explainer
- Tap any abnormal value in a report → plain-language explanation + normal range + what to do.
- Pairs with existing OCR scanner.

### 3.3 Water / step / sleep quick-log
- Lightweight daily trackers feeding the Health Score + streak.

### 3.4 Vaccination / checkup scheduler
- Reminders for routine checkups, vaccines; ties into notifications.

---

## PHASE 4 — Trust, Quality & Security (launch blockers)

> Pulled forward from `PLAN.md` — these must be done before a real Play Store launch.

### 4.1 Move AI API key off-client
- `RemoteConfigService.openRouterApiKey` is still shippable in the APK.
- Fetch from Firestore/remote config at startup, or proxy through a Cloud Function. **Highest priority.**

### 4.2 Turn off payment bypass
- `payment_service.dart` has `_paymentBypassEnabled = true` — everything is free right now.
- Wire real Razorpay verification + Firestore source-of-truth before charging / before ads matter.

### 4.3 Encrypt Hive boxes
- Generate key on first launch → `flutter_secure_storage` → encrypted Hive boxes for health data.

### 4.4 Firestore rules audit
- Confirm rules for `purchases`, `video_calls`, `appointments`, referral/config collections.

### 4.5 Release hardening
- `android:allowBackup="false"`, code obfuscation/minification, real release signing (partly started — `proguard-rules.pro`, `key.properties.example` already added).

### 4.6 UX polish
- Empty states, loading skeletons, consistent error + retry across AI screens.

---

## Suggested execution order

1. **Phase 0 (Ads)** — your priority; ~self-contained.
2. **Phase 4.1 + 4.2** — API key + payment bypass (needed before ads/revenue mean anything).
3. **Phase 1 (Retention)** — biggest impact on "want to use it."
4. **Phase 2 (Growth)** — onboarding + share + referral.
5. **Phase 3 (New tools)** — incremental.
6. **Phase 4 remainder** — before public launch.

---

## New packages required

| Package | Purpose | Phase |
|---|---|---|
| `google_mobile_ads` | Interstitial + banner ads | 0 |
| `firebase_messaging` | Push notifications | 1 |
| `home_widget` | Android home-screen widget | 1 |
| `in_app_review` | Rating prompt | 2 |
| `flutter_localizations` (SDK) | Hindi localization | 2 |

---

**Next step:** tell me which phase to start. Recommended first build: **Phase 0 (Ads)** end-to-end, since that's your main ask.
