# Upgrade Options — DiseaseCheckApp

> Complete audit of frontend, backend, bugs, features, diseases, and UI/UX improvements.
> **Zero-cost constraint: Everything below runs on-device or uses free-tier services only. No paid servers, no paid APIs.**

---

## COST PHILOSOPHY

| Method | Cost | Used Here? |
|--------|------|------------|
| On-device computation (rule engine, ML, OCR, calculators) | Free forever | YES |
| Hive local storage | Free forever | YES |
| Firebase Spark Plan (Auth, Firestore 1GB/50K reads/day, Crashlytics, Analytics, FCM) | Free forever | YES |
| Google ML Kit (on-device text recognition) | Free forever | YES |
| Google Sign-In / Apple Sign-In / Phone Auth | Free (Firebase Auth) | YES |
| HealthKit / Google Fit APIs | Free (OS-level) | YES |
| Cloud Functions, Cloud Storage, Remote Config | Requires Blaze plan (paid) | NO — replaced with on-device logic |
| WHO ICD API | Requires credentials + token server | NO — replaced with local diseases.json |
| Lab LIMS APIs | Paid / partnership required | NO — replaced with OCR scanning |
| Doctor web portal | Requires server hosting | NO — replaced with PDF/QR share |

---

## 1. BUGS & ISSUES

### 1.1 Data Integrity
- [ ] **diseases.json inconsistency**: IDs 1 & 10 use numeric strings, D068–D074 use prefixed strings, IMG01–IMG06 use another prefix. Some entries use `icdCode` key while others use `icd10` key. Must unify to a single schema (`icd10` for all).
- [ ] **Missing `detectionMethod`** on disease D074 (Thyroid Dysfunction in Pregnancy) — field is absent, will cause null errors downstream.
- [ ] **reference_ranges.json gender/age blindness**: Ranges are single-value and don't account for male vs. female (e.g., creatinine, testosterone) or age bands (e.g., FSH varies by menopausal status). This leads to false positives/negatives.
- [ ] **HDL `normal_min: 60`** is the *optimal* floor, not the clinical lower bound (which is 40 for men, 50 for women). Values between 40–60 will be incorrectly flagged as abnormal.

### 1.2 Routing & Navigation
- [ ] **No deep-link guard on `/report`**: If `state.extra` is null (deep link or browser refresh), `ReportScreen(report: null)` will crash. Needs null-check + redirect.
- [ ] **Same issue on `/data-category` and `/data-entry`**: `state.extra` casts without safety — will throw `TypeError` on hot-restart or deep link.
- [ ] **No `/profile-setup` guard**: User can navigate directly to profile-setup without being authenticated.

### 1.3 Auth & Security
- [ ] **No email verification gate**: User can sign up and immediately access the app without verifying email. Should block dashboard access until `emailVerified == true`.
- [ ] **Firebase Security Rules**: `firestore.rules` needs review — ensure users can only read/write their own data (`request.auth.uid == resource.data.userId`).
- [ ] **No session timeout**: User stays logged in indefinitely. Should add configurable auto-logout after inactivity.
- [ ] **Remove WHO ICD API dependency**: Currently partially implemented but requires external credentials + a token server. Replace with local `diseases.json` lookup + bundled ICD-10 code map. Zero cost, works offline.

### 1.4 Engine & Logic
- [ ] **Rule engine has no audit trail**: When a disease is flagged, there's no way to see *which* rules fired and *why*. Store audit trail in Hive alongside the report.
- [ ] **No conflict resolution between overlapping diseases**: e.g., PCOS from hormonal panel (rule engine) and PCOS from imaging (OCR parser) — could produce duplicate entries with different risk scores. Deduplicate by ICD-10 code, merge risk scores (take higher).
- [ ] **eGFR calculator** likely doesn't handle edge cases: creatinine ≤ 0, extreme age values, or non-standard units without conversion.
- [ ] **Unit converter**: No validation that the input value is within a physically plausible range before conversion (e.g., a typo like 9999 mg/dL glucose would silently convert). Add sanity bounds.

### 1.5 Performance
- [ ] **No pagination on report history**: Loading all reports at once will degrade with usage. Needs lazy loading from Hive (query with offset/limit).
- [ ] **diseases.json, reference_ranges.json, guidelines.json** are loaded as raw JSON assets on every access — should be parsed once and cached in memory or stored in Hive after first load.

### 1.6 UI Bugs
- [ ] **Splash screen flash**: Theme loads asynchronously from SharedPreferences — defaults to light mode, causing a flash if user had dark mode. Show a neutral branded splash until theme resolves.
- [ ] **No loading states** on multiple screens (OCR review, data entry submission) — user can tap "Submit" multiple times, creating duplicate reports.
- [ ] **No error handling UI** for OCR failures or offline mode — user sees blank or broken screens.

