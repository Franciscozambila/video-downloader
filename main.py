"""
Entrypoint da aplicação FastAPI.
Executa com: uvicorn main:app --reload
"""
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pathlib import Path
import os

from app.api.routes import router
from app.api.multi_routes import router as multi_router
from app.security.headers import SecurityHeadersMiddleware

app = FastAPI(
    title="Video Downloader",
    description="Aplicação web para baixar vídeos e áudio usando yt-dlp.",
    version="1.0.0"
)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=[
        host.strip()
        for host in os.getenv(
            "ALLOWED_HOSTS",
            "*",
        ).split(",")
        if host.strip()
    ],
)

# Montar diretório estático (CSS/JS futuros)
app.mount("/static", StaticFiles(directory=str(Path(__file__).parent / "app" / "static")), name="static")

# Incluir rotas
app.include_router(router)
app.include_router(multi_router)
