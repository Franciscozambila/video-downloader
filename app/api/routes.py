"""
Endpoints FastAPI para a interface web do downloader.
"""
from pathlib import Path
from typing import Optional
import json
import math

from fastapi import APIRouter, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, FileResponse, RedirectResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel, Field
from xvideos_api import Client
from xvideos_api.modules.errors import (
    BotDetection,
    NetworkError,
    NotFound,
    UnknownNetworkError,
)

from app.core.downloader import (
    download_video,
    get_video_info,
    DEFAULT_DOWNLOAD_DIR,
    download_thumbnail,
    search_youtube,
    get_stream_url,
)
from app.security.csrf import get_token, is_valid
from app.security.rate_limit import rate_limiter
from app.security.validators import InputValidator

router = APIRouter()

templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


class XVideosMetadataRequest(BaseModel):
    url: str = Field(min_length=1, max_length=2000)


xvideos_client = Client()


@router.post("/api/xvideos/metadata")
async def xvideos_metadata(payload: XVideosMetadataRequest, request: Request):
    """Extrai metadados de um vídeo XVideos e devolve-os em JSON."""
    client_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.check_rate_limit(f"xvideos-metadata:{client_ip}"):
        raise HTTPException(
            status_code=429,
            detail="Demasiadas requisições. Tente novamente mais tarde.",
        )

    url = payload.url.strip()
    if not InputValidator.validate_xvideos_url(url):
        raise HTTPException(
            status_code=400,
            detail="URL do XVideos inválida ou não permitida",
        )

    try:
        video = await xvideos_client.get_video(url)
        return {
            "url": video.url,
            "id": video.video_id,
            "title": video.title,
            "description": video.description,
            "thumbnail": video.thumbnail_url,
            "preview_video": video.preview_video_url,
            "publish_date": video.publish_date,
            "content_url": video.content_url,
            "tags": video.tags,
            "views": video.views,
            "likes": video.likes,
            "dislikes": video.dislikes,
            "rating_votes": video.rating_votes,
            "comment_count": video.comment_count,
            "author_link": video.author_link,
            "length": video.length,
            "embed_url": video.embed_url,
        }
    except NotFound as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except (NetworkError, UnknownNetworkError) as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except BotDetection as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.get("/", response_class=HTMLResponse)
async def index(request: Request):
    """
    Página inicial com pesquisa e download por URL.
    """
    csrf_token = get_token(request)
    response = templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "title": "Video Downloader",
            "result": None,
            "error": None,
            "search_results": None,
            "search_query": None,
            "csrf_token": csrf_token
        }
    )
    response.set_cookie("streamdown_csrf", csrf_token, httponly=True, samesite="lax")
    return response

@router.get("/search", response_class=HTMLResponse)
async def search(request: Request, q: str = "", page: int = 1):
    """
    Endpoint para pesquisar vídeos no YouTube.
    """
    if not q.strip():
        return RedirectResponse("/", status_code=303)
    client_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.check_rate_limit(f"search:{client_ip}"):
        raise HTTPException(status_code=429, detail="Demasiadas pesquisas. Tente novamente mais tarde.")
    
    try:
        results_per_page = 10
        all_results = search_youtube(q, max_results=100)
        total_results = len(all_results)
        total_pages = max(1, math.ceil(total_results / results_per_page))
        page = max(1, min(page, total_pages))
        start = (page - 1) * results_per_page
        results = all_results[start:start + results_per_page]
        return templates.TemplateResponse(
            request=request,
            name="search.html",
            context={
                "title": f"Resultados para '{q}'",
                "search_results": results,
                "search_query": q,
                "current_page": page,
                "total_pages": total_pages,
                "total_results": total_results,
                "error": None
            }
        )
    except Exception as e:
        return templates.TemplateResponse(
            request=request,
            name="search.html",
            context={
                "title": "Erro na pesquisa",
                "search_results": None,
                "search_query": q,
                "current_page": 1,
                "total_pages": 1,
                "total_results": 0,
                "error": str(e)
            }
        )

@router.get("/sobre", response_class=HTMLResponse)
async def about(request: Request):
    """Página institucional e informações de contacto do projeto."""
    return templates.TemplateResponse(
        request=request,
        name="about.html",
        context={"title": "Sobre o StreamDown"}
    )

@router.get("/player", response_class=HTMLResponse)
async def player(request: Request, url: str = ""):
    """
    Página do player para ouvir áudio.
    """
    if not url:
        return RedirectResponse("/", status_code=303)
    if not InputValidator.validate_url(url):
        raise HTTPException(status_code=400, detail="URL inválida ou não permitida")
    
    try:
        video_info = get_video_info(url)
        stream_info = get_stream_url(url, 'audio')
        
        return templates.TemplateResponse(
            request=request,
            name="player.html",
            context={
                "title": f"Player: {video_info['title']}",
                "video_info": video_info,
                "video_url": url,
                "stream_url": stream_info.get('stream_url'),
                "error": None
            }
        )
    except Exception as e:
        return templates.TemplateResponse(
            request=request,
            name="player.html",
            context={
                "title": "Erro",
                "video_info": None,
                "video_url": url,
                "stream_url": None,
                "error": str(e)
            }
        )

