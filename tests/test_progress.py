from httpx import AsyncClient

_USER = {"email": "progress@example.com", "password": "password123"}


async def _auth_headers(client: AsyncClient) -> dict:
    await client.post("/v1/auth/register", json=_USER)
    response = await client.post(
        "/v1/auth/token", data={"username": _USER["email"], "password": _USER["password"]}
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


async def test_update_and_get_progress(auth_client):
    headers = await _auth_headers(auth_client)
    slug = "scia-edilizia-cosenza"

    put_response = await auth_client.put(
        f"/v1/progress/{slug}", json={"completed_steps": [1, 2]}, headers=headers
    )
    assert put_response.status_code == 200
    data = put_response.json()
    assert data["procedure_slug"] == slug
    assert data["completed_steps"] == [1, 2]
    assert "started_at" in data
    assert "updated_at" in data

    get_response = await auth_client.get(f"/v1/progress/{slug}", headers=headers)
    assert get_response.status_code == 200
    assert get_response.json()["completed_steps"] == [1, 2]


async def test_update_progress_overwrites(auth_client):
    headers = await _auth_headers(auth_client)
    slug = "scia-edilizia-cosenza"

    await auth_client.put(f"/v1/progress/{slug}", json={"completed_steps": [1]}, headers=headers)
    await auth_client.put(
        f"/v1/progress/{slug}", json={"completed_steps": [1, 2, 3]}, headers=headers
    )

    response = await auth_client.get(f"/v1/progress/{slug}", headers=headers)
    assert response.json()["completed_steps"] == [1, 2, 3]


async def test_get_progress_not_started(auth_client):
    headers = await _auth_headers(auth_client)
    response = await auth_client.get("/v1/progress/scia-edilizia-cosenza", headers=headers)
    assert response.status_code == 404


async def test_progress_requires_auth(auth_client):
    get_response = await auth_client.get("/v1/progress/scia-edilizia-cosenza")
    put_response = await auth_client.put(
        "/v1/progress/scia-edilizia-cosenza", json={"completed_steps": [1]}
    )
    assert get_response.status_code == 401
    assert put_response.status_code == 401
