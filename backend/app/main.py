from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.db.session import init_db
from app.models import generation as _generation  # noqa: F401
from app.models import listing as _listing  # noqa: F401
from app.models import user as _user  # noqa: F401
from app.models import user_photo as _user_photo  # noqa: F401
from app.routes import admin_listings, auth, generations, health, me, try_on, user_photos

ADMIN_DIST = Path(__file__).resolve().parent.parent.parent / "admin" / "dist"


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(title="AI Styler API", version="0.3.0", lifespan=lifespan)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(me.router)
app.include_router(user_photos.router)
app.include_router(generations.router)
app.include_router(try_on.router)
app.include_router(admin_listings.router)

if ADMIN_DIST.is_dir():
    app.mount(
        "/admin/assets",
        StaticFiles(directory=ADMIN_DIST / "assets"),
        name="admin-assets",
    )

    @app.get("/admin")
    @app.get("/admin/{path:path}")
    async def admin_spa(path: str = "") -> FileResponse:
        file_path = ADMIN_DIST / path
        if path and file_path.is_file():
            return FileResponse(file_path)
        return FileResponse(ADMIN_DIST / "index.html")