---

## 2. NEW DISEASES TO ADD

> All detection is on-device via rule engine (no API calls). Rules reference published guidelines bundled in guidelines.json.

### 2.1 Cardiovascular (expand current)
- [ ] **Coronary Artery Disease (CAD)** — I25.1 | Rule: Framingham Risk Score (age, BP, cholesterol, smoking, diabetes) — all inputs already available
- [ ] **Atrial Fibrillation** — I48 | Rule: Irregular heart rate flag + age > 65 + symptoms checklist
- [ ] **Heart Failure** — I50.9 | Rule: Low eGFR + elevated BNP/NT-proBNP + edema symptoms
- [ ] **Peripheral Artery Disease** — I73.9 | Rule: Ankle-brachial index + smoking + diabetes + age
- [ ] **Deep Vein Thrombosis (DVT)** — I82.9 | Rule: D-dimer + swelling symptoms + risk factors (immobilization, OCP use)

### 2.2 Metabolic & Endocrine
- [ ] **Type 1 Diabetes** — E10 | Rule: Low C-peptide + anti-GAD antibodies + acute hyperglycemia onset
- [ ] **Gestational Diabetes** — O24.4 | Rule: OGTT during pregnancy per ACOG/IADPSG criteria
- [ ] **Metabolic Syndrome** — E88.81 | Rule: ≥3 of: waist circumference, triglycerides, HDL, BP, fasting glucose (NCEP ATP III)
- [ ] **Hypothyroidism** — E03.9 | Rule: TSH > 4.5 mIU/L + low Free T4
- [ ] **Hyperthyroidism** — E05.9 | Rule: TSH < 0.1 + elevated Free T4/T3
- [ ] **Vitamin D Deficiency** — E55.9 | Rule: 25-OH Vitamin D < 20 ng/mL
- [ ] **Iron Deficiency Anemia** — D50.9 | Rule: Low ferritin + low MCV + low Hb + low hematocrit
- [ ] **B12 Deficiency** — D51.9 | Rule: Low B12 + elevated MCV + elevated homocysteine
- [ ] **Gout / Hyperuricemia** — M10.9 | Rule: Uric acid > 7 mg/dL + joint symptoms

### 2.3 Kidney & Liver (expand current)
- [ ] **Chronic Kidney Disease (CKD) Staging** — N18.1–N18.5 | Rule: eGFR staging per KDIGO (G1–G5) + albuminuria — eGFR calculator already exists
- [ ] **Acute Kidney Injury** — N17.9 | Rule: Rapid creatinine rise + decreased urine output (KDIGO criteria)
- [ ] **Nephrotic Syndrome** — N04.9 | Rule: Proteinuria > 3.5 g/day + low albumin + edema
- [ ] **Non-Alcoholic Steatohepatitis (NASH)** — K75.81 | Rule: Elevated ALT/AST + fatty liver on imaging + metabolic risk factors
- [ ] **Alcoholic Liver Disease** — K70.9 | Rule: AST/ALT ratio > 2 + elevated GGT + MCV
- [ ] **Viral Hepatitis (B/C) Risk** — B18.1/B18.2 | Rule: Elevated ALT + risk factors (travel, exposure, tattoos)

### 2.4 Women's Health (expand current)
- [ ] **Endometriosis** — N80.9 | Rule: Dysmenorrhea + dyspareunia + elevated CA-125 + imaging
- [ ] **Gestational Diabetes** — O24.4 | (listed in pregnancy category above)
- [ ] **Postpartum Depression Risk** — F53 | Rule: EPDS score + history + hormonal markers
- [ ] **Osteoporosis Risk** — M81.0 | Rule: Low calcium + vitamin D + age + T-score from DEXA scan (OCR)
- [ ] **Uterine Fibroids** — D25.9 | Rule: Detected via OCR of pelvic ultrasound (keywords: fibroid, leiomyoma, myoma)
- [ ] **Breast Cancer Screening Risk** — Z12.31 | Rule: Age + family history + BRCA markers if available

### 2.5 Men's Health (new category)
- [ ] **Benign Prostatic Hyperplasia (BPH) Staging** — N40 | Rule: PSA levels + prostate volume (from OCR) + IPSS symptom score
- [ ] **Prostate Cancer Risk** — C61 | Rule: PSA > 4 ng/mL + age + family history + free/total PSA ratio
- [ ] **Hypogonadism / Low Testosterone** — E29.1 | Rule: Total testosterone < 300 ng/dL + symptoms + LH/FSH
- [ ] **Erectile Dysfunction (Cardiovascular Risk)** — F52.2 | Rule: Flag for cardiac workup based on age + cardiovascular risk factors
- [ ] **Male Infertility** — N46 | Rule: Low sperm count markers + FSH/LH/Testosterone panel

