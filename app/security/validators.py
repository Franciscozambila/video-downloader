import re
from urllib.parse import urlparse


class InputValidator:
    """Valida entradas controladas pelo utilizador antes de as processar."""

    ALLOWED_DOMAINS = {
        "youtube.com",
        "www.youtube.com",
        "youtu.be",
        "m.youtube.com",
        "music.youtube.com",
    }
    ALLOWED_QUALITIES = {"best", "1080p", "720p", "480p", "360p", "320", "192", "128"}

    @classmethod
    def validate_url(cls, url: str) -> bool:
        if not url or len(url) > 2000:
            return False
        try:
            parsed = urlparse(url)
            hostname = (parsed.hostname or "").lower().rstrip(".")
            return (
                parsed.scheme in {"http", "https"}
                and not parsed.username
                and not parsed.password
                and hostname in cls.ALLOWED_DOMAINS
            )
        except ValueError:
            return False

    @classmethod
    def validate_xvideos_url(cls, url: str) -> bool:
        if not url or len(url) > 2000:
            return False
        try:
            parsed = urlparse(url)
            hostname = (parsed.hostname or "").lower().rstrip(".")
            return (
                parsed.scheme in {"http", "https"}
                and not parsed.username
                and not parsed.password
                and hostname in {"xvideos.com", "www.xvideos.com"}
                and parsed.path.startswith("/video")
            )
        except ValueError:
            return False

    @classmethod
    def validate_download_url(cls, url: str) -> bool:
        return cls.validate_url(url) or cls.validate_xvideos_url(url)

    @classmethod
    def validate_quality(cls, quality: str) -> bool:
        return quality in cls.ALLOWED_QUALITIES

    @staticmethod
    def validate_file_type(file_type: str) -> bool:
        return file_type in {"mp3", "mp4"}

    @staticmethod
    def sanitize_filename(filename: str) -> str:
        cleaned = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "", filename)
        return re.sub(r"\s+", " ", cleaned).strip()[:200]
