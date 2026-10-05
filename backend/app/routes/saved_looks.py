import uuid

from fastapi import APIRouter, Response
from sqlalchemy import select

from app.deps.auth import CurrentUser, DbSession
from app.models import SavedLook
from app.schemas.saved_look import SavedLookCreateRequest, SavedLookResponse
from app.services import saved_looks

router = APIRouter(prefix="/user/saved-looks", tags=["saved-looks"])


@router.get("", response_model=list[SavedLookResponse])
async def list_saved_looks(user: CurrentUser, db: DbSession) -> list[SavedLookResponse]:
    result = await db.scalars(
        select(SavedLook)
        .where(SavedLook.user_id == user.id)
        .order_by(SavedLook.created_at.desc())
    )
    return [SavedLookResponse.from_model(look) for look in result]


@router.post(
    "",
    response_model=SavedLookResponse,
    status_code=201,
    responses={200: {"description": "This try-on was already saved."}},
)
async def create_saved_look(
    body: SavedLookCreateRequest, response: Response, user: CurrentUser, db: DbSession
) -> SavedLookResponse:
    saved_look, created = await saved_looks.save_look(db, user, body.try_on_id)
    if not created:
        response.status_code = 200
    return SavedLookResponse.from_model(saved_look)


@router.get("/{saved_look_id}", response_model=SavedLookResponse)
async def get_saved_look(
    saved_look_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> SavedLookResponse:
    return SavedLookResponse.from_model(
        await saved_looks.get_saved_look(db, user, saved_look_id)
    )


@router.delete("/{saved_look_id}", status_code=204)
async def delete_saved_look(saved_look_id: uuid.UUID, user: CurrentUser, db: DbSession) -> None:
    await saved_looks.delete_saved_look(db, user, saved_look_id)
