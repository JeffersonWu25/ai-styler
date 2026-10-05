from fastapi import APIRouter

from app.deps.auth import CurrentUser, DbSession
from app.schemas.try_on import TryOnCreateRequest, TryOnResponse
from app.services import try_ons

router = APIRouter(prefix="/try-ons", tags=["try-ons"])


@router.post("", response_model=TryOnResponse, status_code=201)
async def create_try_on(
    body: TryOnCreateRequest, user: CurrentUser, db: DbSession
) -> TryOnResponse:
    try_on, outfit_name = await try_ons.create_try_on(db, user, body.outfit_id)
    return TryOnResponse.from_model(try_on, outfit_name)
