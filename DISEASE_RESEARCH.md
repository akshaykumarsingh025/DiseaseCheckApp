# DiseaseCheckApp - Disease List & Research Report

## Part 1: Current Diseases Diagnosed in the App

The app currently diagnoses **44 diseases/conditions** through rule-based clinical checks:

### Cardiovascular Diseases
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Hypertension (Normal/Elevated/Stage 1/Stage 2/Crisis) | I10 | Blood Pressure (Systolic/Diastolic) |
| Hypercholesterolemia | E78.0 | Lipid Panel |
| Cardiac Risk / Myocardial Injury | I25.1 | Cardiac Markers |
| Heart Failure Risk | I25.1 | BNP/NT-proBNP |

### Metabolic & Diabetes
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Type 2 Diabetes | E11 | FBS, HbA1c, PP, Random Glucose |
| Pre-Diabetes | E11 | Blood Sugar Panel |

### Blood & Hematology
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Anemia (Mild/Moderate/Severe) | D64.9 | CBC (Hb, Hct, MCV, MCH) |
| Iron Deficiency Anemia | D64.9 | CBC + MCV <80 |
| Vitamin B12/Folate Deficiency Anemia | D64.9 | CBC + MCV >100 |
| Leukocytosis | D75.9 | WBC >11,000 |
| Leukopenia | D75.9 | WBC <4,000 |
| Thrombocytopenia | D75.9 | Platelets <150,000 |
| Thrombocytosis | D75.9 | Platelets >400,000 |

### Liver Diseases
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Liver Disease Risk | K76.0 | LFT (ALT, AST, ALP, Bilirubin, Albumin, GGT) |
| Jaundice | K76.0 | Bilirubin >2.5 |
| Fatty Liver (Steatosis) | K76.0 | OCR Imaging Keywords |

### Kidney Diseases
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Chronic Kidney Disease (Stage 1-5) | N18 | eGFR, Creatinine, BUN |
| Gout Risk | N18 | Uric Acid >7.0 |
| Hyperkalemia | N18 | Potassium >5.0 |
| Hypokalemia | N18 | Potassium <3.5 |
| Hypernatremia | N18 | Sodium >145 |
| Hyponatremia | N18 | Sodium <135 |
| Calcium Deficiency | N18 | Calcium <8.5 |
| Kidney Stones | N20.0 | OCR Imaging Keywords |

### Thyroid Disorders
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Hypothyroidism | E03 | TSH >4.0, Free T4 <0.8 |
| Hyperthyroidism | E03 | TSH <0.4, Free T3 >4.4 |

### Nutritional & Iron
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Iron Deficiency | E61.1 | Ferritin, Serum Iron, TIBC |

### Women's Health
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| PCOS Risk Profile | E28.2 | Hormonal Panel |
| Diminished Ovarian Reserve | N97.9 | AMH <1.0, FSH >10.0 |
| Menopause / POI | N95.1 | FSH >30, Estradiol <30 |
| Pregnancy Readiness Flaws | Z31.8 | Composite |
| Cervical Dysplasia | Z12.4 | Pap Smear, HPV |

### Vital Signs Abnormalities
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Tachycardia | R68.8 | Heart Rate >100 |
| Bradycardia | R68.8 | Heart Rate <60 |
| Hypoxia | R68.8 | SpO2 <95% |
| Fever | R68.8 | Temperature >100.4F |
| Hypothermia | R68.8 | Temperature <97F |
| Tachypnea | R68.8 | Respiratory Rate >20 |
| Bradypnea | R68.8 | Respiratory Rate <12 |

### Imaging (OCR-based)
| Disease | ICD Code | Detection Method |
|---------|----------|------------------|
| Pneumonia | J18.9 | OCR Imaging Keywords |
| Enlarged Prostate (BPH) | N40 | OCR Imaging Keywords |
| Gallstones | K80.20 | OCR Imaging Keywords |

---

## Part 2: Additional Diseases That Can Be Added

### A. HIGH PRIORITY - Common Diseases from Lab Tests

#### Metabolic & Endocrine (10 diseases)
| Disease | ICD Code | Lab Tests Needed | Priority |
|---------|----------|------------------|----------|
| Metabolic Syndrome | E88.9 | FBS, HbA1c, Triglycerides, HDL, BP, Waist | HIGH |
| Insulin Resistance | E11 | Fasting Insulin, HOMA-IR | HIGH |
| Hypotension (Low BP) | I95 | Systolic <90, Diastolic <60 | HIGH |
| Gestational Diabetes | O24.4 | OGTT, HbA1c in pregnancy | MEDIUM |
| Subclinical Hypothyroidism | E03.9 | TSH 4.0-10.0, Normal Free T4 | MEDIUM |
| Hyperparathyroidism | E21 | PTH, Calcium, Phosphate | MEDIUM |
| Cushing's Syndrome | E24 | Cortisol (AM/PM), ACTH | LOW |
| Addison's Disease | E27 | Cortisol, ACTH, Electrolytes | LOW |
| Polycystic Kidney Disease | Q61.2 | Imaging + eGFR | LOW |
| Insulinoma | D13.7 | Fasting Glucose, Insulin | LOW |

