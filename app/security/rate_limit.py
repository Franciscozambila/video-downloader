from collections import defaultdict
import time
from threading import Lock


class RateLimiter:
    def __init__(self, max_requests: int = 30, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: dict[str, list[float]] = defaultdict(list)
        self._lock = Lock()

    def check_rate_limit(self, key: str) -> bool:
        now = time.monotonic()
        cutoff = now - self.window_seconds
        with self._lock:
            recent = [stamp for stamp in self.requests[key] if stamp > cutoff]
            if len(recent) >= self.max_requests:
                self.requests[key] = recent
                return False
            recent.append(now)
            self.requests[key] = recent
            return True


rate_limiter = RateLimiter()
