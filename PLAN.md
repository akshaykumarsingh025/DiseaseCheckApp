# Fix: Separate Doctor & Patient Experiences for OPD Video Call

## Problem

Both the **doctor** (`doctor.opd.test@diseasecheck.app`) and **patient** (`patient.opd.test@diseasecheck.app`) see the exact same dashboard and OPD booking screen. This causes:

1. **Doctor sees the patient booking flow** — date picker, slot selector, "Pay ₹199" — instead of a doctor console showing incoming patient appointments.
2. **"Slot already booked" error** — When testing with Emergency OPD, both accounts try to create the same appointment (deterministic `appointmentId`), causing a conflict.
3. **Can't test the video call flow** — Because the doctor can't see patient bookings or start a consultation.

## Test Accounts

| Role    | Email                              | Password      | UID (Firebase)                 |
|---------|------------------------------------|---------------|--------------------------------|
| Doctor  | doctor.opd.test@diseasecheck.app   | OpdTest@199   | `pvqEOm1BeybUSycUhhhUmSZoZnP2` |
| Patient | patient.opd.test@diseasecheck.app  | OpdTest@199   | *(different UID)*              |

## Proposed Changes

### 1. Add `isDoctor` helper to FeatureFlags

#### [MODIFY] [feature_flags.dart](file:///d:/Software/Projects/DiseaseCheckApp/lib/config/feature_flags.dart)

Add a static method that checks if the current Firebase Auth user is the doctor:

```dart
static bool get isDoctor {
  final user = FirebaseAuth.instance.currentUser;
  return user != null && user.uid == doctorUserId;
}
```

This centralizes the check so all screens use a single source of truth.

---

### 2. Create Doctor OPD Dashboard Screen

#### [NEW] [doctor_opd_screen.dart](file:///d:/Software/Projects/DiseaseCheckApp/lib/screens/doctor_opd_screen.dart)

A new screen **only the doctor sees** when navigating to `/online-opd`. Shows:

- **Today's Appointments** — all patient bookings for today with "Start Consultation" buttons
- **Upcoming Appointments** — future bookings grouped by date
- **Past Appointments** — completed consultations
- **Active consultation card** — if a call is in progress, show a prominent "Rejoin" button

No date picker, no booking flow, no payment. Doctor's role is to **accept and start** consultations.

---

### 3. Route Doctor to Doctor OPD Screen

#### [MODIFY] [app.dart](file:///d:/Software/Projects/DiseaseCheckApp/lib/app.dart)

Change the `/online-opd` route to check `FeatureFlags.isDoctor`:

```dart
GoRoute(
  path: '/online-opd',
  builder: (context, state) =>
    FeatureFlags.isDoctor
      ? const DoctorOpdScreen()
      : const OnlineOpdScreen(),
),
```

---

### 4. Customize Dashboard for Doctor

#### [MODIFY] [dashboard_screen.dart](file:///d:/Software/Projects/DiseaseCheckApp/lib/screens/dashboard_screen.dart)

When logged in as doctor:
- Change the "Online OPD - ₹199" card text to **"Doctor Console — Manage OPD"**
- Hide patient-only cards that don't apply to the doctor (e.g., "Enter New Data", "Scan Medical Report", etc.)
- Show a **"Today's Patients"** count badge on the OPD card

---

### 5. Fix Emergency OPD for Testing

#### [MODIFY] [appointment_service.dart](file:///d:/Software/Projects/DiseaseCheckApp/lib/services/appointment_service.dart)

The `createEmergencyAppointment` generates a deterministic `appointmentId` from `doctorId + date + startTime`. When both doctor and patient test at the same time, they generate the same ID → conflict.

Fix: Include the `patientId` in the appointment ID so each user's emergency booking is unique. Also, skip the "slot available" check for emergency appointments since they're instant.

---

### 6. Skip Profile Setup for Doctor

#### [MODIFY] [app.dart](file:///d:/Software/Projects/DiseaseCheckApp/lib/app.dart)

The router redirect forces all authenticated users without a profile to `/profile-setup`. The doctor account may not have a profile set up, causing them to get stuck.

Fix: Skip the profile-setup redirect for the doctor UID.

---

## Testing Plan

After these changes, here's how to test the full video call flow:

### Step-by-step

1. **Login as Patient** (`patient.opd.test@diseasecheck.app`)
2. Go to **Online OPD** → Select a date → Select a slot → Pay ₹199 (dummy) → Appointment booked
3. **Login as Doctor** (`doctor.opd.test@diseasecheck.app`) on a different device/emulator
4. Go to **Doctor Console** → See the patient's appointment listed
5. When appointment time arrives → Doctor taps **"Start Consultation"** → Jitsi room opens + Firestore status = `started`
6. **Patient's screen auto-updates** (StreamBuilder) → Shows "Dr. Deepika is ready!" → Patient taps **"Join Video Call"**
7. Both are in the same Jitsi room ✅

### Quick Testing with Emergency OPD

1. Login as Patient → Tap **"Emergency OPD Test"** → Appointment created instantly → Navigates to video call → Shows "Waiting for doctor..."
2. Login as Doctor → Doctor Console shows the emergency appointment → Tap **"Start Consultation"**
3. Patient screen auto-updates → "Join Video Call" becomes available

## Verification

- [ ] `flutter analyze` passes with no errors
- [ ] Doctor login → sees Doctor Console (not patient booking flow)
- [ ] Patient login → sees normal booking flow
- [ ] Doctor can start a consultation → patient can join
- [ ] Emergency OPD works for both accounts without "slot already booked" error
- [ ] APK builds successfully
