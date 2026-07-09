"""Smoke tests for the CrohnsIQ flare prediction pipeline."""

from __future__ import annotations

import main as ml


HIGH = {
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
    "days_since_last_flare": 3,
}

LOW = {
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
    "days_since_last_flare": 45,
}


def test_global_model_is_trained():
    assert ml.global_model is not None
    assert len(ml.feature_cols) >= 15


def test_predict_returns_bounded_risk():
    result = ml.predict("pytest_cold", HIGH)
    assert 0.0 <= result["final_risk"] <= 1.0
    assert 0.0 <= result["global_prob"] <= 1.0
    assert result["personalization_weight"] == 0.0
    assert result["days_logged"] == 0
    assert "feature_contributions" in result


def test_high_risk_exceeds_low_risk():
    high = ml.predict("pytest_high", HIGH)["final_risk"]
    low = ml.predict("pytest_low", LOW)["final_risk"]
    assert high > low


def test_explain_includes_status():
    result = ml.predict("pytest_explain", HIGH)
    explanation = ml.explain(result, HIGH)
    assert "personalization_status" in explanation
    assert isinstance(explanation["risk_factors"], list)
    assert isinstance(explanation["protective_factors"], list)


def test_simulate_improves_with_better_lifestyle():
    sim = ml.simulate(
        "pytest_sim",
        HIGH,
        {"stress": 3, "sleep_hours": 8, "spicy_food": 0},
    )
    assert sim["new_risk"] <= sim["original_risk"]
    assert sim["delta"] <= 0
    assert "interpretation" in sim
