# AI Styler

Virtual try-on iOS app backed by a Python API and OpenAI GPT Image 2.

## Project layout

```
ai-styler/
├── ios/          SwiftUI iPhone app
├── backend/      FastAPI server (OpenAI proxy)
├── CLAUDE.md     High-level product summary
└── PLAN.md       MVP implementation plan
```

## Prerequisites

- **Xcode 15+** (for the iOS app)
- **Python 3.11+** (for the backend)
- **OpenAI API key** with access to `gpt-image-2` (verified organization)

## Backend setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp ../.env.example .env
# Edit .env: OPENAI_API_KEY and DATABASE_URL (Railway Postgres public URL)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Database (Railway Postgres, local backend)

Local development runs **uvicorn on your Mac** but stores data in **Railway Postgres**:

1. In [Railway](https://railway.app), create a project and add **PostgreSQL**.
2. Open the Postgres service → **Connect** → copy the **public** `DATABASE_URL` (not `.railway.internal`).
3. Paste it into `backend/.env`:
   ```
   DATABASE_URL=postgresql://postgres:...@...railway.app:5432/railway
   ```
   The backend converts `postgres://` → `postgresql+asyncpg://` and enables SSL automatically.

Tables are created on first startup. Use a separate Railway Postgres for production when you deploy the API.

Verify the server is running:

```bash
curl http://localhost:8000/health
# {"status":"ok"}
```

API docs: http://localhost:8000/docs

### Try-on endpoint

`POST /try-on` accepts multipart fields `front`, `side`, and `back` (JPEG/PNG). It uses the user's **front** photo plus hardcoded garment references from `backend/assets/outfits/old-money/` and calls OpenAI `gpt-image-2`.

Set `OPENAI_API_KEY` in `backend/.env` before testing try-on. Replace the placeholder garment PNGs with real clothing reference photos for better results.

## iOS setup

1. Open `ios/AIStyler.xcodeproj` in Xcode
2. Select the **AIStyler** scheme and an iPhone simulator
3. Press **Run** (⌘R)

You should see the photo capture screen with three slots (Front, Side, Back).

Start the backend first so the app can show **Connected** at the top:

```bash
cd backend && source .venv/bin/activate && uvicorn app.main:app --reload --port 8000
```

> **Physical device:** change `AppConfig.apiBaseURL` in `ios/AIStyler/Services/AppConfig.swift` to your Mac's LAN IP (e.g. `http://192.168.1.10:8000`).

> **Note:** Set your Development Team in Xcode (Signing & Capabilities) before running on a physical device.

Sign in with any email and password (8+ characters to sign up). No OAuth or Apple Developer Program setup required.

If the `users` table already exists from earlier OAuth work, drop and recreate it on Railway Postgres before testing signup.

## Development phases

| Phase | Status |
|-------|--------|
| 1. Scaffold | Done |
| 2. Photo capture UI | Done |
| 3. GPT Image 2 integration | Done |
| 4. Polish | Pending |

See [PLAN.md](PLAN.md) for full details.
