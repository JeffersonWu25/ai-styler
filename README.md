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
# Edit .env and set OPENAI_API_KEY
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verify the server is running:

```bash
curl http://localhost:8000/health
# {"status":"ok"}
```

API docs: http://localhost:8000/docs

## iOS setup

1. Open `ios/AIStyler.xcodeproj` in Xcode
2. Select the **AIStyler** scheme and an iPhone simulator
3. Press **Run** (⌘R)

You should see a placeholder screen: "Phase 1 scaffold ready."

> **Note:** Set your Development Team in Xcode (Signing & Capabilities) before running on a physical device.

## Development phases

| Phase | Status |
|-------|--------|
| 1. Scaffold | Done |
| 2. Photo capture UI | Pending |
| 3. GPT Image 2 integration | Pending |
| 4. Polish | Pending |

See [PLAN.md](PLAN.md) for full details.
