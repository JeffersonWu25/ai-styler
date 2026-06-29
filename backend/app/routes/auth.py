from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps.auth import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import AuthResponse, LoginRequest, SignUpRequest, UserResponse
from app.services.jwt_tokens import create_access_token
from app.services.passwords import hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


def _auth_response(user: User) -> AuthResponse:
    return AuthResponse(
        access_token=create_access_token(user.id),
        user=UserResponse(id=str(user.id), email=user.email, created_at=user.created_at),
    )


@router.post("/signup", response_model=AuthResponse, status_code=201)
async def sign_up(
    body: SignUpRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AuthResponse:
    result = await db.execute(select(User).where(User.email == body.email.lower()))
    if result.scalar_one_or_none() is not None:
        raise HTTPException(status_code=409, detail="An account with this email already exists.")

    user = User(email=body.email.lower(), password_hash=hash_password(body.password))
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return _auth_response(user)


@router.post("/login", response_model=AuthResponse)
async def log_in(
    body: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AuthResponse:
    result = await db.execute(select(User).where(User.email == body.email.lower()))
    user = result.scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    return _auth_response(user)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: Annotated[User, Depends(get_current_user)]) -> UserResponse:
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        created_at=current_user.created_at,
    )
