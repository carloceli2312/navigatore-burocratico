import time
from collections import defaultdict

_windows: dict[str, list[float]] = defaultdict(list)

LIMIT = 10   # max requests per window
WINDOW = 60  # window size in seconds


def check_rate_limit(key: str) -> bool:
    """Return True if the request is allowed, False if rate-limited."""
    now = time.time()
    _windows[key] = [t for t in _windows[key] if now - t < WINDOW]
    if len(_windows[key]) >= LIMIT:
        return False
    _windows[key].append(now)
    return True
