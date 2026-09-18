import secrets
from fastapi import Request

COOKIE_NAME = "streamdown_csrf"


def get_token(request: Request) -> str:
    return request.cookies.get(COOKIE_NAME) or secrets.token_urlsafe(32)


def is_valid(request: Request, token: str) -> bool:
    expected = request.cookies.get(COOKIE_NAME)
    return bool(expected and token and secrets.compare_digest(expected, token))
