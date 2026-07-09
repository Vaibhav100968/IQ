# Testing & Quality Assurance

How IQ is verified across the iOS app, ML model, and FastAPI backend.

**Scope:** Personal / portfolio project — not clinical validation. These checks prove the stack runs correctly and that risk scores behave as expected under known inputs.

---

## Quick checklist

| Layer | What to run | Pass criteria |
|-------|-------------|---------------|
| **ML unit smoke** | `pytest ml_model/tests -q` | All tests green |
| **ML demo script** | `python ml_model/main.py` | Prints prediction + what-if deltas |
| **API health** | `curl localhost:8000/health` | `{"status":"ok","model":"ready"}` |
| **API predict** | `POST /predict` with sample body | `final_risk` in `[0, 1]` + explanations |
| **iOS build** | Xcode → Product → Build (`Cmd+B`) | Build succeeds on iOS 16+ simulator |
| **iOS smoke** | Run app → log symptoms/food → check Home risk | Risk disk updates; Analytics shows factors |

---

## 1. ML model tests

### Run the automated suite

```bash
cd ml_model
python3 -m venv .venv
source .venv/bin/activate
pip install pandas scikit-learn numpy pytest
pytest tests/ -q
```

The suite covers:

- Global model trains and exposes `feature_cols`
- Cold-start `predict()` returns a blended `final_risk` in `[0, 1]`
- High-symptom inputs score higher than low-symptom inputs
- `explain()` returns personalization status + factor lists
- `simulate()` reports a negative delta when stress/sleep improve

### Manual demo (richer console output)

```bash
cd ml_model
source .venv/bin/activate
python main.py
```

This simulates ~35 days of history for `test_user_1`, prints risk breakdowns, and runs what-if scenarios (sleep, dairy, stress).

### Expected qualitative behavior

| Scenario | Expected |
|----------|----------|
| High pain/stress, poor sleep, recent flare | Elevated `final_risk` (often ~0.45–0.70 cold-start) |
| Low symptoms, good sleep, long flare gap | Lower `final_risk` (often ~0.10–0.30) |
| What-if: lower stress + more sleep | `delta` ≤ 0 |
| < 5 personal logs | `personalization_weight == 0` (global model only) |
| ≥ 30 personal logs | `personalization_weight == 1` (fully personalized) |

---

## 2. Backend / API tests

### Prerequisites

Follow [Backend Setup](BACKEND_SETUP.md). Supabase is optional for local smoke tests — without credentials the API still serves `/health`, `/predict`, and `/simulate` using in-memory history.

### Health check

```bash
curl -s http://127.0.0.1:8000/health
# {"status":"ok","model":"ready"}
```

### Predict smoke

```bash
curl -s -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "qa_user",
    "features": {
      "pain": 7, "diarrhea": 6, "fatigue": 7, "bloating": 5,
      "nausea": 4, "cramping": 6, "urgency": 5, "appetite_loss": 4,
      "blood_in_stool": 1, "sleep_hours": 4.5, "stress": 8,
      "dairy": 1, "spicy_food": 1, "fiber": 0, "days_since_last_flare": 3
    }
  }' | python3 -m json.tool
```

**Pass:** HTTP 200; `final_risk` between 0 and 1; `risk_factors` / `personalization_status` present.

### Simulate smoke

```bash
curl -s -X POST http://127.0.0.1:8000/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "qa_user",
    "features": {
      "pain": 7, "diarrhea": 6, "fatigue": 7, "bloating": 5,
      "nausea": 4, "cramping": 6, "urgency": 5, "appetite_loss": 4,
      "blood_in_stool": 1, "sleep_hours": 4.5, "stress": 8,
      "dairy": 1, "spicy_food": 1, "fiber": 0, "days_since_last_flare": 3
    },
    "changes": { "stress": 3, "sleep_hours": 8, "spicy_food": 0 }
  }' | python3 -m json.tool
```

**Pass:** `new_risk` ≤ `original_risk` for this improvement scenario; `interpretation` string present.

### Log endpoint (requires Supabase)

Without `SUPABASE_*` env vars, `/log` still updates in-memory profiles but skips persistence. With Supabase configured, verify a row appears in the `logs` table after `POST /log`.

---

## 3. iOS quality checks

### Build verification

1. `open ios/IQ.xcodeproj`
2. Select an iOS 16+ simulator
3. **Product → Build** (`Cmd + B`) — must succeed
4. **Product → Run** (`Cmd + R`) — app launches to onboarding or Home

### Manual QA script (15 minutes)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Complete onboarding | Lands on Home with risk disk |
| 2 | Log high-severity symptoms for today | Home risk band / score moves up |
| 3 | Log a trigger food (e.g. dairy/spicy) | Food history updates; risk narrative may change |
| 4 | Open Calendar / heatmap | Day cells reflect logged activity |
| 5 | Open Analytics | Charts + factor breakdown render |
| 6 | Open Assistant | Chat UI accepts a message and returns a reply |
| 7 | Kill and relaunch | Prior logs still present (UserDefaults) |

### Regression notes

- Tab bar remains visible across tabs
- Severity pickers use the wheel control
- On-device Core ML block in Analytics is separate from the rule-based Home risk (by design — see session notes)

---

## 4. Quality gates before sharing the repo

- [ ] `pytest ml_model/tests -q` passes
- [ ] Backend `/health` returns ready after cold start
- [ ] Sample predict/simulate curls match [Samples & Benchmarks](SAMPLES_AND_BENCHMARKS.md)
- [ ] iOS builds on a clean simulator
- [ ] No secrets committed (`.env` is gitignored; only `.env.example` is tracked)
- [ ] README links to setup, testing, and samples docs

---

## 5. Known limitations (honest QA)

- Dataset is synthetic / research-style — metrics are for engineering demos, not clinical claims
- No XCTest suite yet; iOS coverage is manual + build verification
- Supabase auth/config placeholders in `ios/IQ/Config.swift` must be filled for cloud sync
- Personalization quality depends on logging consistency (≥ 5 days to start blending)

For measured accuracy and latency numbers, see **[Samples & Benchmarks](SAMPLES_AND_BENCHMARKS.md)**.
