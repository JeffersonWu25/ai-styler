from fastapi import APIRouter

router = APIRouter(prefix="/try-on", tags=["try-on"])


@router.post("")
def try_on_not_implemented() -> dict[str, str]:
    return {
        "message": "Try-on endpoint coming in Phase 3. Use GET /health to verify the server is running."
    }
