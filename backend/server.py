"""
IQ ML API — FastAPI server wrapping CrohnsIQ ML model
Loads model ONCE at startup. Fetches/stores user history via Supabase.
"""

import os
import sys
import logging

# ── Point to ml_model directory so main.py finds crohns_dataset_v2.csv ────────
ML_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ml_model")
os.chdir(ML_DIR)
sys.path.insert(0, ML_DIR)

# ── Import ML module (trains global model at import time) ──────────────────────
import main as ml  # noqa: E402  (must come after chdir)

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("iq_api")

# ── Supabase client ────────────────────────────────────────────────────────────
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    log.warning("SUPABASE_URL / SUPABASE_SERVICE_KEY not set — Supabase writes disabled")
    supabase: Optional[Client] = None
else:
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# ── FastAPI app ────────────────────────────────────────────────────────────────
app = FastAPI(title="IQ ML API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Pydantic schemas ───────────────────────────────────────────────────────────

class PredictRequest(BaseModel):
    user_id: str
    features: dict

class SimulateRequest(BaseModel):
    user_id: str
    features: dict
    changes: dict

class LogRequest(BaseModel):
    user_id: str
    log: dict
    flare: int = 0


# ── Supabase ↔ ML bridge ───────────────────────────────────────────────────────

SUPABASE_TO_ML = {
    "pain": "pain",
    "diarrhea": "diarrhea",
    "fatigue": "fatigue",
    "bloating": "bloating",
    "nausea": "nausea",
    "cramping": "cramping",
    "urgency": "urgency",
    "appetite_loss": "appetite_loss",
    "blood_in_stool": "blood_in_stool",
    "sleep_hours": "sleep_hours",
    "stress": "stress",
    "dairy": "dairy",
    "spicy_food": "spicy_food",
    "fiber": "fiber",
    "days_since_last_flare": "days_since_last_flare",
    "flare": "flare",
}

def load_history_from_supabase(user_id: str) -> list:
    """Fetch user log rows from Supabase and inject into ml.user_profiles."""
    if supabase is None:
        return ml.user_profiles.get(user_id, [])
    try:
        res = (
            supabase.table("logs")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at")
            .execute()
        )
        rows = res.data or []
        history = []
        for row in rows:
            entry = {ml_col: float(row.get(sb_col, 0)) for sb_col, ml_col in SUPABASE_TO_ML.items()}
            entry["flare"] = int(row.get("flare", 0))
            history.append(entry)
        ml.user_profiles[user_id] = history
        return history
    except Exception as e:
        log.error(f"Supabase fetch error for {user_id}: {e}")
        return ml.user_profiles.get(user_id, [])


def write_log_to_supabase(user_id: str, log_data: dict, flare: int):
    """Insert one log row into Supabase logs table."""
    if supabase is None:
        return
    try:
        payload = {"user_id": user_id, "flare": flare}
        payload.update({k: v for k, v in log_data.items() if k in SUPABASE_TO_ML})
        supabase.table("logs").insert(payload).execute()
    except Exception as e:
        log.error(f"Supabase insert error for {user_id}: {e}")


# ── Endpoints ──────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok", "model": "ready"}


@app.post("/predict")
def predict(req: PredictRequest):
    """
    Run personalized flare prediction for a user.
    Fetches their Supabase history first so the model is current.
    Returns prediction + explanation in one response.
    """
    load_history_from_supabase(req.user_id)

    try:
        result = ml.predict(req.user_id, req.features)
        explanation = ml.explain(result, req.features)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    return {**result, **explanation}


@app.post("/simulate")
def simulate(req: SimulateRequest):
    """
    What-if simulation: apply changes to features and return new risk.
    """
    load_history_from_supabase(req.user_id)

    try:
        return ml.simulate(req.user_id, req.features, req.changes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/log")
def log_entry(req: LogRequest):
    """
    Store a new daily log entry in Supabase and update the in-memory model.
    """
    load_history_from_supabase(req.user_id)
    write_log_to_supabase(req.user_id, req.log, req.flare)
    ml.update_user(req.user_id, req.log, req.flare)
    return {"status": "logged", "days_logged": len(ml.get_history(req.user_id))}


# ── Run ────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=False)
