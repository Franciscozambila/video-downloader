"""Platform detection and URL validation for the multi-platform downloader.

The detector deliberately uses a host allowlist instead of accepting arbitrary
URLs.  This keeps yt-dlp from being used as a proxy for unrelated hosts.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Optional
from urllib.parse import urlparse


class Platform(str, Enum):
    YOUTUBE = "youtube"
    FACEBOOK = "facebook"
    INSTAGRAM = "instagram"
    TIKTOK = "tiktok"
    TWITTER = "twitter"
    VIMEO = "vimeo"
    SOUNDCLOUD = "soundcloud"
    DAILYMOTION = "dailymotion"
    TWITCH = "twitch"
    REDDIT = "reddit"
    PINTEREST = "pinterest"
    XVIDEOS = "xvideos"


@dataclass(frozen=True)
class PlatformConfig:
    name: str
    domains: frozenset[str]
    formats: tuple[str, ...]


PLATFORM_CONFIGS: dict[Platform, PlatformConfig] = {
    Platform.YOUTUBE: PlatformConfig(
        "YouTube",
        frozenset({"youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be"}),
        ("mp4", "mp3"),
    ),
    Platform.FACEBOOK: PlatformConfig(
        "Facebook",
        frozenset({"facebook.com", "www.facebook.com", "web.facebook.com", "m.facebook.com", "fb.watch"}),
        ("mp4", "mp3"),
    ),
    Platform.INSTAGRAM: PlatformConfig(
        "Instagram", frozenset({"instagram.com", "www.instagram.com"}), ("mp4",)
    ),
    Platform.TIKTOK: PlatformConfig(
        "TikTok", frozenset({"tiktok.com", "www.tiktok.com", "vm.tiktok.com", "vt.tiktok.com"}), ("mp4",)
    ),
    Platform.TWITTER: PlatformConfig(
        "Twitter/X",
        frozenset({"twitter.com", "www.twitter.com", "mobile.twitter.com", "x.com", "www.x.com"}),
        ("mp4",),
    ),
    Platform.VIMEO: PlatformConfig(
        "Vimeo", frozenset({"vimeo.com", "www.vimeo.com", "player.vimeo.com"}), ("mp4", "mp3")
    ),
    Platform.SOUNDCLOUD: PlatformConfig(
        "SoundCloud", frozenset({"soundcloud.com", "www.soundcloud.com", "on.soundcloud.com"}), ("mp3",)
    ),
    Platform.DAILYMOTION: PlatformConfig(
        "Dailymotion", frozenset({"dailymotion.com", "www.dailymotion.com", "dai.ly"}), ("mp4", "mp3")
    ),
    Platform.TWITCH: PlatformConfig(
        "Twitch", frozenset({"twitch.tv", "www.twitch.tv", "clips.twitch.tv"}), ("mp4", "mp3")
    ),
    Platform.REDDIT: PlatformConfig(
        "Reddit",
        frozenset({"reddit.com", "www.reddit.com", "old.reddit.com", "new.reddit.com", "v.redd.it"}),
        ("mp4", "mp3"),
    ),
    Platform.PINTEREST: PlatformConfig(
        "Pinterest", frozenset({"pinterest.com", "www.pinterest.com", "pin.it"}), ("mp4", "mp3")
    ),
    Platform.XVIDEOS: PlatformConfig(
        "XVideos", frozenset({"xvideos.com", "www.xvideos.com"}), ("mp4",)
    ),
}

_DOMAIN_TO_PLATFORM = {
    domain: platform for platform, config in PLATFORM_CONFIGS.items() for domain in config.domains
}
SUPPORTED_DOMAINS = frozenset(_DOMAIN_TO_PLATFORM)
SUPPORTED_PLATFORMS = tuple(Platform)


def _parse_safe_url(url: str):
    if not isinstance(url, str) or not url or len(url) > 2000:
        return None
    try:
        parsed = urlparse(url.strip())
        hostname = (parsed.hostname or "").lower().rstrip(".")
    except ValueError:
        return None
    if (
        parsed.scheme not in {"http", "https"}
        or not hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.port is not None
    ):
        return None
    return parsed, hostname


def detect_platform(url: str) -> Optional[Platform]:
    """Return the supported platform for *url*, or ``None`` for an unsafe URL."""
    parsed_url = _parse_safe_url(url)
    if parsed_url is None:
        return None
    _, hostname = parsed_url
    return _DOMAIN_TO_PLATFORM.get(hostname)


def validate_url(url: str) -> bool:
    """Validate that *url* is an HTTP(S) URL on an explicitly supported host."""
    return detect_platform(url) is not None


def get_platform_config(platform: Platform | str) -> PlatformConfig:
    """Get configuration for a detected platform."""
    try:
        return PLATFORM_CONFIGS[platform if isinstance(platform, Platform) else Platform(platform)]
    except (KeyError, ValueError) as exc:
        raise ValueError(f"Unsupported platform: {platform}") from exc


def platform_name(platform: Platform | str) -> str:
    """Return the display name for a platform."""
    return get_platform_config(platform).name


def allowed_formats(platform: Platform | str) -> tuple[str, ...]:
    """Return formats allowed by the platform policy."""
    return get_platform_config(platform).formats


class PlatformDetector:
    """Small class facade for callers that prefer an object-oriented API."""

    @staticmethod
    def detect(url: str) -> Optional[Platform]:
        return detect_platform(url)

    @staticmethod
    def detect_platform(url: str) -> Optional[Platform]:
        return detect_platform(url)

    @staticmethod
    def validate(url: str) -> bool:
        return validate_url(url)


# Friendly aliases kept at module level for API consumers.
is_supported_url = validate_url
is_valid_url = validate_url
get_platform = detect_platform


__all__ = [
    "Platform",
    "PlatformConfig",
    "PlatformDetector",
    "PLATFORM_CONFIGS",
    "SUPPORTED_DOMAINS",
    "SUPPORTED_PLATFORMS",
    "allowed_formats",
    "detect_platform",
    "get_platform",
    "get_platform_config",
    "is_valid_url",
    "is_supported_url",
    "platform_name",
    "validate_url",
]