### 2.6 Pediatric (new category)
- [ ] **Childhood Obesity** — E66.0 | Rule: BMI percentile ≥ 95th for age/sex (CDC growth charts bundled locally)
- [ ] **Juvenile Diabetes** — E10 | Rule: Age < 18 + acute hyperglycemia + ketones
- [ ] **Growth Hormone Deficiency** — E23.0 | Rule: Height < 3rd percentile + IGF-1 levels + growth velocity
- [ ] **Lead Toxicity** — T56.0 | Rule: Blood lead level ≥ 5 µg/dL

### 2.7 Mental Health & Neurology (new category)
- [ ] **Depression Screening** — F32.9 | Rule: PHQ-9 score ≥ 10 (questionnaire scored on-device)
- [ ] **Anxiety Disorder** — F41.1 | Rule: GAD-7 score ≥ 10 (questionnaire scored on-device)
- [ ] **Sleep Apnea Risk** — G47.33 | Rule: BMI > 35 + neck circumference + snoring + daytime fatigue
- [ ] **Migraine** — G43.9 | Rule: Recurrent headache pattern + triggers + duration criteria (ICHD-3)

### 2.8 Infectious Disease (new category)
- [ ] **HIV Screening** — Z11.4 | Rule: Risk factors + ELISA/Western blot results
- [ ] **Tuberculosis Risk** — A15.9 | Rule: Positive PPD/IGRA + CXR findings + symptoms
- [ ] **COVID-19 Risk Assessment** — U07.1 | Rule: Symptom checker + vaccination status + comorbidities
- [ ] **Hepatitis B Carrier** — B18.1 | Rule: HBsAg positive + HBV DNA viral load

### 2.9 Oncology Screening (new category)
- [ ] **Colorectal Cancer Risk** — C18.9 | Rule: Age > 45 + FOBT/FIT positive + family history
- [ ] **Lung Cancer Screening** — Z12.11 | Rule: Age 50–80 + smoking history ≥ 20 pack-years (USPSTF)
- [ ] **Liver Cancer Risk (HCC)** — C22.0 | Rule: Cirrhosis + AFP levels + chronic HBV/HCV

---

## 3. FRONTEND UPGRADES

> All UI changes are on-device. No server costs.

### 3.1 UI/UX Redesign
- [ ] **Design System**: Create a unified design system with:
  - Color tokens (primary, secondary, semantic, surface, on-surface)
  - Typography scale (display, headline, title, body, label)
  - Spacing scale (4, 8, 12, 16, 24, 32, 48)
  - Elevation/shadow tokens
  - Border radius tokens
  - Component library (buttons, cards, inputs, chips, dialogs)
- [ ] **Dashboard Redesign**: Replace flat card grid with:
  - Personalized greeting + on-device health score ring at top
  - "Quick Actions" row (Scan Report, Enter Data, View Trends)
  - Recent reports carousel (horizontal scroll, data from Hive)
  - Health alerts banner (animated, triggered by rule engine)
  - Disease category chips for filtering
- [ ] **Data Entry Redesign**:
  - Stepper/wizard flow instead of one long form
  - Auto-save drafts (save to Hive on every field change)
  - Smart defaults from user profile (age, sex → pre-fill)
  - Visual reference range slider on each input (green zone = normal, from bundled ranges)
  - Unit toggle (mg/dL ↔ mmol/L) with real-time on-device conversion
- [ ] **Report Screen Redesign**:
  - Animated risk gauge (semicircle) instead of static cards
  - Expandable sections (click to see which values triggered each disease — from rule audit trail)
  - Timeline view (compare with previous reports from Hive, no server needed)
  - "What to do next" actionable cards (lifestyle tips bundled in JSON)
  - Share as PDF (on-device generation via `pdf` package) or share via WhatsApp/email
- [ ] **Trends Screen Redesign**:
  - Interactive line charts with pinch-to-zoom (fl_chart already in pubspec)
  - Heatmap calendar view (color per day by health score, computed on-device)
  - Anomaly highlighting (red dots on outlier values)
  - Filter by disease category
  - Export trend data as CSV (on-device, save to downloads or share)
- [ ] **OCR Scanner Redesign**:
  - Live camera preview with auto-crop overlay
  - Real-time text extraction preview (Google ML Kit — free, on-device)
  - Confidence scores on each extracted value (green/yellow/red)
  - Manual correction mode with tap-to-edit on each field

