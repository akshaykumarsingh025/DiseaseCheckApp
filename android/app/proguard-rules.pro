# ── Flutter engine ──────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ── Razorpay ────────────────────────────────────────────────────────────────
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class proguard.annotation.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# ── On-device LiteRT / Gemma ────────────────────────────────────────────────
-keep class com.google.ai.edge.** { *; }

# ── LiveKit + WebRTC ────────────────────────────────────────────────────────
-keep class io.livekit.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# ── Google Mobile Ads (AdMob) ───────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.play.core.**

# ── Firebase / Google Play services ─────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── ML Kit text recognition (optional language scripts not bundled) ──────────
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
