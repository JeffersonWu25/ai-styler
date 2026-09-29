from fastapi import FastAPI

from app.routes import generations, health, me, try_on, user_photos

app = FastAPI(title="AI Styler API", version="0.3.0")

app.include_router(health.router)
app.include_router(me.router)
app.include_router(user_photos.router)
app.include_router(generations.router)
app.include_router(try_on.router)
