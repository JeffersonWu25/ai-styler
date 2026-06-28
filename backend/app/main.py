from fastapi import FastAPI

from app.routes import health, try_on

app = FastAPI(title="AI Styler API", version="0.1.0")

app.include_router(health.router)
app.include_router(try_on.router)
