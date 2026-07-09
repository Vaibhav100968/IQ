# Backend Setup

Run the IQ ML API locally. The FastAPI server loads the Gradient Boosting flare model once at startup and optionally syncs user history with Supabase.

---

## Requirements

| Dependency | Version / notes |
|------------|-----------------|
| Python | 3.9+ (3.10+ recommended) |
| pip / venv | Standard library tooling |
| Network | Only needed for `pip install` and optional Supabase |
| Supabase | Optional — predict/simulate work without it |

---

## 1. Create a virtual environment

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
```

Confirm you are inside the venv:

```bash
which python
python --version
```

---

## 2. Install dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

Pinned / minimum packages (`requirements.txt`):

| Package | Purpose |
|---------|---------|
| `fastapi==0.111.0` | HTTP API |
| `uvicorn[standard]==0.29.0` | ASGI server |
| `supabase==2.4.2` | Optional cloud log sync |
| `python-dotenv==1.0.1` | Load `.env` |
| `pandas>=1.5.0` | Feature frames for the model |
| `scikit-learn>=1.2.0` | GradientBoosting + calibration |
| `numpy>=1.23.0` | Numeric ops |

The server imports `../ml_model/main.py` at startup, which **trains the global model** on `ml_model/crohns_dataset_v2.csv` (~1–2 seconds on a laptop).

---

## 3. Environment configuration

### Copy the example file

```bash
cp .env.example .env
```

### Variables

| Variable | Required? | Description |
|----------|-----------|-------------|
| `SUPABASE_URL` | No* | Project URL, e.g. `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | No* | **Service role** key (server-side only — never ship in the iOS app) |

\* If either is missing, the API still starts. You will see:

```text
SUPABASE_URL / SUPABASE_SERVICE_KEY not set — Supabase writes disabled
```

In that mode:

- `/health`, `/predict`, `/simulate` work with in-memory `user_profiles`
- `/log` updates memory only (no cloud insert)

### Where to get Supabase values

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project  
2. **Settings → API**  
3. Copy **Project URL** → `SUPABASE_URL`  
4. Copy **service_role** key → `SUPABASE_SERVICE_KEY`  
   - Do **not** use the anon key here  
   - Do **not** commit `.env` (gitignored)

### Example `.env`

```bash
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Optional: Supabase `logs` table

If you want persistence, create a table that matches the API field map:

```sql
create table if not exists public.logs (
  id bigint generated always as identity primary key,
  user_id text not null,
  created_at timestamptz not null default now(),
  flare int not null default 0,
  pain float8,
  diarrhea float8,
  fatigue float8,
  bloating float8,
  nausea float8,
  cramping float8,
  urgency float8,
  appetite_loss float8,
  blood_in_stool float8,
  sleep_hours float8,
  stress float8,
  dairy float8,
  spicy_food float8,
  fiber float8,
  days_since_last_flare float8
);

create index if not exists logs_user_id_created_at_idx
  on public.logs (user_id, created_at);
```

Enable Row Level Security as appropriate for your project; the backend uses the service role and bypasses RLS.

---

## 4. Start the server

From the `backend/` directory with the venv active:

```bash
# Development (auto-reload)
uvicorn server:app --reload --host 0.0.0.0 --port 8000

# Or run the module directly (no reload)
python server.py
```

On first boot you should see:

```text
Training global model...
Global model ready.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Interactive docs: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

---

## 5. Verify

```bash
curl -s http://127.0.0.1:8000/health
# {"status":"ok","model":"ready"}
```

Full curl examples and expected JSON: [Samples & Benchmarks](SAMPLES_AND_BENCHMARKS.md)  
QA checklist: [Testing](TESTING.md)

---

## 6. API surface

| Method | Path | Body | Notes |
|--------|------|------|-------|
| `GET` | `/health` | — | Liveness + model ready |
| `POST` | `/predict` | `{ user_id, features }` | Risk + explanation |
| `POST` | `/simulate` | `{ user_id, features, changes }` | What-if delta |
| `POST` | `/log` | `{ user_id, log, flare? }` | Persist + update personalization |

`features` / `log` keys (floats / 0–1 flags):

```text
pain, diarrhea, fatigue, bloating, nausea, cramping, urgency,
appetite_loss, blood_in_stool, sleep_hours, stress, dairy,
spicy_food, fiber, days_since_last_flare
```

---

## 7. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ModuleNotFoundError: main` / CSV not found | Start uvicorn from `backend/`; `server.py` `chdir`s into `ml_model/` |
| Slow first request / long startup | Normal — model trains at import (~1s) |
| Supabase insert errors | Check service role key, table name `logs`, and column names |
| CORS issues from a web client | Server allows `*` origins in this portfolio setup |
| Port 8000 in use | `uvicorn server:app --port 8001` |

---

## 8. Security notes

- Keep `SUPABASE_SERVICE_KEY` server-only
- iOS uses anon key placeholders in `ios/IQ/Config.swift` — separate from this backend
- Never commit real `.env` files or keys into git
