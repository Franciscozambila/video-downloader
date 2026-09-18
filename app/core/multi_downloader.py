"""yt-dlp based downloader for supported non-legacy platforms.

This module is intentionally separate from :mod:`app.core.downloader`; the
existing YouTube routes can therefore retain their established behaviour.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Optional

import yt_dlp

from app.core.platform_detector import (
    Platform,
    allowed_formats,
    detect_platform,
    platform_name,
)
from app.core.downloader import DEFAULT_DOWNLOAD_DIR

logger = logging.getLogger(__name__)

QUALITY_LIMITS = {
    "best": None,
    "1080p": 1080,
    "720p": 720,
    "480p": 480,
    "360p": 360,
}
AUDIO_QUALITIES = {"best", "320", "192", "128"}


def _validated_platform(url: str) -> Platform:
    platform = detect_platform(url)
    if platform is None:
        raise ValueError("URL inválida ou plataforma não suportada")
    return platform


def _format_info(fmt: dict[str, Any]) -> dict[str, Any]:
    return {
        "format_id": fmt.get("format_id"),
        "ext": fmt.get("ext"),
        "resolution": fmt.get("resolution"),
        "height": fmt.get("height"),
        "filesize": fmt.get("filesize") or fmt.get("filesize_approx"),
        "vcodec": fmt.get("vcodec"),
        "acodec": fmt.get("acodec"),
        "format_note": fmt.get("format_note"),
    }


def get_metadata(url: str) -> dict[str, Any]:
    """Extract safe, JSON-serialisable metadata for a supported URL."""
    platform = _validated_platform(url.strip())
    options = {
        "quiet": True,
        "no_warnings": True,
        "skip_download": True,
        "noplaylist": True,
    }
    try:
        with yt_dlp.YoutubeDL(options) as ydl:
            info = ydl.extract_info(url.strip(), download=False)
    except Exception as exc:
        logger.warning("Metadata extraction failed for %s: %s", url, exc)
        raise ValueError("Não foi possível obter os metadados deste URL") from exc

    formats = [_format_info(item) for item in info.get("formats", []) if item.get("format_id")]
    if Platform.SOUNDCLOUD in {platform}:
        formats = [item for item in formats if item.get("acodec") != "none"]
    elif platform in {Platform.INSTAGRAM, Platform.TIKTOK, Platform.XVIDEOS}:
        formats = [item for item in formats if item.get("ext") == "mp4"]

    return {
        "platform": platform.value,
        "platform_name": platform_name(platform),
        "title": info.get("title") or "Sem título",
        "id": info.get("id"),
        "duration": info.get("duration"),
        "thumbnail": info.get("thumbnail"),
        "uploader": info.get("uploader") or info.get("channel"),
        "view_count": info.get("view_count"),
        "formats": formats,
        "allowed_formats": list(allowed_formats(platform)),
    }


def _video_selector(quality: str) -> str:
    height = QUALITY_LIMITS.get(quality)
    suffix = f"[height<={height}]" if height else ""
    # Prefer MP4 while retaining a fallback for extractors that only expose
    # another container.
    return f"bestvideo[ext=mp4]{suffix}+bestaudio[ext=m4a]/best[ext=mp4]{suffix}/best"


def download_media(
    url: str,
    file_type: str = "mp4",
    quality: str = "best",
    output_dir: Optional[Path] = None,
) -> Path:
    """Download one item and return its path.

    yt-dlp and post-processing are blocking operations; API callers must run
    this function in a worker thread.
    """
    platform = _validated_platform(url.strip())
    allowed = allowed_formats(platform)
    if file_type not in allowed:
        allowed_text = ", ".join(allowed)
        raise ValueError(f"{platform_name(platform)} permite apenas: {allowed_text}")
    if file_type == "mp4" and quality not in QUALITY_LIMITS:
        raise ValueError("Qualidade de vídeo inválida")
    if file_type == "mp3" and quality not in AUDIO_QUALITIES:
        raise ValueError("Qualidade de áudio inválida")

    target_dir = (output_dir or DEFAULT_DOWNLOAD_DIR).resolve()
    target_dir.mkdir(parents=True, exist_ok=True)
    options: dict[str, Any] = {
        "outtmpl": str(target_dir / "%(title).150s [%(id)s].%(ext)s"),
        "noplaylist": True,
        "quiet": True,
        "no_warnings": True,
    }
    if file_type == "mp3":
        options.update(
            {
                "format": "bestaudio/best",
                "postprocessors": [
                    {
                        "key": "FFmpegExtractAudio",
                        "preferredcodec": "mp3",
                        "preferredquality": "192" if quality == "best" else quality,
                    }
                ],
            }
        )
    else:
        options.update(
            {
                "format": _video_selector(quality),
                "merge_output_format": "mp4",
            }
        )

    try:
        with yt_dlp.YoutubeDL(options) as ydl:
            info = ydl.extract_info(url.strip(), download=True)
            filename = Path(ydl.prepare_filename(info))
    except Exception as exc:
        logger.warning("Download failed for %s: %s", url, exc)
        raise ValueError("Não foi possível baixar este conteúdo") from exc

    result = filename.with_suffix(".mp3" if file_type == "mp3" else ".mp4")
    if not result.is_file():
        # Some extractors already return the final extension in prepare_filename.
        candidate = target_dir / filename.name
        if candidate.is_file():
            result = candidate
        else:
            raise ValueError("O download terminou sem produzir um ficheiro válido")
    return result


class MultiPlatformDownloader:
    """Convenience facade around the stateless multi-platform operations."""

    @staticmethod
    def get_metadata(url: str) -> dict[str, Any]:
        return get_metadata(url)

    @staticmethod
    def metadata(url: str) -> dict[str, Any]:
        return get_metadata(url)

    @staticmethod
    def download(
        url: str,
        file_type: str = "mp4",
        quality: str = "best",
        output_dir: Optional[Path] = None,
    ) -> Path:
        return download_media(url, file_type, quality, output_dir)

    @staticmethod
    def download_video(
        url: str,
        file_type: str = "mp4",
        quality: str = "best",
        output_dir: Optional[Path] = None,
    ) -> Path:
        return download_media(url, file_type, quality, output_dir)


__all__ = [
    "AUDIO_QUALITIES",
    "QUALITY_LIMITS",
    "MultiPlatformDownloader",
    "download_media",
    "get_metadata",
]
