import time
from dataclasses import dataclass, field
from threading import Lock
from typing import Any


@dataclass
class _CacheEntry:
    value: Any
    expires_at: float


@dataclass
class CacheStats:
    hits: int = 0
    misses: int = 0
    total_requests: int = 0
    evictions: int = 0

    @property
    def hit_rate(self) -> float:
        if self.total_requests == 0:
            return 0.0
        return round(self.hits / self.total_requests * 100, 2)

    def to_dict(self) -> dict:
        return {
            "hits": self.hits,
            "misses": self.misses,
            "total_requests": self.total_requests,
            "evictions": self.evictions,
            "hit_rate_pct": self.hit_rate,
        }


class TTLCache:
    """Thread-safe in-memory TTL cache — PerformanceTracker equivalent for the backend."""

    def __init__(self) -> None:
        self._store: dict[str, _CacheEntry] = {}
        self._lock = Lock()
        self.stats = CacheStats()

    def get(self, key: str) -> Any | None:
        with self._lock:
            self.stats.total_requests += 1
            entry = self._store.get(key)
            if entry is None:
                self.stats.misses += 1
                return None
            if time.monotonic() > entry.expires_at:
                del self._store[key]
                self.stats.evictions += 1
                self.stats.misses += 1
                return None
            self.stats.hits += 1
            return entry.value

    def set(self, key: str, value: Any, ttl: int) -> None:
        with self._lock:
            self._store[key] = _CacheEntry(value=value, expires_at=time.monotonic() + ttl)

    def delete(self, key: str) -> None:
        with self._lock:
            self._store.pop(key, None)

    def clear(self) -> None:
        with self._lock:
            self._store.clear()

    def size(self) -> int:
        with self._lock:
            now = time.monotonic()
            return sum(1 for e in self._store.values() if e.expires_at > now)


cache = TTLCache()
