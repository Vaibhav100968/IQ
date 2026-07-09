# Samples & Benchmarks

Concrete outputs from the flare model and API so reviewers can see what “working” looks like.

> **Disclaimer:** Numbers below are from the synthetic `crohns_dataset_v2.csv` and local laptop runs. This is an engineering demo, not a clinical evaluation.

---

## Dataset snapshot

| Metric | Value |
|--------|-------|
| Rows | 1,500 |
| Features | 15 base + 3 engineered time features (`pain_3d_avg`, `stress_3d_avg`, `sleep_trend`) |
| Label | `flare` (0/1) |
| Overall flare rate | ~46.5% |
| Train / test split | 1,200 / 300 (`test_size=0.2`, `random_state=42`) |

---

## Model quality (held-out test set)

Retrain with the same recipe as `ml_model/main.py` (`GradientBoostingClassifier` + `CalibratedClassifierCV`):

| Metric | Score |
|--------|-------|
| Accuracy | **0.640** |
| ROC-AUC | **0.713** |
| Precision | **0.673** |
| Recall | **0.517** |
| F1 | **0.585** |
| Train time (laptop) | ~0.9 s |

Confusion matrix (test, threshold 0.5):

```text
                Pred 0    Pred 1
Actual 0         116        37
Actual 1          71        76
```

Interpretation for portfolio readers: the calibrated booster separates flare vs non-flare better than chance (AUC ~0.71) on this synthetic set. Recall is moderate — the product UX pairs the score with explanations rather than treating it as a hard alarm.

---

## Inference latency

Cold-start `predict()` after the model is loaded (50 runs, local Mac):

| Percentile | Latency |
|------------|---------|
| p50 | **~1.8 ms** |
| p95 | **~2.1 ms** |
| mean | **~1.8 ms** |

Startup cost (train-at-import): typically **1–2 seconds** before Uvicorn accepts traffic.

---

## Sample prediction — elevated risk (cold start)

**Input**

```json
{
  "user_id": "demo_high",
  "features": {
    "pain": 7,
    "diarrhea": 6,
    "fatigue": 7,
    "bloating": 5,
    "nausea": 4,
    "cramping": 6,
    "urgency": 5,
    "appetite_loss": 4,
    "blood_in_stool": 1,
    "sleep_hours": 4.5,
    "stress": 8,
    "dairy": 1,
    "spicy_food": 1,
    "fiber": 0,
    "days_since_last_flare": 3
  }
}
```

**Output** (representative local run)

```json
{
  "final_risk": 0.5097,
  "global_prob": 0.6995,
  "personal_prob": null,
  "personalization_weight": 0.0,
  "trend_factor": 0.225,
  "days_logged": 0,
  "feature_contributions": {
    "pain": 0.5,
    "stress": 0.5,
    "diarrhea": 0.25,
    "sleep": 0.55,
    "recency": 0.71,
    "dairy": 0.3,
    "spicy_food": 0.3
  },
  "risk_factors": [
    "Recent previous flare (risk contribution: 71%)",
    "Poor sleep (risk contribution: 55%)"
  ],
  "protective_factors": [
    "Dairy consumption (protective: 30%)",
    "Spicy food consumption (protective: 30%)",
    "Frequent diarrhea (protective: 25%)"
  ],
  "personalization_status": "Using general model — log more days to personalize (0/5 needed)"
}
```

---

## Sample prediction — lower risk (cold start)

**Input** (mild symptoms, good sleep, long flare gap)

```json
{
  "user_id": "demo_low",
  "features": {
    "pain": 1,
    "diarrhea": 0,
    "fatigue": 2,
    "bloating": 1,
    "nausea": 0,
    "cramping": 1,
    "urgency": 0,
    "appetite_loss": 0,
    "blood_in_stool": 0,
    "sleep_hours": 8,
    "stress": 2,
    "dairy": 0,
    "spicy_food": 0,
    "fiber": 1,
    "days_since_last_flare": 45
  }
}
```

**Output** (representative)

```json
{
  "final_risk": 0.1756,
  "global_prob": 0.2927,
  "personal_prob": null,
  "personalization_weight": 0.0,
  "trend_factor": 0.0,
  "days_logged": 0,
  "personalization_status": "Using general model — log more days to personalize (0/5 needed)"
}
```

**Sanity check:** elevated scenario (`0.51`) ≫ calm scenario (`0.18`).

---

## Sample what-if simulation

Same elevated features, with lifestyle improvements:

```json
{
  "changes": {
    "stress": 3,
    "sleep_hours": 8,
    "spicy_food": 0
  }
}
```

**Output**

```json
{
  "original_risk": 0.5097,
  "new_risk": 0.4275,
  "delta": -0.0822,
  "changes_applied": {
    "stress": 3,
    "sleep_hours": 8,
    "spicy_food": 0
  },
  "interpretation": "Risk decreases by 8.2% with these changes."
}
```

---

## Reproduce locally

```bash
# Model console demo
cd ml_model && source .venv/bin/activate
python main.py

# Automated checks
pytest tests/ -q

# API (from backend/)
uvicorn server:app --reload --port 8000
curl -s http://127.0.0.1:8000/health
```

Exact curl bodies: [Testing guide](TESTING.md).  
Env + Supabase: [Backend setup](BACKEND_SETUP.md).

---

## iOS / product-level proof

The native app pairs:

1. **Rule-based Home risk** — updates immediately from today’s logs  
2. **On-device Core ML** (`ml_model/FlarePredictor.mlmodel`) — factor-style context in Analytics  

Qualitative shipping checks (simulator/device): high-severity same-day logs move the Home band; Analytics shows plausible factor emphasis. See also `docs/CODING_AGENT_SESSION.md` for session validation notes.
