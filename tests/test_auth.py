from httpx import AsyncClient

_USER = {"email": "test@example.com", "password": "password123"}


async def _register_and_login(client: AsyncClient) -> str:
    await client.post("/v1/auth/register", json=_USER)
    response = await client.post(
        "/v1/auth/token", data={"username": _USER["email"], "password": _USER["password"]}
    )
    return response.json()["access_token"]


async def test_register(auth_client):
    response = await auth_client.post("/v1/auth/register", json=_USER)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == _USER["email"]
    assert data["is_active"] is True
    assert "hashed_password" not in data


async def test_register_duplicate(auth_client):
    await auth_client.post("/v1/auth/register", json=_USER)
    response = await auth_client.post("/v1/auth/register", json=_USER)
    assert response.status_code == 409


async def test_register_invalid_email(auth_client):
    response = await auth_client.post(
        "/v1/auth/register", json={"email": "not-an-email", "password": "password123"}
    )
    assert response.status_code == 422


async def test_register_short_password(auth_client):
    response = await auth_client.post(
        "/v1/auth/register", json={"email": "a@b.com", "password": "short"}
    )
    assert response.status_code == 422


async def test_login(auth_client):
    await auth_client.post("/v1/auth/register", json=_USER)
    response = await auth_client.post(
        "/v1/auth/token", data={"username": _USER["email"], "password": _USER["password"]}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


async def test_login_wrong_password(auth_client):
    await auth_client.post("/v1/auth/register", json=_USER)
    response = await auth_client.post(
        "/v1/auth/token", data={"username": _USER["email"], "password": "wrongpass"}
    )
    assert response.status_code == 401


async def test_login_unknown_user(auth_client):
    response = await auth_client.post(
        "/v1/auth/token", data={"username": "nobody@example.com", "password": "password123"}
    )
    assert response.status_code == 401


async def test_me(auth_client):
    token = await _register_and_login(auth_client)
    response = await auth_client.get("/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert response.json()["email"] == _USER["email"]


async def test_me_no_token(auth_client):
    response = await auth_client.get("/v1/auth/me")
    assert response.status_code == 401


async def test_me_invalid_token(auth_client):
    response = await auth_client.get(
        "/v1/auth/me", headers={"Authorization": "Bearer notavalidtoken"}
    )
    assert response.status_code == 401


async def test_refresh(auth_client):
    await auth_client.post("/v1/auth/register", json=_USER)
    token_response = await auth_client.post(
        "/v1/auth/token", data={"username": _USER["email"], "password": _USER["password"]}
    )
    refresh_token = token_response.json()["refresh_token"]
    response = await auth_client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    assert "access_token" in response.json()


async def test_refresh_with_access_token_fails(auth_client):
    """Access token must not be accepted as refresh token."""
    token = await _register_and_login(auth_client)
    response = await auth_client.post("/v1/auth/refresh", json={"refresh_token": token})
    assert response.status_code == 401
