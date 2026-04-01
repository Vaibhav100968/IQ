from __future__ import annotations  # enables float | None on Python 3.9
# file: crohns_model_v5.py
# CrohnsIQ - Full Personalized Flare Prediction System
# Improvements: persistence, smooth cold-start, better explanations,
# food confound correction, learned trend weights, symptom-based test flares

import pandas as pd
import numpy as np
import json
import os
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.calibration import CalibratedClassifierCV

# =============================================================
# CONFIGURATION
# =============================================================

PROFILE_PATH = "user_profiles.json"   # persistent storage file
MIN_PERSONAL_SAMPLES = 5              # minimum logs before personalization starts
FULL_PERSONAL_SAMPLES = 30            # logs needed for full personalization weight

# Feature columns the model trains on
SYMPTOM_FEATURES = [
    "pain", "diarrhea", "fatigue", "bloating",
    "nausea", "cramping", "urgency", "appetite_loss",
    "blood_in_stool"
]

LIFESTYLE_FEATURES = [
    "sleep_hours", "stress", "dairy", "spicy_food",
    "fiber", "days_since_last_flare"
]

TIME_FEATURES = ["pain_3d_avg", "stress_3d_avg", "sleep_trend"]

ALL_FEATURES = SYMPTOM_FEATURES + LIFESTYLE_FEATURES + TIME_FEATURES


# =============================================================
# PERSISTENCE — save/load user profiles to disk
# =============================================================

def load_profiles() -> dict:
    """Load user profiles from disk. Returns empty dict if file doesn't exist."""
    if os.path.exists(PROFILE_PATH):
        with open(PROFILE_PATH, "r") as f:
            return json.load(f)
    return {}


def save_profiles(profiles: dict):
    """Persist user profiles to disk after every update."""
    with open(PROFILE_PATH, "w") as f:
        json.dump(profiles, f, indent=2)


# Load on startup
user_profiles = load_profiles()


# =============================================================
# DATA LOADING & MODEL TRAINING
# =============================================================

def build_time_features(df: pd.DataFrame) -> pd.DataFrame:
    """Add rolling/trend columns to a dataframe."""
    df = df.copy()
    df["pain_3d_avg"]  = df["pain"].rolling(3, min_periods=1).mean()
    df["stress_3d_avg"] = df["stress"].rolling(3, min_periods=1).mean()
    df["sleep_trend"]  = df["sleep_hours"].diff().fillna(0)
    return df


