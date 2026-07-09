# IQ — Gut Intelligence

> A personal full-stack project for tracking gut health, spotting food triggers, and predicting Crohn's flare risk — built with SwiftUI, Python ML, and FastAPI.

**Status:** Personal / portfolio project · Not on the App Store

---

## About

**IQ (Gut Intelligence)** started as a way to explore a real problem: people living with Crohn's disease often track symptoms and diet in scattered notes, but rarely get clear, actionable answers to the question that matters most — *how likely am I to flare soon, and why?*

This repo is the full stack behind that idea:

- A **native iOS app** (SwiftUI) for daily symptom and food logging, analytics, and an AI assistant
- A **flare prediction engine** that scores risk from symptoms, diet, sleep, stress, and historical patterns
- An **ML pipeline** (scikit-learn) with personalized cold-start learning per user
- A **FastAPI backend** that wraps the model and syncs user history

It's a learning and portfolio project — not a published product. The focus is on thoughtful UX, a clean architecture, and building something that could genuinely help someone understand their body better.

### What it does

| Area | Highlights |
|------|------------|
| **Tracking** | Symptom severity scoring, food logging with dietary tags |
| **Prediction** | 5-component flare risk engine + ML personalization |
| **Insights** | Activity heatmap calendar, analytics dashboard, trend charts |
| **Design** | Liquid glass UI, circular risk visualization, native SwiftUI |

### Tech stack

| Layer | Tools |
|-------|-------|
| **iOS** | SwiftUI, MVVM, Core ML, Charts |
| **ML** | Python, scikit-learn, Gradient Boosting, Core ML export |
| **Backend** | FastAPI, Supabase |
| **Design** | Custom design system, GitHub-style heatmaps |

### Proof at a glance

| Signal | Result (local / synthetic data) |
|--------|----------------------------------|
| Held-out ROC-AUC | **0.71** |
| Predict latency (p50) | **~1.8 ms** |
| Elevated vs calm risk | **0.51** vs **0.18** |
| What-if (sleep + lower stress) | **−8.2%** risk |

Full JSON samples and methodology: **[Samples & Benchmarks](docs/SAMPLES_AND_BENCHMARKS.md)**

---

## Quick Start

### Open the iOS project
```bash
open ios/IQ.xcodeproj
```

### Build & Run
1. Select a simulator or device in Xcode
2. Press `Cmd + R`
3. The app launches with onboarding and the home risk dashboard

### Run the ML API
```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # optional: add Supabase keys
uvicorn server:app --reload --port 8000
```

Detailed env vars, Supabase schema, and troubleshooting: **[Backend Setup](docs/BACKEND_SETUP.md)**

### Run ML tests
```bash
cd ml_model
python3 -m venv .venv && source .venv/bin/activate
pip install pandas scikit-learn numpy pytest
pytest tests/ -q
```

Full QA checklist (API curls + iOS manual script): **[Testing & QA](docs/TESTING.md)**

---

## Project Structure

```
├── ios/IQ/          # Native iOS app (SwiftUI)
├── ml_model/        # Flare prediction model + Core ML export + pytest suite
├── backend/         # FastAPI server wrapping the ML pipeline
├── docs/            # Testing, backend setup, samples & benchmarks
├── PRD.md           # Product requirements & feature spec
└── iOS_SETUP.md     # Detailed Xcode setup guide
```

---

## Features

- Symptom tracking with severity scoring
- Food logging with dietary tags
- Flare risk prediction (rule-based engine + ML layer)
- Activity heatmap calendar (GitHub-style)
- Analytics dashboard with trends
- AI assistant chat
- Local data persistence (UserDefaults)
- Liquid glass UI design system

---

## Requirements

- iOS 16.0+
- Xcode 15.4+
- Swift 5.9
- Python 3.9+ (for ML / backend)

---

## Documentation

| Doc | What it covers |
|-----|----------------|
| **[Backend Setup](docs/BACKEND_SETUP.md)** | venv, dependencies, `.env`, Supabase `logs` schema, API surface |
| **[Testing & QA](docs/TESTING.md)** | pytest, API smoke curls, iOS manual QA, quality gates |
| **[Samples & Benchmarks](docs/SAMPLES_AND_BENCHMARKS.md)** | Accuracy metrics, latency, example predict/simulate JSON |
| **[iOS Setup Guide](ios/README.md)** | Architecture, Xcode setup, troubleshooting |
| **[PRD](PRD.md)** | Full product requirements document |

---

## About the author

Built by **Vaibhav** as a hands-on exploration of health-tech UX, on-device ML, and full-stack mobile development. Feedback and ideas welcome — open an issue or reach out on [GitHub](https://github.com/Vaibhav100968).

---

**Version:** 1.0 · **Platform:** iOS 16+ · **Last updated:** July 2026
