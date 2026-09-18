import os
import sys
from pathlib import Path
from uuid import uuid4

import httpx
import pytest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))


@pytest.fixture
def api_url() -> str:
    return os.getenv("API_URL", "http://127.0.0.1:8000").rstrip("/")


@pytest.fixture
def web_url() -> str:
    return os.getenv("WEB_URL", "http://127.0.0.1:3000").rstrip("/")


@pytest.fixture
def unique_name() -> str:
    return f"student-{uuid4().hex[:10]}"


@pytest.fixture
def registered_user(api_url: str, unique_name: str) -> dict:
    payload = {
        "user": {
            "username": unique_name,
            "email": f"{unique_name}@example.com",
            "password": "safe-password-123",
        }
    }
    response = httpx.post(f"{api_url}/api/users", json=payload, timeout=15)
    assert response.status_code == 200, response.text
    return response.json()["user"]
