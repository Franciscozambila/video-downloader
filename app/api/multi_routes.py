"""Async API routes for automatic multi-platform downloads."""

from __future__ import annotations

import asyncio
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from app.core.multi_downloader import download_media, get_metadata
from app.core.platform_detector import allowed_formats, detect_platform, platform_name
from app.security.rate_limit import rate_limiter

router = APIRouter(prefix="/api/multi", tags=["multi-platform"])


class URLRequest(BaseModel):
    url: str = Field(min_length=1, max_length=2000)


class DownloadRequest(URLRequest):
    file_type: str | None = Field(default=None, pattern=r"^(mp3|mp4)$")
    format: str | None = Field(default=None, pattern=r"^(mp3|mp4)$")
    quality: str = Field(default="best", pattern=r"^(best|1080p|720p|480p|360p|320|192|128)$")

    @property
    def resolved_file_type(self) -> str:
        return self.file_type or self.format or "mp4"


def _check_rate_limit(request: Request, operation: str) -> None:
    client_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.check_rate_limit(f"multi-{operation}:{client_ip}"):
        raise HTTPException(status_code=429, detail="Demasiadas requisições. Tente novamente mais tarde.")


def _metadata_error(exc: Exception) -> HTTPException:
    return HTTPException(status_code=400, detail=str(exc) or "URL inválido ou plataforma não suportada")


@router.get("/detect")
async def detect(url: str = Query(..., min_length=1, max_length=2000)):
    """Detect a supported platform without contacting the remote service."""
    platform = detect_platform(url.strip())
    if platform is None:
        return {"valid": False, "platform": None, "platform_name": None, "formats": []}
    return {
        "valid": True,
        "platform": platform.value,
        "platform_name": platform_name(platform),
        "formats": list(allowed_formats(platform)),
    }


@router.post("/detect")
async def detect_post(payload: URLRequest):
    """JSON equivalent of the GET detection endpoint for browser clients."""
    return await detect(payload.url)


@router.post("/metadata")
async def metadata(payload: URLRequest, request: Request):
    _check_rate_limit(request, "metadata")
    try:
        return await asyncio.to_thread(get_metadata, payload.url)
    except ValueError as exc:
        raise _metadata_error(exc) from exc


@router.get("/metadata")
async def metadata_get(
    request: Request,
    url: str = Query(..., min_length=1, max_length=2000),
):
    """GET variant useful for simple integrations."""
    return await metadata(URLRequest(url=url), request)


@router.post("/download")
async def download(payload: DownloadRequest, request: Request):
    _check_rate_limit(request, "download")
    try:
        filepath = await asyncio.to_thread(
            download_media,
            payload.url,
            payload.resolved_file_type,
            payload.quality,
        )
    except ValueError as exc:
        raise _metadata_error(exc) from exc

    # download_media constrains output_dir to the application's download
    # directory; retain a second check before serving user-controlled names.
    base_dir = Path(__file__).resolve().parent.parent.parent.joinpath("downloads").resolve()
    if not filepath.is_relative_to(base_dir) or not filepath.is_file():
        raise HTTPException(status_code=500, detail="Ficheiro de download inválido")
    media_type = "audio/mpeg" if filepath.suffix.lower() == ".mp3" else "video/mp4"
    return FileResponse(path=filepath, filename=filepath.name, media_type=media_type)


multi_router = router

__all__ = ["multi_router", "router"]