### 3.2 New Screens & Flows
- [ ] **Onboarding Flow** (3-5 slides): App purpose → how it works → privacy → disclaimer → get started
- [ ] **Home/Health Score Screen**: Aggregate score (0–100) computed on-device from latest vitals + lab values
- [ ] **Medication Tracker**: Log medications in Hive, local reminders via `flutter_local_notifications` (free), check drug-lab interactions via bundled interaction rules JSON
- [ ] **Symptom Checker**: Chat-like interface to log symptoms, cross-reference with lab values on-device
- [ ] **Doctor Share**: Generate PDF report on-device → share via WhatsApp/email/QR code (no server portal needed)
- [ ] **Emergency Alerts**: If critical values detected (e.g., BP > 180/120, glucose > 500), show prominent "Seek immediate medical attention" with call-to-action
- [ ] **Settings Screen**: Theme, units, language, notification preferences, data export (CSV/PDF), account deletion, privacy
- [ ] **Profile Screen**: View/edit profile, see health summary, manage family members (all stored in Hive)
- [ ] **Education Hub**: Disease-specific articles, lifestyle tips, prevention guides — bundled as local JSON/Markdown assets (no server fetch)

### 3.3 Animations & Micro-interactions
- [ ] Page transitions (slide, fade) using GoRouter + AnimatedSwitcher
- [ ] Lottie animations on splash, processing, empty states (Lottie files bundled in assets)
- [ ] Hero animations on report cards → detail
- [ ] Pull-to-refresh with custom animation on list screens
- [ ] Haptic feedback on risk-level reveals (low = light, high = heavy)
- [ ] Skeleton loading states (shimmer) instead of spinners
- [ ] Confetti animation on "all values normal" result

### 3.4 Accessibility
- [ ] Semantic labels on all interactive elements
- [ ] Screen reader support (Semantics widget)
- [ ] High contrast mode
- [ ] Font scaling support (respect system text scale)
- [ ] Minimum touch target 48x48
- [ ] Color-blind friendly palette (use shapes/icons + color, not color alone for risk levels)

### 3.5 Internationalization
- [ ] Set up `flutter_localizations` + `intl` (already in pubspec)
- [ ] Extract all hardcoded strings to ARB files
- [ ] Priority languages: English, Hindi, Spanish, Arabic, Mandarin
- [ ] RTL layout support for Arabic/Urdu
- [ ] Locale-aware date/number formatting

### 3.6 Responsive Design
- [ ] Tablet layout: side navigation + two-panel layout
- [ ] Foldable device support (hinge-aware layout)
- [ ] Landscape mode support on phones
- [ ] Breakpoint system: compact (<600), medium (600–840), expanded (>840)

---

## 4. BACKEND UPGRADES (FREE TIER ONLY)

### 4.1 Firestore Schema & Security (Spark Plan — Free)
- [ ] **Schema design**: Define structured collections:
  ```
  users/{uid}
  users/{uid}/reports/{reportId}
  users/{uid}/health_data/{dataId}
  users/{uid}/medications/{medId}
  ```
- [ ] **Composite indexes** for queries (e.g., reports sorted by date, filtered by disease) — free on Spark plan
- [ ] **Security rules**: Enforce `request.auth != null && request.auth.uid == uid` — free
- [ ] **Data validation on-device**: Instead of Cloud Functions (which require Blaze plan), validate all health data on-device before writing to Firestore. Reject impossible values in Dart code.
- [ ] **Rate limiting on-device**: Throttle Firestore writes in Dart code (e.g., max 1 report per minute) to stay within free tier quotas

### 4.2 On-Device Logic (Replaces Cloud Functions)
> Cloud Functions require Blaze plan (paid). All this logic runs on-device instead.

- [ ] **onReportCreate (replaced)**: Generate PDF on-device via `pdf` package, update trend aggregation in Hive, schedule local notification via `flutter_local_notifications`
- [ ] **onCriticalValue (replaced)**: Check critical thresholds on-device after data entry, show immediate alert dialog + schedule local notification
- [ ] **scheduledDataCleanup (replaced)**: Run cleanup on app start using Hive — delete data older than retention period from local DB, then sync deletion to Firestore
- [ ] **reportShareFunction (replaced)**: Generate PDF on-device, share via `share_plus` (WhatsApp/email/AirDrop) — no server link needed
- [ ] **backupFunction (replaced)**: Export user data as encrypted JSON file to Google Drive / local storage via `share_plus`. User controls their own backup.