#### Cardiovascular (8 diseases)
| Disease | ICD Code | Lab Tests Needed | Priority |
|---------|----------|------------------|----------|
| Coronary Artery Disease Risk | I25.1 | Lipid Panel + Risk Factors | HIGH |
| Peripheral Artery Disease | I73.9 | ABI (Ankle-Brachial Index) | MEDIUM |
| Atrial Fibrillation Risk | I48 | ECG findings, CHA2DS2-VASc | MEDIUM |
| Atherosclerosis Risk | I70 | Lipid Panel, CRP, Age | MEDIUM |
| Heart Block | I44 | ECG findings | LOW |
| Valvular Heart Disease | I35 | Echocardiogram findings | LOW |
| Deep Vein Thrombosis | I80 | D-Dimer, Clinical | LOW |
| Pulmonary Embolism | I26 | D-Dimer, Clinical | LOW |

#### Liver & GI (8 diseases)
| Disease | ICD Code | Lab Tests Needed | Priority |
|---------|----------|------------------|----------|
| Non-Alcoholic Fatty Liver Disease (NAFLD) | K76.0 | FLI Score (BMI, Waist, TG, GGT) | HIGH |
| Hepatitis B Screening | B18.1 | HBsAg, Anti-HBs, Anti-HBc | HIGH |
| Hepatitis C Screening | B18.2 | Anti-HCV, HCV RNA | HIGH |
| Liver Cirrhosis Risk | K74.6 | APRI, FIB-4 Scores | MEDIUM |
| Alcoholic Liver Disease | K70 | GGT, AST/ALT Ratio | MEDIUM |
| Pancreatitis | K85 | Amylase, Lipase | MEDIUM |
| GERD/Acid Reflux | K21 | Clinical + pH Monitoring | LOW |
| Celiac Disease | K90.0 | Anti-tTG, EMA | LOW |

#### Kidney & Electrolytes (6 diseases)
| Disease | ICD Code | Lab Tests Needed | Priority |
|---------|----------|------------------|----------|
| Acute Kidney Injury | N17 | Creatinine, BUN, Urine Output | HIGH |
| Nephrotic Syndrome | N04 | Proteinuria, Albumin, Lipids | MEDIUM |
| Urinary Tract Infection (Extended) | N39.0 | Urine Culture, WBC, Nitrite | HIGH |
| Proteinuria | R80 | Urine Protein, Albumin | MEDIUM |
| Hematuria | R31 | Urine RBC | MEDIUM |
| Renal Stone Risk | N20 | Urine Calcium, Oxalate, Uric Acid | MEDIUM |

#### Blood & Hematology (8 diseases)
| Disease | ICD Code | Lab Tests Needed | Priority |
|---------|----------|------------------|----------|
| Vitamin D Deficiency | E55.9 | 25-OH Vitamin D | HIGH |
| Vitamin B12 Deficiency | E53.8 | Vitamin B12, MMA, Homocysteine | HIGH |
| Folate Deficiency | E53.8 | Folate, Homocysteine | HIGH |
| Magnesium Deficiency | E83.2 | Serum Magnesium | MEDIUM |
| Thalassemia Trait Screen | D56 | Mentzer Index (MCV/RBC) | MEDIUM |
| Polycythemia | D45 | RBC, Hct, EPO | LOW |
| Sickle Cell Trait | D57.3 | Hb Electrophoresis | MEDIUM |
| Hemophilia Screen | D68 | PT, PTT, Factor Levels | LOW |

#### Cancer Screening (5 diseases)
| Disease | ICD Code | Lab Tests Needed | Priority |
|---------|----------|------------------|----------|
| Prostate Cancer Risk (PSA) | C61 | Total PSA, Free PSA, Ratio | HIGH |
| Colorectal Cancer Risk | C18 | Fecal Occult Blood, CEA | MEDIUM |
| Breast Cancer Risk | C50 | BRCA, Family History | LOW |
| Ovarian Cancer Risk | C56 | CA-125, HE4 | LOW |
| Thyroid Cancer Risk | C73 | TSH, Ultrasound | MEDIUM |

### B. INFECTIOUS DISEASES (Screening)

