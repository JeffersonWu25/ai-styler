from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.db.session import init_db
from app.models import generation as _generation  # noqa: F401
from app.models import user as _user  # noqa: F401
from app.routes import auth, generations, health, try_on


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(title="AI Styler API", version="0.2.0", lifespan=lifespan)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(generations.router)
app.include_router(try_on.router)