### 4.3 Authentication Enhancements (Firebase Auth — Free)
- [ ] **Google Sign-In** (free via Firebase Auth)
- [ ] **Apple Sign-In** (free via Firebase Auth, required for iOS if any social login)
- [ ] **Phone Auth** (free via Firebase Auth — SMS costs apply from Firebase but covered under free tier for low volume)
- [ ] **Biometric login** (fingerprint / face unlock via `local_auth` package — free, on-device)
- [ ] **Email verification enforcement** before app access (free)
- [ ] **Account deletion flow** (delete Firestore docs + Hive data — free, runs on-device)

### 4.4 Push Notifications (FCM — Free)
- [ ] **FCM integration** (free on Spark plan) for:
  - Medication reminders (scheduled locally, FCM for cross-device)
  - Follow-up test reminders (e.g., "Your HbA1c is due in 2 weeks")
  - Critical value alerts
  - Weekly health summary
- [ ] **Local notifications fallback** via `flutter_local_notifications` when offline or FCM unavailable
- [ ] **Notification preferences** in settings (per-type opt-in/out, stored in Hive)

### 4.5 Data Sync & Offline-First (Hive + Firestore Free Tier)
- [ ] **Offline-first architecture**:
  - Write all data to Hive first (instant, on-device)
  - Sync to Firestore when online (background isolate)
  - Queue mutations when offline in Hive, replay on reconnect
  - This also reduces Firestore reads (read from Hive, write to Firestore)
- [ ] **Conflict resolution**: Last-write-wins with timestamp + device ID (stored in Hive)
- [ ] **Sync status indicator** in UI (green = synced to Firestore, yellow = pending, red = failed)

### 4.6 On-Device Integrations (Free OS APIs)
- [ ] **HealthKit (iOS) / Google Fit (Android)**: Read steps, heart rate, blood pressure, weight from phone/watch — free OS APIs, no server needed
- [ ] **FHIR export**: Generate FHIR R4 JSON on-device from Hive data — no server needed. User can share the JSON file with their doctor/EHR.
- [ ] **OpenFDA drug interactions**: Instead of live API calls, bundle a local drug-interaction database as JSON (open-source datasets exist from OpenFDA — download once, include in assets). Zero API cost.
- [ ] **ICD-10 lookup**: Remove WHO ICD API dependency. Bundle a complete ICD-10 code lookup as local JSON (public domain data, ~5MB compressed). Works offline, zero cost.
- [ ] **Lab report scanning**: OCR via Google ML Kit (on-device, free) instead of lab LIMS API integrations (paid)

### 4.7 ML Engine Upgrade (On-Device)
- [ ] **Keep TensorFlow Lite**: Already bundled in assets, runs on-device, free. No need to switch to ONNX or Firebase ML.
- [ ] **Model versioning**: Store model version in Hive alongside report metadata — track which model produced each result
- [ ] **A/B testing on-device**: Run both rule engine and ML model, compare outputs locally, log discrepancies to Hive for developer review (not to a server)
- [ ] **Explainable AI (XAI)**: Compute SHAP-like feature importance on-device — highlight which input values contributed most to each disease prediction
- [ ] **Feedback collection**: "Was this diagnosis helpful?" button stores feedback in Hive. Developer can export anonymized CSV later for model improvement. No server needed.
- [ ] **Model updates via app update**: Bundle updated ML models in new app releases (no remote model hosting needed)

### 4.8 Rule Engine Upgrade (On-Device)
- [ ] **Rule versioning**: Store guideline version in rules JSON (e.g., `"guidelineVersion": "AHA-2017"`) — log which version was used in each report
- [ ] **Age/sex-specific rules**: Add demographic branching to rule engine (read age/sex from user profile in Hive)
- [ ] **Rule priority system**: Add priority field to rules (e.g., pregnancy BP rules override general BP rules when `isPregnant == true`)
- [ ] **Rule test suite**: Unit tests for every rule with known input/output pairs (Dart test framework — free)
- [ ] **Rule audit log**: Store which rules fired, with what values, in Hive alongside each report
- [ ] **Rule updates via app update**: Bundle updated rules in new app releases instead of Firebase Remote Config (which needs Blaze plan for production use)

---

## 5. REFERENCE RANGES UPGRADE

> All ranges bundled locally in reference_ranges.json. No API calls.

### 5.1 Demographic-Specific Ranges
- [ ] **Age-banded ranges**: Pediatric (0–12), Adolescent (13–17), Adult (18–64), Geriatric (65+)
- [ ] **Sex-specific ranges**: Male vs. Female for: creatinine, hemoglobin, hematocrit, HDL, testosterone, FSH/LH
- [ ] **Pregnancy-specific ranges**: Trimester-specific ranges for TSH, glucose, Hb, BP, liver enzymes
- [ ] **Menopausal status ranges**: Pre-menopausal vs. post-menopausal for FSH, estradiol, AMH