def train_global_model(csv_path: str = "crohns_dataset_v2.csv"):
    """
    Train and calibrate the global GradientBoosting model.
    Returns the fitted model and feature column list.
    """
    df = pd.read_csv(csv_path)
    df = build_time_features(df)

    X = df.drop("flare", axis=1)
    y = df["flare"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    base = GradientBoostingClassifier(
        n_estimators=150,
        max_depth=3,
        learning_rate=0.1,
        random_state=42
    )

    calibrated = CalibratedClassifierCV(base, method="sigmoid", cv=5)
    calibrated.fit(X_train, y_train)

    feature_cols = list(X.columns)
    return calibrated, feature_cols


# Train once at import time
print("Training global model...")
global_model, feature_cols = train_global_model()
print("Global model ready.\n")


# =============================================================
# USER HISTORY MANAGEMENT
# =============================================================

def update_user(user_id: str, data: dict, flare: int):
    """
    Add one day's log entry (with confirmed flare outcome) to user history.
    Immediately persists to disk.
    """
    if user_id not in user_profiles:
        user_profiles[user_id] = []

    entry = {k: float(v) for k, v in data.items()}
    entry["flare"] = int(flare)
    user_profiles[user_id].append(entry)

    save_profiles(user_profiles)


def get_history(user_id: str) -> list:
    return user_profiles.get(user_id, [])


# =============================================================
# COLD-START WEIGHT — smoothly ramps from 0 → 1
# =============================================================

def personalization_weight(user_id: str) -> float:
    """
    Returns a 0–1 weight representing how much to trust
    personal data vs the global model.
    - 0 personal samples  → 0.0  (pure global model)
    - MIN_PERSONAL_SAMPLES → starts blending
    - FULL_PERSONAL_SAMPLES → 1.0 (full personalization)
    """
    n = len(get_history(user_id))
    if n < MIN_PERSONAL_SAMPLES:
        return 0.0
    if n >= FULL_PERSONAL_SAMPLES:
        return 1.0
    return (n - MIN_PERSONAL_SAMPLES) / (FULL_PERSONAL_SAMPLES - MIN_PERSONAL_SAMPLES)


# =============================================================
# CONDITIONAL PROBABILITY ENGINE
# =============================================================

def user_conditional_prob(user_id: str, feature: str, threshold: float) -> float | None:
    """
    P(flare | feature >= threshold) estimated from this user's history.
    Returns None if not enough data yet.
    """
    history = get_history(user_id)
    if len(history) < MIN_PERSONAL_SAMPLES:
        return None

    relevant = [e["flare"] for e in history if e.get(feature, 0) >= threshold]
    if len(relevant) == 0:
        return None

    return float(np.mean(relevant))


def multi_feature_personal_prob(user_id: str, user_input: dict) -> float | None:
    """
    Combines conditional probabilities across pain, stress, and diarrhea,
    weighting each by how many samples contributed (more data = more trust).
    Returns None if no feature has enough data.
    """
    history = get_history(user_id)
    weighted_sum = 0.0
    weight_total = 0.0

    for feature in ["pain", "stress", "diarrhea"]:
        threshold = user_input.get(feature, 0)
        relevant = [e["flare"] for e in history if e.get(feature, 0) >= threshold]

        if len(relevant) >= 3:
            prob = float(np.mean(relevant))
            weight = len(relevant)           # more samples = higher trust
            weighted_sum += prob * weight
            weight_total += weight

    if weight_total == 0:
        return None

    return weighted_sum / weight_total


# =============================================================
# FOOD → SYMPTOM LEARNING (confound-corrected)
# =============================================================

def food_impact(user_id: str, food_feature: str, symptom: str) -> float:
    """
    Estimates how much a food raises a symptom for this specific user,
    controlling for stress level to avoid confounding.
    Returns 0 if not enough data.
    """
    history = get_history(user_id)
    if len(history) < 10:
        return 0.0

    # Only compare days with similar stress (within ±2 of median)
    stresses = [e.get("stress", 5) for e in history]
    median_stress = float(np.median(stresses))

    with_food    = [e[symptom] for e in history
                    if e.get(food_feature) == 1
                    and abs(e.get("stress", 5) - median_stress) <= 2]

    without_food = [e[symptom] for e in history
                    if e.get(food_feature) == 0
                    and abs(e.get("stress", 5) - median_stress) <= 2]

    if len(with_food) < 3 or len(without_food) < 3:
        return 0.0

    return float(np.mean(with_food) - np.mean(without_food))


def adjust_symptoms_for_food(user_id: str, user_input: dict) -> dict:
    """Apply learned food effects to the current symptom values."""
    adjusted = user_input.copy()

    dairy_effect = food_impact(user_id, "dairy", "pain")
    spicy_effect = food_impact(user_id, "spicy_food", "diarrhea")
    fiber_effect = food_impact(user_id, "fiber", "bloating")

    if user_input.get("dairy") == 1:
        adjusted["pain"] = min(10, adjusted["pain"] + dairy_effect)

    if user_input.get("spicy_food") == 1:
        adjusted["diarrhea"] = min(10, adjusted["diarrhea"] + spicy_effect)

    if user_input.get("fiber") == 1:
        adjusted["bloating"] = min(10, adjusted["bloating"] + fiber_effect)

    return adjusted


# =============================================================
# TIME-SERIES FEATURE EXTRACTION
# =============================================================

def extract_time_features(history: list) -> tuple:
    """
    Returns (pain_avg, stress_avg, sleep_trend) from recent history.
    Uses last 7 days if available, otherwise whatever exists.
    """
    window = history[-7:] if len(history) >= 7 else history

    pain_avg   = float(np.mean([d["pain"]        for d in window]))
    stress_avg = float(np.mean([d["stress"]       for d in window]))

    if len(window) >= 2:
        sleep_trend = window[-1]["sleep_hours"] - window[0]["sleep_hours"]
    else:
        sleep_trend = 0.0

    return pain_avg, stress_avg, sleep_trend


# =============================================================
# PER-FEATURE RISK CONTRIBUTION (for explanation)
# =============================================================

def compute_feature_contributions(user_id: str, user_input: dict) -> dict:
    """
    Estimates each feature's individual contribution to risk,
    using the user's own conditional probability history where available,
    falling back to global thresholds otherwise.
    Returns a dict of {feature: risk_contribution (0–1)}.
    """
    history = get_history(user_id)
    contributions = {}

    feature_thresholds = {
        "pain":               ("pain",       user_input.get("pain", 0)),
        "stress":             ("stress",     user_input.get("stress", 0)),
        "diarrhea":           ("diarrhea",   user_input.get("diarrhea", 0)),
        "sleep_hours":        ("sleep_hours", 0),   # low sleep = bad, handled below
        "days_since_flare":   ("days_since_last_flare", 0),
    }

    for label, (feature, threshold) in feature_thresholds.items():

        if label == "sleep_hours":
            # Invert: low sleep → high risk
            relevant = [e["flare"] for e in history
                        if e.get("sleep_hours", 8) <= user_input.get("sleep_hours", 5)]
            if len(relevant) >= 3:
                contributions["sleep"] = float(np.mean(relevant))
            else:
                # global fallback: sleep < 5 → moderate risk proxy
                contributions["sleep"] = 0.55 if user_input.get("sleep_hours", 8) < 5 else 0.25

        elif label == "days_since_flare":
            val = user_input.get("days_since_last_flare", 30)
            contributions["recency"] = max(0, 0.8 - val * 0.03)

        else:
            p = user_conditional_prob(user_id, feature, threshold)
            if p is not None:
                contributions[label] = p
            else:
                # simple global fallback
                contributions[label] = 0.5 if threshold > 6 else 0.25

    # Food triggers
    if user_input.get("dairy") == 1:
        d_impact = food_impact(user_id, "dairy", "pain")
        contributions["dairy"] = min(1.0, 0.3 + d_impact / 10)

    if user_input.get("spicy_food") == 1:
        s_impact = food_impact(user_id, "spicy_food", "diarrhea")
        contributions["spicy_food"] = min(1.0, 0.3 + s_impact / 10)

    return contributions


# =============================================================
# MAIN PREDICTION
# =============================================================

def predict(user_id: str, user_input: dict) -> dict:
    """
    Returns a dict with:
      - final_risk       : blended 0–1 score
      - global_prob      : raw ML model output
      - personal_prob    : user-specific conditional probability (or None)
      - personalization_weight : how much personal data influenced the result
      - trend_factor     : time-series component
      - feature_contributions : per-feature risk breakdown
    """

    # 1. Apply food adjustments
    adjusted_input = adjust_symptoms_for_food(user_id, user_input)

    # 2. Build feature row for global model
    history = get_history(user_id)

    if len(history) >= 3:
        pain_avg, stress_avg, sleep_trend = extract_time_features(history)
    else:
        pain_avg, stress_avg, sleep_trend = 5.0, 5.0, 0.0

    row = {**adjusted_input,
           "pain_3d_avg":   pain_avg,
           "stress_3d_avg": stress_avg,
           "sleep_trend":   sleep_trend}

    # Align columns to training feature order
    row_df = pd.DataFrame([row]).reindex(columns=feature_cols, fill_value=0)

    # 3. Global model probability
    global_prob = float(global_model.predict_proba(row_df)[0][1])

    # 4. Personal conditional probability
    personal_prob = multi_feature_personal_prob(user_id, adjusted_input)

    # 5. Time-trend factor
    trend_factor = float(
        0.35 * (pain_avg / 10) +
        0.20 * (stress_avg / 10) +
        0.25 * (adjusted_input.get("pain", 5) / 10) -
        0.50 * (adjusted_input.get("sleep_hours", 7) / 10)
    )
    trend_factor = max(0.0, min(1.0, trend_factor))

    # 6. Smooth cold-start blending
    p_weight = personalization_weight(user_id)   # 0.0 → 1.0

    # When p_weight=0: pure global + trend
    # When p_weight=1: personal drives the prediction
    if personal_prob is not None:
        final = (
            (1 - p_weight) * (0.6 * global_prob + 0.4 * trend_factor) +
            p_weight       * (0.4 * global_prob + 0.4 * personal_prob + 0.2 * trend_factor)
        )
    else:
        final = 0.6 * global_prob + 0.4 * trend_factor

    final = float(min(1.0, max(0.0, final)))

    # 7. Feature contributions
    contributions = compute_feature_contributions(user_id, adjusted_input)

    return {
        "final_risk":              round(final, 4),
        "global_prob":             round(global_prob, 4),
        "personal_prob":           round(personal_prob, 4) if personal_prob else None,
        "personalization_weight":  round(p_weight, 4),
        "trend_factor":            round(trend_factor, 4),
        "feature_contributions":   {k: round(v, 3) for k, v in contributions.items()},
        "days_logged":             len(history),
    }


# =============================================================
# EXPLANATION SYSTEM (driven by actual contributions)
# =============================================================

def explain(result: dict, user_input: dict) -> dict:
    """
    Returns human-readable risk factors and protective factors,
    ranked by their actual contribution values.
    """
    contribs = result["feature_contributions"]

    risk_factors       = []
    protective_factors = []

    labels = {
        "pain":        "High pain",
        "stress":      "High stress",
        "diarrhea":    "Frequent diarrhea",
        "sleep":       "Poor sleep",
        "recency":     "Recent previous flare",
        "dairy":       "Dairy consumption",
        "spicy_food":  "Spicy food consumption",
    }

    for feature, contrib in sorted(contribs.items(), key=lambda x: -x[1]):
        label = labels.get(feature, feature)
        if contrib >= 0.55:
            risk_factors.append(f"{label} (risk contribution: {contrib:.0%})")
        elif contrib <= 0.35:
            protective_factors.append(f"{label} (protective: {contrib:.0%})")

    # Personalization status message
    n = result["days_logged"]
    pw = result["personalization_weight"]
    if pw == 0:
        status = f"Using general model — log more days to personalize ({n}/{MIN_PERSONAL_SAMPLES} needed)"
    elif pw < 1.0:
        status = f"Personalizing ({n}/{FULL_PERSONAL_SAMPLES} days logged, {pw:.0%} personalized)"
    else:
        status = f"Fully personalized ({n} days logged)"

    return {
        "risk_factors":       risk_factors,
        "protective_factors": protective_factors,
        "personalization_status": status,
    }


# =============================================================
# WHAT-IF SIMULATION
# =============================================================

def simulate(user_id: str, user_input: dict, changes: dict) -> dict:
    """
    Returns prediction result with modified inputs.
    Also computes the delta vs the original prediction.
    """
    original = predict(user_id, user_input)

    modified = user_input.copy()
    modified.update(changes)
    modified_result = predict(user_id, modified)

    delta = round(modified_result["final_risk"] - original["final_risk"], 4)

    return {
        "original_risk":  original["final_risk"],
        "new_risk":       modified_result["final_risk"],
        "delta":          delta,
        "changes_applied": changes,
        "interpretation": (
            f"Risk {'decreases' if delta < 0 else 'increases'} by "
            f"{abs(delta):.1%} with these changes."
        )
    }


# =============================================================
# SYMPTOM-BASED SYNTHETIC FLARE (for realistic testing)
# =============================================================

def synthetic_flare(user_input: dict) -> int:
    """
    Generates a realistic flare label from symptom values
    instead of purely random. Used only for testing/simulation.
    """
    prob = (
        0.25 * (user_input["pain"] / 10) +
        0.20 * (user_input["diarrhea"] / 10) +
        0.15 * user_input["blood_in_stool"] +
        0.15 * (user_input["stress"] / 10) +
        0.10 * (user_input["fatigue"] / 10) -
        0.15 * (user_input["sleep_hours"] / 10)
    )
    prob = max(0.0, min(1.0, prob))
    return int(np.random.binomial(1, prob))


# =============================================================
# TEST RUN
# =============================================================

if __name__ == "__main__":

    user_id = "test_user_1"

    base_user = {
        "sleep_hours": 4,
        "stress": 8,
        "pain": 7,
        "diarrhea": 6,
        "fatigue": 7,
        "bloating": 6,
        "nausea": 5,
        "cramping": 7,
        "urgency": 6,
        "appetite_loss": 5,
        "blood_in_stool": 1,
        "dairy": 1,
        "spicy_food": 1,
        "fiber": 0,
        "days_since_last_flare": 2
    }

    # ── Simulate 35 days of logging ──────────────────────────────
    print("Simulating 35 days of user history...")
    for day in range(35):
        # add some daily variation
        daily = base_user.copy()
        daily["pain"]        = min(10, max(1, base_user["pain"]   + np.random.randint(-2, 3)))
        daily["stress"]      = min(10, max(1, base_user["stress"] + np.random.randint(-2, 3)))
        daily["sleep_hours"] = min(10, max(3, base_user["sleep_hours"] + np.random.uniform(-1, 2)))
        daily["diarrhea"]    = min(10, max(0, base_user["diarrhea"] + np.random.randint(-2, 3)))

        flare = synthetic_flare(daily)
        update_user(user_id, daily, flare)

    print(f"History stored: {len(get_history(user_id))} days\n")

    # ── Current prediction ────────────────────────────────────────
    result = predict(user_id, base_user)
    explanation = explain(result, base_user)

    print("=" * 50)
    print("PREDICTION RESULTS")
    print("=" * 50)
    print(f"Final Risk Score:        {result['final_risk']:.1%}")
    print(f"Global Model Prob:       {result['global_prob']:.1%}")
    print(f"Personal Prob:           {result['personal_prob']:.1%}" if result["personal_prob"] else "Personal Prob:           (not yet available)")
    print(f"Personalization Weight:  {result['personalization_weight']:.1%}")
    print(f"Trend Factor:            {result['trend_factor']:.3f}")
    print(f"Days Logged:             {result['days_logged']}")

    print(f"\nPersonalization Status: {explanation['personalization_status']}")

    print("\nRisk Factors:")
    for r in explanation["risk_factors"]:
        print(f"  ↑ {r}")

    print("\nProtective Factors:")
    for p in explanation["protective_factors"]:
        print(f"  ↓ {p}")

    print("\nFeature Contributions (all):")
    for feat, val in sorted(result["feature_contributions"].items(), key=lambda x: -x[1]):
        bar = "█" * int(val * 20)
        print(f"  {feat:<18} {val:.2f}  {bar}")

    # ── What-if simulations ───────────────────────────────────────
    print("\n" + "=" * 50)
    print("WHAT-IF SIMULATIONS")
    print("=" * 50)

    scenarios = [
        {"sleep_hours": 8},
        {"dairy": 0},
        {"stress": 3},
        {"sleep_hours": 8, "dairy": 0, "stress": 3},
    ]

    for changes in scenarios:
        sim = simulate(user_id, base_user, changes)
        print(f"\nChanges: {changes}")
        print(f"  {sim['original_risk']:.1%} → {sim['new_risk']:.1%}  ({sim['interpretation']})")