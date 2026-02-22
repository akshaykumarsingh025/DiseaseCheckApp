# 🏥 DiseaseCheckApp

AI-powered health diagnosis mobile app that detects **67+ diseases** using verified WHO/AHA/ADA guidelines and ML models.

## 🎯 What It Does

Users input their medical data (blood reports, vitals, pregnancy data, etc.) and receive an AI-powered health risk assessment — completely **offline, on-device**, with **no server required**.

## 🔬 Key Features

- **67 diseases** screened across 12 medical categories
- **17 health data input categories** (blood sugar, CBC, lipid panel, liver, kidney, thyroid, urine, stool, pregnancy, etc.)
- **Hybrid detection**: Rule-based engine (WHO/AHA/ADA thresholds) + TensorFlow Lite ML models
- **100% offline** — all ML models run on-device
- **Privacy first** — no health data leaves the phone
- **Free verified data** — WHO ICD-11, NIH, openFDA APIs
- **Color-coded risk reports** (🟢 Low / 🟡 Moderate / 🔴 High)

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Android → Web → iOS) |
| ML On-Device | TensorFlow Lite |
| Local Storage | Hive |
| State Management | Riverpod |
| APIs | WHO ICD-11, NIH, openFDA |

## 📋 Full Plan

See [PLAN.md](PLAN.md) for the complete implementation plan with all APIs, datasets, code samples, and build instructions.

## ⚠️ Disclaimer

This app provides health risk assessments for informational purposes only. It is NOT a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider.

## 📄 License

MIT License