### 5.2 Missing Lab Categories
- [ ] **Complete Blood Count (CBC)**: WBC, RBC, Hemoglobin, Hematocrit, MCV, MCH, MCHC, Platelets
- [ ] **Thyroid Panel**: TSH, Free T4, Free T3, Total T4, Total T3
- [ ] **Iron Studies**: Serum Iron, TIBC, Ferritin, Transferrin Saturation
- [ ] **Vitamins**: B12, Folate, 25-OH Vitamin D
- [ ] **Inflammatory Markers**: CRP, ESR, Procalcitonin
- [ ] **Cardiac Markers**: Troponin, BNP/NT-proBNP, CK-MB
- [ ] **Coagulation**: PT/INR, APTT, D-Dimer
- [ ] **Urine Analysis**: Protein, Glucose, Ketones, Blood, pH, Specific Gravity
- [ ] **Bone Markers**: Calcium, Phosphorus, Alkaline Phosphatase, PTH
- [ ] **Tumor Markers**: PSA, CA-125, AFP, CEA, CA 19-9
- [ ] **Arterial Blood Gas**: pH, pO2, pCO2, HCO3, SaO2

---

## 6. OCR ENGINE UPGRADES

> All OCR runs on-device via Google ML Kit. No cloud OCR. Free.

### 6.1 Improved Parsing
- [ ] **Template-based parsing**: Pre-define templates for common lab report formats (ThyroCare, SRL, Dr. Lal, LabCorp, Quest) — bundled as JSON rules in assets
- [ ] **Multi-page PDF support**: Process each page sequentially using `pdfx` (already in pubspec) + ML Kit
- [ ] **Table detection**: Parse tabular lab results with column-awareness using regex + column position heuristics (on-device)
- [ ] **Image preprocessing**: Auto-rotate, de-skew, contrast enhancement before OCR (Dart image processing — on-device)
- [ ] ~~Handwriting OCR~~: Removed — requires cloud Vision API (paid). Keep to printed text OCR only.

### 6.2 Confidence & Validation
- [ ] **Per-field confidence score**: ML Kit returns confidence — map to green/yellow/red UI
- [ ] **Auto-validation**: Compare extracted values against plausible ranges from reference_ranges.json (on-device)
- [ ] **Cross-reference**: If same test appears on multiple pages, verify consistency
- [ ] **User feedback loop**: Track which fields users correct most in Hive → improve parsing templates in next app update

### 6.3 New Input Methods (All Free / On-Device)
- [ ] **Voice input**: Dictate lab values via OS speech-to-text (`speech_to_text` package — free, on-device)
- [ ] **Photo gallery import**: Select existing photos of lab reports from gallery (`image_picker` already in pubspec)
- [ ] ~~Barcode/QR scanner for lab import~~: Removed — requires lab partnership APIs. QR code can be used for sharing reports peer-to-peer instead.
- [ ] ~~Direct lab API~~: Removed — requires paid lab partnerships. OCR scanning replaces this.

---

## 7. TESTING & QUALITY

> All testing tools are free. No paid CI services required.

### 7.1 Unit Tests
- [ ] Rule engine: Every disease rule with edge cases
- [ ] eGFR calculator: Known input/output pairs (CKD-EPI formula verification)
- [ ] BMI calculator: Edge cases (height = 0, negative values)
- [ ] Unit converter: Round-trip conversion accuracy (mg/dL → mmol/L → mg/dL)
- [ ] Risk scoring: Boundary conditions (scores at 0%, 50%, 100%)
- [ ] OCR parser: Sample reports with expected output
- [ ] Reference ranges: Validate all ranges against published guidelines

### 7.2 Integration Tests
- [ ] End-to-end: Sign up → profile → enter data → generate report → view history
- [ ] OCR flow: Capture → parse → review → submit → report
- [ ] Auth flow: Sign up → verify email → login → forgot password → reset → login
- [ ] Offline flow: Enter data offline → sync when online → verify data integrity

### 7.3 Performance Tests
- [ ] Report generation time with 20+ lab values
- [ ] OCR processing time for multi-page PDFs
- [ ] App startup time (cold start, warm start)
- [ ] Memory usage with 100+ stored reports
- [ ] Hive database size with 1 year of data