| Disease | ICD Code | Tests | Priority |
|---------|----------|-------|----------|
| Dengue | A90 | NS1 Antigen, IgM/IgG | HIGH |
| Malaria | B50 | Rapid Diagnostic Test | HIGH |
| Typhoid | A01 | Widal, Typhi IgM | HIGH |
| Tuberculosis | A15 | TB IgG/IgM, Clinical | MEDIUM |
| HIV | B20 | Rapid HIV Test | HIGH |
| Syphilis | A51 | VDRL, RPR, FTA-ABS | MEDIUM |
| COVID-19 | U07.1 | Rapid Antigen, PCR | MEDIUM |
| Chikungunya | A92 | IgM, Clinical | LOW |

### C. AUTOIMMUNE & INFLAMMATORY

| Disease | ICD Code | Tests | Priority |
|---------|----------|-------|----------|
| Rheumatoid Arthritis | M06 | RA Factor, Anti-CCP, CRP, ESR | MEDIUM |
| Systemic Lupus Erythematosus | M32 | ANA, Anti-dsDNA, Complement | MEDIUM |
| Osteoporosis | M81 | Calcium, Vitamin D, BMD | HIGH |
| Gout (Standalone) | M10 | Uric Acid, Joint Aspiration | HIGH |
| Ankylosing Spondylitis | M45 | HLA-B27, ESR, CRP | LOW |
| Psoriatic Arthritis | L40.5 | Clinical, RF, Anti-CCP | LOW |

### D. PREGNANCY & PRENATAL

| Disease | ICD Code | Tests | Priority |
|---------|----------|-------|----------|
| Pre-eclampsia Risk | O14.9 | BP, Urine Protein, Platelets | HIGH |
| Gestational Hypertension | O13 | BP Monitoring | HIGH |
| Pregnancy Anemia | O99.0 | Hemoglobin, Ferritin | HIGH |
| HELLP Syndrome | O14.2 | Platelets, AST, ALT, LDH | MEDIUM |
| Ectopic Pregnancy | O00 | hCG, Ultrasound | LOW |
| Thyroid in Pregnancy | O99.2 | TSH, Free T4 | HIGH |
| Rh Incompatibility | O36.0 | Blood Type, Antibody Screen | HIGH |

### E. MENTAL HEALTH & NEUROLOGICAL

| Disease | ICD Code | Tests | Priority |
|---------|----------|-------|----------|
| Depression Screen | F32 | PHQ-9 Questionnaire | MEDIUM |
| Anxiety Screen | F41 | GAD-7 Questionnaire | MEDIUM |
| Dementia Risk | F03 | MMSE, Clinical | LOW |
| Migraine | G43 | Clinical, Family History | LOW |
| Epilepsy Risk | G40 | EEG (referral) | LOW |

---

## Part 3: Qwen 3.5:0.8b (0.6B) Model for Mobile

### Model Specifications

| Parameter | Qwen3-0.6B | Qwen3-0.8B |
|-----------|------------|------------|
| Parameters | 0.6 billion | 0.8 billion |
| Size (Q4_K_M) | ~523MB | ~600MB |
| Context Length | 32K tokens | 32K tokens |
| Languages | 119+ | 119+ |
| License | Apache 2.0 | Apache 2.0 |

### Mobile Deployment Options

#### 1. Ollama (Recommended for development)
```bash
# Download model
ollama pull qwen3:0.6b

# Run locally
ollama run qwen3:0.6b

# API server
ollama serve
```

#### 2. Flutter Integration Options

| Option | Pros | Cons |
|--------|------|------|
| **llama.cpp (via dart binding)** | Full offline, fast | Complex setup |
| **MNN (Alibaba)** | Optimized for mobile | Limited documentation |
| **TensorFlow Lite** | Already in your project | Limited LLM support |
| **MLC-LLM** | Excellent mobile perf | Advanced setup |
| **Remote API** | Easy to implement | Requires internet |

#### 3. Recommended Approach for DiseaseCheckApp

**Hybrid Solution:**
- Keep rule-based engine for clinical accuracy
- Use Qwen for natural language features
- Optional: Cache model on-device for offline

### Unique Features with Qwen3

#### Feature 1: Smart Lab Report Chat
- Ask questions like "What do these results mean?"
- Get personalized explanations in simple language
- Multi-language support (119+ languages)

#### Feature 2: Symptom-to-Test Recommendation
- User describes symptoms
- Qwen suggests which lab tests to get
- Connects symptoms to potential conditions

#### Feature 3: Health Education Chatbot
- Explain diseases in simple terms
- Diet/lifestyle recommendations
- Medication side effects info

#### Feature 4: Voice Input Analysis
- Voice-to-text for symptom entry
- Natural language processing of patient concerns

#### Feature 5: Report Summary Generator
- Auto-generate plain-English summaries
- Explain abnormal values
- Actionable next steps

#### Feature 6: Multilingual Support
- Translate reports to user's language
- Support for 119+ languages
- Local health guidelines per region

### Implementation Roadmap

