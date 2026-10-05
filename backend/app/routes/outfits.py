import uuid

from fastapi import APIRouter
from sqlalchemy import select

from app.db.session import get_or_404
from app.deps.auth import DbSession
from app.models import Outfit
from app.schemas.outfit import OutfitResponse, OutfitSummaryResponse

router = APIRouter(prefix="/outfits", tags=["outfits"])


@router.get("", response_model=list[OutfitSummaryResponse])
async def list_outfits(db: DbSession) -> list[OutfitSummaryResponse]:
    result = await db.scalars(select(Outfit).order_by(Outfit.created_at.desc()))
    return [OutfitSummaryResponse.from_model(outfit) for outfit in result]


@router.get("/{outfit_id}", response_model=OutfitResponse)
async def get_outfit(outfit_id: uuid.UUID, db: DbSession) -> OutfitResponse:
    return OutfitResponse.from_model(await get_or_404(db, Outfit, outfit_id, "Outfit"))