### 7.4 Security Tests
- [ ] Firestore rules: Verify no cross-user data access
- [ ] API key exposure check (ensure no keys in source code)
- [ ] Injection via OCR input — validate all parsed values
- [ ] Authentication bypass attempts
- [ ] Hive data encryption for sensitive health data (use `hive_encrypted` or AES encryption layer)

---

## 8. DEPLOYMENT & DEVOPS

### 8.1 CI/CD (Free Tier)
- [ ] **GitHub Actions** (free for public repos, 2000 min/month for private): Lint → Test → Build on every PR
- [ ] **Fastlane** (free tool): Automate Play Store and App Store deployments
- [ ] **Separate Firebase projects**: One for dev (free Spark), one for prod (free Spark) — no paid staging server needed
- [ ] ~~Remote Config for feature flags~~: Removed — requires Blaze plan. Use on-device feature flags stored in Hive instead. Toggle features via app settings.

### 8.2 Monitoring & Analytics (Firebase Free Tier)
- [ ] **Crashlytics** (free): Auto-report crashes with stack traces
- [ ] **Analytics** (free): Track user flows, feature usage, disease detection rates
- [ ] **Performance Monitoring** (free): App start time, screen load times, network latency
- [ ] **Custom events** (free): "report_generated", "ocr_scan_completed", "disease_flagged"
- [ ] **In-app feedback form**: Store feedback in Firestore under user's own collection (free tier)

### 8.3 App Store Optimization
- [ ] Screenshots for all device sizes (6.7", 6.1", iPad)
- [ ] App description with keyword optimization
- [ ] Privacy policy URL (host on GitHub Pages — free)
- [ ] Data safety section (Google Play) / Nutrition label (App Store)
- [ ] Age rating justification (medical content)

---

## 9. COMPLIANCE & LEGAL

- [ ] **GDPR compliance**: Right to access, rectify, erase data (all done on-device + Firestore free tier); data portability (export as JSON/PDF); consent management
- [ ] **India DPDPA compliance**: Consent framework, data localization (Firebase has India regions)
- [ ] **FDA/CE medical device classification**: Determine if app qualifies as a medical device; if so, regulatory pathway
- [ ] **Disclaimer hardening**: Current disclaimer is minimal — needs legal review, explicit acceptance timestamp stored in Hive
- [ ] **Terms of Service & Privacy Policy**: Must be accepted before first use (host on GitHub Pages — free)
- [ ] **Data retention policy**: Define and enforce on-device (e.g., auto-delete Hive data older than 7 years on app start)
- [ ] ~~HIPAA BAA with Firebase~~: Removed — BAA requires Blaze plan. App disclaimer states it is NOT HIPAA-compliant and should not be used as a medical device. Users must acknowledge this.

---

## 10. ARCHITECTURE IMPROVEMENTS

### 10.1 Code Structure
- [ ] **Feature-first folder structure**: Group by feature (auth, reports, ocr, profile) not by type
- [ ] **Dependency injection**: Use Riverpod providers consistently; remove direct `FirebaseAuth.instance` calls from screens
- [ ] **Repository pattern**: Abstract data sources behind repositories (AuthRepository, ReportRepository, HealthDataRepository)
- [ ] **Use cases / Interactors**: Separate business logic from providers (Clean Architecture)

### 10.2 State Management
- [ ] **Migrate to Notifier/AsyncNotifier**: Current providers likely use ChangeNotifier patterns — should use Riverpod 2.x code-gen notifiers
- [ ] **Optimistic updates**: Update UI immediately from Hive, sync to Firestore in background
- [ ] **Error recovery**: Auto-retry failed operations with exponential backoff
- [ ] **State persistence**: Survive app restarts via Hive

### 10.3 Type Safety
- [ ] **Freezed models**: Replace hand-written model classes with Freezed for immutability + union types
- [ ] **Strict null safety**: Audit all `!` operators and replace with proper null handling
- [ ] **Enum for risk levels**: Replace string comparisons with typed enums
- [ ] **Strongly typed health data**: Instead of `Map<String, dynamic>`, use typed model classes per category

---

## 11. COMPLETELY FREE STACK SUMMARY

