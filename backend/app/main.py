from fastapi import FastAPI

from app.errors import register_error_handlers
from app.routes import health, outfits, saved_looks, try_ons, user
from app.routes.admin import clothes as admin_clothes
from app.routes.admin import outfits as admin_outfits

app = FastAPI(title="AI Styler API", version="0.4.0")
register_error_handlers(app)

app.include_router(health.router)
app.include_router(user.router)
app.include_router(saved_looks.router)
app.include_router(outfits.router)
app.include_router(try_ons.router)
app.include_router(admin_clothes.router)
app.include_router(admin_outfits.router)
