# AI Styler

Virtual try-on iOS app backed by a Python API and OpenAI GPT Image 2.

## Project layout

```
ai-styler/
├── ios/          SwiftUI iPhone app
├── backend/      FastAPI server (try-on, catalog, collections, admin API)
├── admin/        Vite React admin UI for the clothing catalog
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

Use a separate Railway Postgres for production when you deploy the API.

Verify the server is running:

```bash
curl http://localhost:8000/health
# {"status":"ok"}
```

API docs: http://localhost:8000/docs

Apply migrations with `alembic upgrade head` (see `REALREADME.md`).

### API

Images are never streamed through the API: responses include short-lived presigned S3 URLs (`imageUrl`). All JSON is camelCase; errors are `{ "detail": "..." }`.

| Endpoint | Purpose |
|---|---|
| `GET /health` | Liveness check |
| `GET /user` | Profile + `photos.front/side/back` (`null` when missing) |
| `PUT /user/photos/{front\|side\|back}` | Multipart `image`; upload or replace a body photo |
| `DELETE /user/photos/{slot}` | Remove a body photo |
| `GET /outfits`, `GET /outfits/{id}` | Outfit catalog; detail includes clothing items |
| `POST /try-ons` `{ outfitId }` | Generates synchronously from stored photos (409 if any are missing) |
| `GET/POST /user/saved-looks`, `GET/DELETE /user/saved-looks/{id}` | Collections. `POST { tryOnId }` snapshots the outfit and its item images, so later catalog edits never change a saved look |
| `/admin/clothes`, `/admin/outfits` | List / create (multipart) / get / delete. Require `X-Admin-Key` |

Run tests with `python -m pytest` from `backend/`.

### Admin catalog

Add clothing items (category, name, brand, listing URL, image), then compose outfits from them. Stored in Postgres; images in S3.

1. Set `ADMIN_API_KEY` in `backend/.env`.
2. Start the backend (`uvicorn` as above).
3. Run the admin UI:

```bash
cd admin
npm install
npm run dev
```

Open http://localhost:5173/admin/ and paste your admin key in the header.

To serve the admin UI from FastAPI in production:

```bash
cd admin && npm run build
# then start uvicorn — UI is at http://localhost:8000/admin/
```

### Try-on

`POST /try-ons` sends the user's front, side, and back photos plus each clothing item's image in the outfit to OpenAI `gpt-image-2`. The prompt is built from the outfit's items in `backend/app/services/prompts.py`. Set `OPENAI_API_KEY` in `backend/.env` before testing try-on.

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

The app opens on the tabs. API routes use the seeded development user; this build has no sign-in screen.

## Development phases

| Phase | Status |
|-------|--------|
| 1. Scaffold | Done |
| 2. Photo capture UI | Done |
| 3. GPT Image 2 integration | Done |
| 4. Polish | Pending |

See [PLAN.md](PLAN.md) for full details.