1. **Phase 1**: Ollama API integration (easy start)
2. **Phase 2**: On-device quantization (Q4_K_M ~500MB)
3. **Phase 3**: Custom fine-tuning for medical domain

---

## Part 4: Additional Features for the App

### A. Core Features

#### 1. AI-Powered Features
- [ ] Smart symptom checker with ML classification
- [ ] Drug interaction checker (integrate openFDA API)
- [ ] Personalized health recommendations
- [ ] Risk prediction models (10-year CVD risk, etc.)
- [ ] Meal/exercise recommendations based on conditions

#### 2. Data & Connectivity
- [ ] Apple Health / Google Fit integration
- [ ] Wearable device sync (Fitbit, Garmin, etc.)
- [ ] Cloud backup with encryption
- [ ] Data export in multiple formats (JSON, CSV, PDF)
- [ ] QR code sharing of reports

#### 3. User Experience
- [ ] Dark/Light mode with auto-switch
- [ ] Offline mode with sync queue
- [ ] Multi-language support ( Hindi, Spanish, etc.)
- [ ] Accessibility features (screen reader support)
- [ ] Widget support for Android/iOS

### B. Healthcare Provider Features

#### 4. Provider Dashboard
- [ ] Doctor portal for patient reports
- [ ] Secure messaging between patient and doctor
- [ ] Prescription upload and tracking
- [ ] Appointment scheduling integration
- [ ] Second opinion feature

#### 5. Telemedicine Integration
- [ ] Video consultation booking
- [ ] Online prescription
- [ ] Lab test booking (integrate with local labs)

### C. Advanced Analytics

#### 6. Predictive Health
- [ ] Health score tracking over time
- [ ] Seasonal health predictions
- [ ] Family health history tracking
- [ ] Genetic risk assessment (integration with 23andMe, etc.)
- [ ] Medication adherence tracking

#### 7. Population Health Insights
- [ ] Anonymous health trends (opt-in)
- [ ] Local health alerts (outbreaks in area)
- [ ] Health tips based on season/location
- [ ] Comparison with population averages

### D. Specialized Health Modules

#### 8. Chronic Disease Management
- [ ] Diabetes management (insulin tracking, carb counting)
- [ ] Hypertension tracking (BP logs, medication reminders)
- [ ] Heart failure monitoring (weight, symptoms)
- [ ] Asthma/COPD action plan
- [ ] Mental health journaling

#### 9. Wellness & Lifestyle
- [ ] Sleep tracking integration
- [ ] Stress level assessment
- [ ] Hydration tracking
- [ ] Step count & activity tracking
- [ ] Calorie & macro tracking

#### 10. Emergency Features
- [ ] Emergency contact一键分享
- [ ] Medical ID (allergies, medications)
- [ ] Emergency report generation
- [ ] Location-based hospital finder

### E. Gamification & Engagement

#### 11. Health Gamification
- [ ] Achievement badges
- [ ] Health streaks (logging daily)
- [ ] Challenges (30-day health challenges)
- [ ] Points system for healthy actions
- [ ] Leaderboards (opt-in)

#### 12. Community Features
- [ ] Health forums (moderated)
- [ ] Success stories
- [ ] Health tips from experts
- [ ] Newsletter with health insights

### F. Monetization (Optional)

#### 13. Premium Features
- [ ] Advanced analytics
- [ ] Unlimited report history
- [ ] Priority support
- [ ] Expert consultations (paid)
- [ ] Personalized meal plans

#### 14. Enterprise Solutions
- [ ] Corporate health dashboards
- [ ] Employee wellness programs
- [ ] Insurance integration
- [ ] Clinical trial matching

---

## Part 5: Recommended Implementation Priority

### Phase 1 - Quick Wins (1-3 months)
1. Add 10 most common additional diseases (Metabolic Syndrome, Vit D, B12, etc.)
2. Implement basic drug interaction checker (openFDA API)
3. Add Apple Health / Google Fit sync
4. Multi-language support (Hindi, Spanish)

### Phase 2 - Core Enhancement (3-6 months)
5. Qwen3 integration for chat features
6. Chronic disease management modules
7. Predictive health scoring
8. Provider portal

### Phase 3 - Advanced Features (6-12 months)
9. On-device ML models (TFLite)
10. Full lab test catalog expansion
11. Telemedicine integration
12. Enterprise features

---

## References

- Qwen3 Technical Report: https://arxiv.org/abs/2505.09388
- Ollama: https://ollama.com
- HuggingFace: https://huggingface.co/Qwen/Qwen3-0.6B
- WHO Clinical Guidelines
- ADA Standards of Care
- AHA/ACC Guidelines
- NCEP ATP III Guidelines

---

*Report generated for DiseaseCheckApp - Flutter Health Check Application*
