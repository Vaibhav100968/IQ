"""
Convert the trained GradientBoostingClassifier to a Core ML model.
Run: python convert_to_coreml.py
Output: FlarePredictor.mlmodel (copied into ios/IQ/)
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
import coremltools as ct

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

def build_time_features(df):
    df = df.copy()
    df["pain_3d_avg"]   = df["pain"].rolling(3, min_periods=1).mean()
    df["stress_3d_avg"] = df["stress"].rolling(3, min_periods=1).mean()
    df["sleep_trend"]   = df["sleep_hours"].diff().fillna(0)
    return df

print("Loading dataset...")
df = pd.read_csv("crohns_dataset_v2.csv")
df = build_time_features(df)

X = df.drop("flare", axis=1)
y = df["flare"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

print("Training model...")
base = GradientBoostingClassifier(
    n_estimators=150,
    max_depth=3,
    learning_rate=0.1,
    random_state=42
)
base.fit(X_train, y_train)

accuracy = base.score(X_test, y_test)
print(f"Test accuracy: {accuracy:.3f}")

feature_cols = list(X.columns)
print(f"Features ({len(feature_cols)}): {feature_cols}")

print("Converting to Core ML...")

coreml_model = ct.converters.sklearn.convert(
    base,
    input_features=feature_cols,
)

coreml_model.author = "IQ: Gut Intelligence"
coreml_model.short_description = "Predicts Crohn's disease flare risk from symptoms, lifestyle, and trend features."

for feat in SYMPTOM_FEATURES:
    coreml_model.input_description[feat] = f"{feat.replace('_', ' ').title()} (0-10)"
coreml_model.input_description["blood_in_stool"] = "Blood in stool (0 or 1)"
coreml_model.input_description["sleep_hours"] = "Hours of sleep"
coreml_model.input_description["stress"] = "Stress level (0-10)"
coreml_model.input_description["dairy"] = "Consumed dairy (0 or 1)"
coreml_model.input_description["spicy_food"] = "Consumed spicy food (0 or 1)"
coreml_model.input_description["fiber"] = "Consumed high fiber (0 or 1)"
coreml_model.input_description["days_since_last_flare"] = "Days since last flare"
coreml_model.input_description["pain_3d_avg"] = "3-day rolling pain average"
coreml_model.input_description["stress_3d_avg"] = "3-day rolling stress average"
coreml_model.input_description["sleep_trend"] = "Sleep trend (hours change)"

output_path = "FlarePredictor.mlmodel"
coreml_model.save(output_path)
print(f"\nSaved: {output_path}")

import shutil
ios_path = "../ios/IQ/FlarePredictor.mlmodel"
shutil.copy2(output_path, ios_path)
print(f"Copied to: {ios_path}")
print("Done!")