| Component | Technology | Cost |
|-----------|-----------|------|
| App Framework | Flutter | Free |
| State Management | Riverpod | Free |
| Local Storage | Hive | Free |
| Cloud Database | Firestore (Spark) | Free (1GB, 50K reads/day) |
| Auth | Firebase Auth (Spark) | Free (email, Google, Apple, phone) |
| OCR | Google ML Kit (on-device) | Free |
| ML | TensorFlow Lite (on-device) | Free |
| Push Notifications | FCM (Spark) + flutter_local_notifications | Free |
| PDF Generation | `pdf` package (on-device) | Free |
| Charts | fl_chart (on-device) | Free |
| Crash Reporting | Crashlytics (Spark) | Free |
| Analytics | Firebase Analytics (Spark) | Free |
| CI/CD | GitHub Actions | Free (2000 min/month) |
| Hosting (privacy policy) | GitHub Pages | Free |
| Drug Interactions | Bundled JSON (from OpenFDA public data) | Free |
| ICD-10 Lookup | Bundled local JSON | Free |
| Health Data Import | HealthKit / Google Fit (OS APIs) | Free |
| Data Export | CSV/PDF/FHIR JSON (on-device) | Free |
| Biometric Auth | `local_auth` (on-device) | Free |
| Voice Input | `speech_to_text` (on-device) | Free |
| Encryption | AES via Dart `encrypt` package | Free |

**Total server cost: $0/month**

---

## 12. PRIORITY MATRIX

| Priority | Item | Impact | Effort | Cost |
|----------|------|--------|--------|------|
| P0 | Fix diseases.json schema inconsistency | High | Low | Free |
| P0 | Fix missing detectionMethod on D074 | High | Low | Free |
| P0 | Fix null safety on route extras | High | Low | Free |
| P0 | Add email verification gate | High | Low | Free |
| P0 | Fix HDL reference range | High | Low | Free |
| P0 | Firestore security rules | High | Low | Free |
| P0 | Remove WHO ICD API dependency, use local JSON | High | Low | Free |
| P1 | Add CBC reference ranges | High | Medium | Free |
| P1 | Add thyroid panel ranges | High | Medium | Free |
| P1 | Demographic-specific reference ranges | High | High | Free |
| P1 | Emergency value alerts (on-device) | High | Medium | Free |
| P1 | Loading states on all screens | Medium | Low | Free |
| P1 | Report pagination (Hive lazy loading) | Medium | Low | Free |
| P1 | Offline-first architecture (Hive → Firestore) | High | High | Free |
| P2 | Dashboard redesign | High | Medium | Free |
| P2 | Data entry stepper flow | Medium | Medium | Free |
| P2 | Design system | High | High | Free |
| P2 | Push notifications (FCM + local) | Medium | Medium | Free |
| P2 | Google/Apple Sign-In | Medium | Medium | Free |
| P2 | Add 10+ new diseases (rule engine) | High | High | Free |
| P2 | Rule engine audit trail (Hive) | High | Medium | Free |
| P2 | Bundle ICD-10 lookup JSON | Medium | Medium | Free |
| P2 | Bundle drug interaction database | Medium | Medium | Free |
| P3 | HealthKit/Google Fit (free OS APIs) | Medium | High | Free |
| P3 | Medication tracker (Hive + local notifications) | Medium | Medium | Free |
| P3 | FHIR export (on-device JSON generation) | Medium | High | Free |
| P3 | Internationalization | Medium | High | Free |
| P3 | Feature-first refactor | Medium | High | Free |
| P3 | Biometric login | Medium | Low | Free |
| P3 | Voice input for lab values | Low | Medium | Free |
| P4 | Explainable AI (on-device SHAP) | Low | High | Free |
| P4 | Pediatric category | Low | High | Free |
| P4 | Wearable integration (HealthKit/Google Fit) | Low | High | Free |
| P4 | Symptom checker (on-device) | Low | Medium | Free |

---

## 13. WHAT WAS REMOVED FROM ORIGINAL PLAN (requires paid services)

| Removed Item | Why | Free Replacement |
|-------------|-----|------------------|
| Cloud Functions | Requires Blaze plan ($0.18/GB-month) | On-device logic in Dart |
| Firebase Remote Config | Production use needs Blaze plan | Feature flags in Hive |
| WHO ICD API | Needs OAuth server + credentials | Bundled local ICD-10 JSON |
| Lab LIMS API integration | Paid partnerships required | OCR scanning of printed reports |
| Doctor web portal | Requires server hosting | Share PDF via WhatsApp/email/QR |
| Remote ML model hosting | Needs Cloud Storage (Blaze plan) | Bundle models in app assets |
| Cloud Storage backups | Needs Blaze plan | Export encrypted JSON to Google Drive/local |
| HIPAA BAA | Requires Blaze plan | Disclaimer: not HIPAA-compliant |
| Handwriting OCR | Requires Cloud Vision API (paid) | Printed text OCR only (ML Kit) |
| Real-time lab API data pull | Paid third-party APIs | Manual entry + OCR scanning |

---

*Document generated from full codebase audit. Every item is achievable at $0/month using on-device computation, Hive local storage, and Firebase Spark Plan (free tier).*
