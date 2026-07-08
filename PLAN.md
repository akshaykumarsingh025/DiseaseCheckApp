# DiseaseCheck App — Implementation Plan

**Created:** 2025-06-17
**Status:** Pending user approval before each phase

---

## Phase 1: CRITICAL Security Fixes (MUST DO before any release)

### 1.1 Move API keys to Firestore / backend proxy
- **File:** `lib/config/feature_flags.dart`
- **Problem:** OpenRouter API key hardcoded in source — extractable from APK
- **Fix:** Fetch keys from Firestore `config/api_keys` at app startup; cache in memory only
- **Impact:** Prevents API abuse and unexpected bills

### 1.2 Server-side payment verification
- **File:** `lib/services/payment_service.dart`
- **Problem:** Payment status stored in SharedPreferences — trivially editable
- **Fix:** 
  - Write purchase status to Firestore `users/{uid}/purchases` on payment success
  - `hasPurchased()` reads from Firestore, not SharedPreferences
  - Add Firestore rules so only the user can write their own purchases
  - Keep SharedPreferences as cache only (with Firestore as source of truth)
- **Impact:** Prevents free access to paid features

### 1.3 Remove email verification bypass
- **File:** `lib/config/feature_flags.dart`
- **Problem:** `firebaseTestAccountsEnabled = true` is a backdoor in production
- **Fix:** Set to `false` or remove entirely
- **Impact:** Closes auth bypass

### 1.4 Remove hardcoded doctor UID
- **File:** `lib/config/feature_flags.dart`
- **Problem:** Doctor role determined client-side by comparing UID
- **Fix:** Use Firestore `users/{uid}/role` field with security rules; read role from Firestore
- **Impact:** Prevents unauthorized doctor dashboard access

### 1.5 Enable code obfuscation + minification
- **File:** `android/app/build.gradle.kts`
- **Problem:** APK is trivial to decompile; all code and strings visible
- **Fix:** Enable `isMinifyEnabled`, `isShrinkResources`, add `--obfuscate --split-debug-info` to Flutter build
- **Impact:** Makes reverse engineering much harder

### 1.6 Set android:allowBackup="false"
- **File:** `android/app/src/main/AndroidManifest.xml`
- **Problem:** ADB backup exposes all app data including health info
- **Fix:** Add `android:allowBackup="false"` and `android:fullBackupContent="false"` to `<application>` tag
- **Impact:** Prevents data extraction via ADB

### 1.7 Encrypt Hive boxes
- **Files:** `lib/services/storage_service.dart`, add `flutter_secure_storage`
- **Problem:** All health data stored unencrypted in Hive
- **Fix:** Generate encryption key on first launch, store in `flutter_secure_storage`, pass to `Hive.openBox()`
- **Impact:** Health data encrypted at rest

### 1.8 Add Firestore security rules
- **File:** `firestore.rules`
- **Problem:** `config`, `purchases`, `video_calls` collections have no rules
- **Fix:** Add rules for:
  - `config/payment`: authenticated users can read, no one can write from client
  - `users/{uid}/purchases`: only the user can read/write their own
  - `video_calls`: restrict to doctor + patient involved
  - `appointments`: restrict to involved users
- **Impact:** Prevents data leaks and unauthorized writes

### 1.9 Create proper release signing config
- **File:** `android/app/build.gradle.kts`
- **Problem:** Release APK signed with debug keys — Google Play rejects it
- **Fix:** Create keystore, configure `signingConfigs.release` in build.gradle
- **Impact:** Required for Play Store submission

---

## Phase 2: HIGH Priority Features

### 2.1 Push notifications for appointment reminders
- Add `firebase_messaging` package
- Send FCM notification 30 min before appointment
- Show in-app notification badge on dashboard

### 2.2 Share report as image
- Add `screenshot` + `share_plus` (already have share_plus)
- Render report card to image using `RepaintBoundary`
- Share via WhatsApp/image — most Indian users prefer this over PDF

### 2.3 Multi-profile support (family members)
- Allow creating family member profiles under one account
- Each member gets their own reports, health data, diet plans
- Switch profiles from dashboard

### 2.4 App lock (PIN/biometric)
- Add `local_auth` package
- Require PIN/fingerprint on app open
- Auto-lock after 5 minutes in background
- Critical for health data privacy on shared phones

---

## Phase 3: MEDIUM Priority Features

### 3.1 Offline mode indicator + local-first sync
- Show clear offline banner (partially exists)
- Queue Firestore writes when offline, sync when back online
- Make report viewing fully offline

### 3.2 Health tips / daily notification
- Schedule daily health tip notification
- Tips based on user's conditions (diabetes tips for diabetic users, etc.)
- Firebase Cloud Messaging for remote tips

### 3.3 Export health data to CSV/Excel
- Add export button on trends screen
- Generate CSV with all health data points
- Share via email/WhatsApp

### 3.4 Medicine reminder system
- Companion to diet plan
- User enters medicines + schedule
- Push notification at reminder time
- Track adherence (taken/skipped)

### 3.5 Dark mode for PDF reports
- Detect system theme
- Generate PDF with dark background + light text when in dark mode
- Or always generate light PDF (standard medical format) with a note

---

## Phase 4: LOW Priority / Polish

### 4.1 Onboarding tutorial
- Show feature walkthrough on first launch
- Highlight: Enter Data → Scan Report → AI Report → Diet Plan
- Skip option for returning users

### 4.2 Localization (Hindi UI)
- Add `flutter_localizations` + Hindi `.arb` files
- Translate all UI strings to Hindi
- Auto-detect device language

### 4.3 Weak password policy fix
- Increase minimum password from 6 to 8 characters
- Add complexity requirements
- Generic auth error messages (prevent account enumeration)

### 4.4 Rate limiting on AI API calls
- Client-side rate limit: max 10 requests per hour
- Store last call timestamps in SharedPreferences
- Show "please wait" message with cooldown timer

### 4.5 Stop writing sensitive data to /sdcard/Download/
- Use app-private directory for AI model downloads
- Only write to Downloads when user explicitly exports

---

## Execution Order

Phase 1 (security) MUST be done before any public release.
Phase 2-4 can be done in any order based on user priority.

**Current status:** Awaiting approval to start Phase 1