@router.get("/download-page", response_class=HTMLResponse)
async def download_page(request: Request, url: str = ""):
    """
    Página de download a partir de um vídeo selecionado na pesquisa.
    """
    if not url:
        return RedirectResponse("/", status_code=303)
    if not InputValidator.validate_download_url(url):
        raise HTTPException(status_code=400, detail="URL inválida ou não permitida")
    
    try:
        info = get_video_info(url)
        csrf_token = get_token(request)
        response = templates.TemplateResponse(
            request=request,
            name="download_page.html",
            context={
                "title": f"Baixar: {info['title']}",
                "video_info": info,
                "video_url": url,
                "error": None,
                "csrf_token": csrf_token
            }
        )
        response.set_cookie("streamdown_csrf", csrf_token, httponly=True, samesite="lax")
        return response
    except Exception as e:
        return templates.TemplateResponse(
            request=request,
            name="download_page.html",
            context={
                "title": "Erro",
                "video_info": None,
                "video_url": url,
                "error": str(e)
            }
        )

@router.post("/download", response_class=HTMLResponse)
async def handle_download(
    request: Request,
    url: str = Form(...),
    file_type: str = Form("mp4"),
    quality: str = Form("best"),
    csrf_token: str = Form("")
):
    """
    Endpoint para processar o download do vídeo/áudio.
    """
    client_ip = request.client.host if request.client else "unknown"
    if not rate_limiter.check_rate_limit(f"download:{client_ip}"):
        raise HTTPException(status_code=429, detail="Demasiadas requisições. Tente novamente mais tarde.")
    if not is_valid(request, csrf_token):
        raise HTTPException(status_code=403, detail="Token de segurança inválido ou expirado.")
    is_xvideos = InputValidator.validate_xvideos_url(url)
    if not InputValidator.validate_download_url(url):
        return templates.TemplateResponse(request=request, name="download_result.html", context={"title": "Erro", "result": None, "error": "URL inválida ou não permitida"}, status_code=400)
    if is_xvideos and file_type != "mp4":
        return templates.TemplateResponse(request=request, name="download_result.html", context={"title": "Erro", "result": None, "error": "Vídeos do XVideos só podem ser baixados em MP4"}, status_code=400)
    if not InputValidator.validate_file_type(file_type):
        return templates.TemplateResponse(request=request, name="download_result.html", context={"title": "Erro", "result": None, "error": "Tipo de ficheiro inválido"}, status_code=400)
    if not InputValidator.validate_quality(quality):
        return templates.TemplateResponse(request=request, name="download_result.html", context={"title": "Erro", "result": None, "error": "Qualidade inválida"}, status_code=400)
    try:
        info = get_video_info(url)
        thumbnail_filename = None

        if file_type == "mp3":
            # Download de áudio com thumbnail incorporada
            audio_quality = quality if quality != "best" else "192"
            filepath = download_video(
                url,
                audio_only=True,
                audio_quality=audio_quality,
                embed_thumbnail=True
            )
            # Baixar thumbnail separada
            if info.get('thumbnail'):
                thumb_path = download_thumbnail(
                    info['thumbnail'],
                    DEFAULT_DOWNLOAD_DIR,
                    filepath.stem
                )
                if thumb_path:
                    thumbnail_filename = thumb_path.name
        else:
            # Download de vídeo
            format_spec = {
                "best": "bestvideo+bestaudio/best",
                "1080p": "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
                "720p": "bestvideo[height<=720]+bestaudio/best[height<=720]",
                "480p": "bestvideo[height<=480]+bestaudio/best[height<=480]",
                "360p": "bestvideo[height<=360]+bestaudio/best[height<=360]"
            }.get(quality, "bestvideo+bestaudio/best")

            filepath = download_video(
                url,
                audio_only=False,
                format_id=format_spec
            )

        base_dir = DEFAULT_DOWNLOAD_DIR.resolve()
        file_path = filepath.resolve()
        if not file_path.is_relative_to(base_dir) or not file_path.is_file():
            raise HTTPException(status_code=500, detail="Ficheiro de download inválido")

        media_type = "audio/mpeg" if file_path.suffix.lower() == ".mp3" else "video/mp4"
        return FileResponse(
            path=file_path,
            filename=file_path.name,
            media_type=media_type,
        )

    except HTTPException:
        raise
    except Exception as e:
        return templates.TemplateResponse(
            request=request,
            name="download_result.html",
            context={
                "title": "Erro",
                "result": None,
                "error": str(e)
            },
            status_code=400
        )

@router.get("/files/{filename}")
async def get_file(filename: str):
    """
    Serve o ficheiro baixado para download.
    """
    base_dir = DEFAULT_DOWNLOAD_DIR.resolve()
    file_path = (base_dir / filename).resolve()
    if not file_path.is_relative_to(base_dir) or not file_path.is_file():
        raise HTTPException(status_code=404, detail="Ficheiro não encontrado")
    return FileResponse(path=file_path, filename=filename)

@router.get("/formats/{url:path}")
async def list_formats(url: str):
    """
    Endpoint para listar formatos disponíveis.
    """
    if not InputValidator.validate_url(url):
        raise HTTPException(status_code=400, detail="URL inválida ou não permitida")
    try:
        formats = get_video_info(url).get("formats", [])
        return {"formats": formats}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
