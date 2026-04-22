import time
import pytest
from app.services.cache_service import TTLCache


def test_cache_set_and_get():
    c = TTLCache()
    c.set("key", "value", ttl=10)
    assert c.get("key") == "value"


def test_cache_miss_returns_none():
    c = TTLCache()
    assert c.get("missing") is None


def test_cache_ttl_expiry():
    c = TTLCache()
    c.set("key", "value", ttl=0)
    time.sleep(0.01)
    assert c.get("key") is None


def test_cache_hit_rate():
    c = TTLCache()
    c.set("k", "v", ttl=10)
    c.get("k")   # hit
    c.get("k")   # hit
    c.get("x")   # miss
    assert c.stats.hits == 2
    assert c.stats.misses == 1
    assert c.stats.hit_rate == pytest.approx(66.67, abs=0.1)


def test_cache_size_excludes_expired():
    c = TTLCache()
    c.set("alive", "v", ttl=100)
    c.set("dead", "v", ttl=0)
    time.sleep(0.01)
    assert c.size() == 1


def test_cache_delete():
    c = TTLCache()
    c.set("k", "v", ttl=10)
    c.delete("k")
    assert c.get("k") is None


def test_cache_clear():
    c = TTLCache()
    c.set("a", 1, ttl=10)
    c.set("b", 2, ttl=10)
    c.clear()
    assert c.size() == 0


def test_cache_eviction_increments_counter():
    c = TTLCache()
    c.set("k", "v", ttl=0)
    time.sleep(0.01)
    c.get("k")
    assert c.stats.evictions == 1
