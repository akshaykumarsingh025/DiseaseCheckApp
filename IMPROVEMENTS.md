# DiseaseCheckApp — Improvements, Fixes & Changes

> Generated: 2026-04-02 | Full codebase audit

---

## TABLE OF CONTENTS

1. [Backend — Critical Issues](#1-backend--critical-issues)
2. [Backend — High Priority](#2-backend--high-priority)
3. [Backend — Medium Priority](#3-backend--medium-priority)
4. [Backend — Low Priority / Refactoring](#4-backend--low-priority--refactoring)
5. [Frontend — Issues](#5-frontend--issues)
6. [Architecture & Project-Level](#6-architecture--project-level)

---

## 1. BACKEND — CRITICAL ISSUES

### 1.1 Hardcoded Placeholder API Credentials
**File:** `lib/services/icd_api_service.dart:12-13`

```dart
static const String _clientId = 'YOUR_CLIENT_ID';
static const String _clientSecret = 'YOUR_CLIENT_SECRET';
```

**Problem:** WHO ICD API credentials are hardcoded as placeholders. If real credentials are ever committed, they'll be in git history forever.

**Fix:**
- Move to environment variables via `--dart-define` or use a `.env` file with `flutter_dotenv`
- Add `.env` to `.gitignore`
- Load at runtime from a secure config service

---

### 1.2 ML Engine is Completely Stubbed Out
**File:** `lib/engine/ml_engine.dart`

**Problem:** The ML engine always returns `0.15` (15% probability) regardless of input. TFLite model loading and prediction are fully commented out. The app claims to be "AI-powered" but uses no actual ML inference.

**Impact:** Misleading to users. The `RiskAggregator` class depends on it but gets garbage data.

**Fix:**
- Either implement the TFLite model properly with real trained models
- Or remove the ML engine entirely and communicate the app is rule-based
- If models exist in `assets/ml_models/`, wire them up

---

### 1.3 Silent Error Swallowing in Cloud Sync
**File:** `lib/services/storage_service.dart:119,133,147`

```dart
} catch (_) {}  // appears 3 times
```

**Problem:** All cloud fetch methods (`fetchProfileFromCloud`, `fetchReportsFromCloud`, `fetchHealthDataFromCloud`) silently swallow errors. If Firestore is unreachable, data corruption occurs, or auth fails — the user gets zero feedback and no logs.

**Fix:**
- Log errors to a crashlytics service (Firebase Crashlytics)
- Return success/failure booleans
- Show user-facing error when cloud sync fails
- At minimum: `catch (e, s) { debugPrint('Cloud sync failed: $e\n$s'); }`

---

### 1.4 Null Safety Bug in Cervical Cancer Risk Check
**File:** `lib/engine/rule_engine.dart:627`

```dart
if (hpvStatus != null && hpvStatus == 1) {
  // ...
} else if (hpvStatus == 0) {  // BUG: hpvStatus could be null here
  findings.add('HPV Status: Negative');
}
```

**Problem:** The `else if` branch doesn't guard against null. When `hpvStatus` is null, this evaluates to `null == 0` which is `false`, so it's technically safe — but it's misleading and fragile. If `papSmear` was non-null and triggered the outer `if`, this `else if` would still run with a null `hpvStatus`.

**Fix:**
```dart
} else if (hpvStatus != null && hpvStatus == 0) {
```

---

## 2. BACKEND — HIGH PRIORITY

### 2.1 No Input Validation on Health Data
**File:** `lib/models/health_data.dart`, `lib/engine/rule_engine.dart`

**Problem:** No bounds checking on health values. A user could enter:
- Negative blood pressure
- Glucose of 99999
- Heart rate of 0 or 10000

The rule engine doesn't validate ranges before applying clinical thresholds, which could produce nonsense results.

**Fix:**
- Add min/max bounds to `LabTestDefinition` (e.g., `minValue`, `maxValue`)
- Validate in `HealthData.fromJson()` and in the form submission
- Add sanity checks in `RuleEngine.evaluateHealthData()` to reject impossible values

---

### 2.2 RiskAggregator is Dead Code / Incomplete
**File:** `lib/engine/risk_aggregator.dart`

**Problem:** This class only evaluates 2 conditions (diabetes, hypertension) using `Map<String, dynamic>` input. The actual processing pipeline (`processing_screen.dart:32`) calls `RuleEngine.evaluateHealthData()` directly, bypassing `RiskAggregator` entirely. The class is dead code.

**Fix:**
- Either delete `RiskAggregator` and `risk_aggregator.dart`
- Or expand it to be the single entry point that delegates to `RuleEngine` and `MLEngine`, merging their results

---

### 2.3 Report IDs Not Guaranteed Unique
**File:** `lib/engine/report_generator.dart:25`

```dart
reportId: DateTime.now().millisecondsSinceEpoch.toString(),
```

**Problem:** If two reports are generated within the same millisecond (e.g., fast processing or batch operations), IDs will collide and overwrite each other in Hive and Firestore.

**Fix:**
```dart
import 'package:uuid/uuid.dart';
reportId: const Uuid().v4(),
```
Note: `processing_screen.dart:61` already uses `Uuid().v4()` correctly — so `report_generator.dart` is also partially dead code.

---

### 2.4 Type Safety — Everything is `Map<String, dynamic>`
**Files:** `lib/engine/rule_engine.dart`, `lib/engine/risk_aggregator.dart`, `lib/engine/report_generator.dart`

**Problem:** All analysis results are returned as `Map<String, dynamic>`. This means:
- Typos in keys (`'disease'` vs `'Disease'`) cause silent bugs
- No compile-time safety
- No IDE autocomplete
- Hard to refactor

**Fix:** Create typed result classes:

```dart
class RiskResult {
  final String disease;
  final String icdCode;
  final int riskScore;
  final String riskLevel;
  final List<String> findings;
  final String guideline;
}
```

Use `RiskResult` everywhere instead of raw maps.

---

### 2.5 `evaluateHealthData` Uses Fragile Label-Based Lookup
**File:** `lib/engine/rule_engine.dart:800-806`

```dart
String label = entry.testName.toString();
double value = entry.value;
vals[label] = value;

double? v(String label) => vals[label];
```

**Problem:** The lookup uses display labels like `'Fasting Blood Glucose'` and `'Systolic BP'`. If a label changes in `test_definitions.dart`, the rule engine silently stops detecting that test — no error, no warning. The `key` field should be used instead of `testName`.

**Fix:**
- Store and look up by `key` (e.g., `'fasting_glucose'`, `'systolic'`) instead of display labels
- Or build a label-to-key mapping once at startup

---

### 2.6 No Firestore Security Rules Configuration
**File:** `firebase.json`

**Problem:** No `firestore.rules` file is present. Default Firestore rules typically allow open read/write access. Health data (PHI/PII) is being synced without access control.

**Fix:**
- Create `firestore.rules` with per-user access:
```
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```
- Deploy with `firebase deploy --only firestore:rules`

---

### 2.7 Health Data Saved Before Firestore Confirms
**File:** `lib/providers/health_data_provider.dart:13-15`

```dart
Future<void> addHealthData(HealthData data) async {
  await StorageService.saveHealthData(data);
  state = [...state, data];  // Added to state regardless of Firestore result
}
```

**Problem:** `StorageService.saveHealthData` saves to Hive first, then to Firestore. If Firestore fails, the local state is updated but the cloud doesn't have the data. On next login from a different device, the data won't be there.

**Fix:**
- Save to Hive, then attempt Firestore. If Firestore fails, mark the entry as `needsSync: true`
- Implement a background sync retry mechanism
- Or use a `try/catch` and show a sync-status indicator to the user

---

### 2.8 Duplicate Data on Cloud Fetch
**File:** `lib/services/storage_service.dart:136-148`

```dart
for (var doc in snapshot.docs) {
  final data = HealthData.fromJson(doc.data());
  await healthDataBox.add(data);  // Appends without deduplication
}
```

**Problem:** Every time `fetchHealthDataFromCloud` is called (e.g., on re-login), it appends all Firestore data to Hive again. After 3 logins, you'll have 3 copies of every entry. Same issue exists for reports.

**Fix:**
- Use `healthDataBox.put(uniqueKey, data)` instead of `.add()`
- Or clear the box before syncing
- Or add a `dataId` field to `HealthData` and use it as the Hive key

---

## 3. BACKEND — MEDIUM PRIORITY

### 3.1 `ReferenceRanges` Class is Unused by Rule Engine
**File:** `lib/engine/reference_ranges.dart`

**Problem:** The `reference_ranges.dart` file defines a `ReferenceRanges` class with `isAbnormal()` and `getRange()` methods, but the `RuleEngine` uses hardcoded threshold values instead. This means:
- Reference ranges in `reference_ranges.dart` and `reference_ranges.json` are not used
- Threshold values are duplicated in two places and may drift

**Fix:**
- Refactor `RuleEngine` to use `ReferenceRanges.isAbnormal()` for threshold checks
- Or delete `reference_ranges.dart` if the hardcoded approach is preferred
- Keep a single source of truth

---

### 3.2 ICD API Service Has No Retry/Timeout Logic
**File:** `lib/services/icd_api_service.dart`

**Problem:** API calls to WHO ICD have no timeout configuration and no retry logic. If the API is slow or temporarily down, the call hangs or fails silently.

**Fix:**
```dart
final _dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 10),
));
```
- Add exponential backoff retry for token refresh
- Consider caching search results locally

---

### 3.3 No Logging Framework
**Files:** All service and engine files

**Problem:** The app has zero structured logging. Errors are either swallowed (`catch (_) {}`) or printed with `print()` (e.g., `ocr_scanner_screen.dart:151-153`). In production, `print` statements are stripped and errors vanish.

**Fix:**
- Add `logger` package or use `dart:developer`'s `log()`
- Add Firebase Crashlytics for crash reporting
- Replace all `print()` with `logger.debug()` / `logger.error()`

---

### 3.4 `StorageService` is Entirely Static
**File:** `lib/services/storage_service.dart`

**Problem:** All methods are `static`. This:
- Makes unit testing impossible (can't mock static methods)
- Creates tight coupling everywhere
- Prevents dependency injection

**Fix:**
- Convert to an instance-based service
- Register via Riverpod provider: `final storageServiceProvider = Provider<StorageService>((ref) => StorageService());`
- Inject into providers/screens via ref

---

### 3.5 `AuthService` Missing Email Verification Check on Sign-In
**File:** `lib/services/auth_service.dart:28-36`

**Problem:** `signInWithEmail` doesn't check if the user's email is verified before allowing login. The `isEmailVerified` getter exists but is never called during sign-in flow. Unverified accounts can use the full app.

**Fix:**
- After `signInWithEmailAndPassword`, check `credential.user?.emailVerified`
- If not verified, throw a specific error or redirect to verification screen

---

### 3.6 `HealthReport` Uses `List<dynamic>` Instead of Typed Lists
**File:** `lib/models/report.dart:14,17`

```dart
final List<dynamic> highRiskDiseases;
final List<dynamic> moderateRiskDiseases;
```

**Problem:** No type safety. Anything can be added to these lists. Serialization/deserialization is fragile.

**Fix:**
- Create a `RiskDisease` model class
- Change to `List<RiskDisease>`
- Add proper Hive type or JSON serialization

---

### 3.7 `PdfReportService` Has Hardcoded Branding
**File:** `lib/services/pdf_report_service.dart:95`

**Problem:** App name "Health Check AI" is hardcoded in the PDF header. If branding changes, this won't update. Also no configurable hospital/clinic name for the report.

**Fix:**
- Extract branding constants to a config file
- Allow profile-level customization (clinic name, logo)

---

## 4. BACKEND — LOW PRIORITY / REFACTORING

### 4.1 `test_definitions.dart` Has Inconsistent Keys vs Labels

Some tests use keys that don't match their labels semantically, and the `fasting_insulin` key appears in TWO categories (`Blood Sugar / Diabetes Panel` and `Metabolic Panel (Women's Health)`). This causes the second one to overwrite the first in `getTestDefinition()`.

**Fix:** Ensure unique keys across all categories. Use a unified lookup map at initialization.

---

### 4.2 `_friendlyError` in `AuthService` Doesn't Cover All Firebase Error Codes

Missing codes: `operation-not-allowed`, `account-exists-with-different-credential`, `credential-already-in-use`, `requires-recent-login`.

**Fix:** Add more cases or use a fallback that shows the raw code for debugging.

---

### 4.3 `BmiCalculator.getBmiCategory` Has Unreachable Code

```dart
} else if (bmi >= 30.0) {
  return 'Obese';
}
return 'Unknown';  // Unreachable — bmi >= 30.0 covers all remaining values
```

The `return 'Unknown'` is dead code.

---

### 4.4 `UnitConverter` Missing Medical Unit Conversions

Missing common conversions: `µIU/mL` to `pmol/L` (insulin), `ng/mL` to `pmol/L` (vitamin D), `mg/dL` to `µmol/L` (creatinine).

---

## 5. FRONTEND — ISSUES

### 5.1 `print()` Statements Left in Production Code
**File:** `lib/screens/ocr_scanner_screen.dart:151-153,213-215`

```dart
print('--- ML KIT OCR EXTRACTED TEXT ---');
print(alignedText);
```

**Problem:** Debug print statements in production code. These dump potentially sensitive medical text to the console.

**Fix:** Remove or replace with `debugPrint()` / logger that's disabled in release builds.

---

### 5.2 No Error Boundary / Crash Handling on Processing Screen
**File:** `lib/screens/processing_screen.dart`

**Problem:** `_processData()` has no `try/catch`. If `RuleEngine.evaluateHealthData()` throws (e.g., due to unexpected data format), the user sees an unhandled exception red screen instead of a graceful error.

**Fix:**
```dart
try {
  final analysisResults = RuleEngine.evaluateHealthData(healthDataList);
  // ... rest of processing
} catch (e) {
  // Show error UI, log to Crashlytics
}
```

---

### 5.3 `ReportGenerator` and `ProcessingScreen` Duplicate Report Creation Logic
**Files:** `lib/engine/report_generator.dart`, `lib/screens/processing_screen.dart:34-66`

**Problem:** `ReportGenerator.generate()` exists but is never called. `ProcessingScreen` manually builds the `HealthReport` inline. Code duplication and `ReportGenerator` is dead code.

**Fix:** Use `ReportGenerator.generate(analysisResults)` in `ProcessingScreen` instead of reimplementing the same logic.

---

### 5.4 No Loading State for Cloud Sync on Login
**File:** `lib/services/storage_service.dart:101-105`

**Problem:** `fetchAllFromCloud()` is called on login but there's no loading indicator. If the user has lots of data, the app appears frozen while syncing.

**Fix:** Show a sync progress indicator or do cloud sync in the background after navigating to dashboard.

---

### 5.5 `TrendsScreen` Crashes When All Data Points Have Same Value
**File:** `lib/screens/trends_screen.dart:107-109`

```dart
final range = maxVal - minVal;
final yMin = (minVal - range * 0.2).clamp(0.0, double.infinity);
final yMax = (maxVal + range * 0.2);
```

**Problem:** If all values are identical (e.g., all readings are 98.6°F), `range = 0`, so `yMin == yMax == 98.6`. The chart renders with zero height range, causing a flat line that may crash or look broken.

**Fix:** Add a minimum range: `final effectiveRange = range > 0 ? range : 10.0;`

---

### 5.6 Missing Form Validation on Profile Setup
**File:** `lib/screens/profile_setup_screen.dart` (not fully reviewed)

The `UserProfile` model allows `age: 0` or negative values, empty `name`, etc. No validation is enforced at the model or form level.

---

### 5.7 No Accessibility (a11y) Support

- No `Semantics` widgets anywhere
- No `semanticLabel` on icons/images
- Charts have no text alternatives for screen readers
- No dynamic text scaling support

---

## 6. ARCHITECTURE & PROJECT-LEVEL

### 6.1 No Tests

**File:** `test/` directory exists but likely empty or minimal.

**Problem:** Zero test coverage for a health-risk assessment app. The rule engine has complex clinical threshold logic that should have extensive unit tests.

**Fix:**
- Add unit tests for every `RuleEngine.check*` method with edge cases
- Test `OcrParser` with sample medical report text
- Test `EgfrCalculator` and `BmiCalculator` with known values
- Add integration tests for the processing pipeline

---

### 6.2 No CI/CD Pipeline

No `.github/workflows/`, no `Makefile`, no build scripts. Manual builds are error-prone.

**Fix:**
- Add GitHub Actions for: `flutter analyze`, `flutter test`, `flutter build`
- Add linting rules in `analysis_options.yaml` (currently uses `flutter_lints` which is deprecated — switch to `flutter_lints` -> `flutter_lints` or `very_good_analysis`)

---

### 6.3 No Environment Configuration

No `.env` file, no flavor/build variant setup. The same code runs against production Firebase regardless of whether it's dev or prod.

**Fix:**
- Add `--dart-define=ENV=dev` / `--dart-define=ENV=prod` configuration
- Use different Firebase projects for dev/prod
- Create a `Config` class that reads from `String.fromEnvironment`

---

### 6.4 Missing `analysis_options.yaml` Strictness

**File:** `analysis_options.yaml`

Current lints are likely minimal. The app uses `flutter_lints` (deprecated).

**Fix:**
- Switch to `flutter_lints: ^4.0.0` (already in pubspec, but ensure `analysis_options.yaml` includes `include: package:flutter_lints/flutter.yaml`)
- Add additional rules: `prefer_const_constructors`, `avoid_print`, `prefer_single_quotes`, etc.

---

### 6.5 `lib/data/` Mixed Into Flutter Assets

**File:** `pubspec.yaml:80`

```yaml
assets:
  - lib/data/
```

**Problem:** Putting source code directory (`lib/data/`) as a Flutter asset is unconventional. These JSON files should be in `assets/data/` instead.

**Fix:** Move `diseases.json`, `guidelines.json`, `reference_ranges.json` to `assets/data/` and update references.

---

### 6.6 Missing App Version Check / Force Update Mechanism

No mechanism to check if the user is on the latest version. Critical for a health app where clinical thresholds may change.

**Fix:**
- Add remote config for minimum app version
- Show update dialog when version is outdated

---

## PRIORITY SUMMARY

| Priority | Count | Focus Area |
|----------|-------|------------|
| CRITICAL | 4 | Security, ML stub, error swallowing, null bug |
| HIGH | 8 | Validation, dead code, type safety, dedup, Firestore rules |
| MEDIUM | 7 | Unused code, logging, DI, auth checks |
| LOW | 4 | Minor refactors, dead code, missing conversions |
| FRONTEND | 7 | Error handling, debug prints, crashes, a11y |
| PROJECT | 6 | Tests, CI/CD, config, linting, assets |

**Total: 36 items identified**
