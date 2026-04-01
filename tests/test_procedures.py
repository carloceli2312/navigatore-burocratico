async def test_list_procedures(seeded_client):
    response = await seeded_client.get("/v1/procedures")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2
    slugs = [p["slug"] for p in data]
    assert "scia-edilizia-cosenza" in slugs
    assert "permesso-costruire-cosenza" in slugs


async def test_list_procedures_fields(seeded_client):
    response = await seeded_client.get("/v1/procedures")
    proc = response.json()[0]
    for field in ("slug", "name", "category", "description", "ente_competente", "tags"):
        assert field in proc
    assert "steps" not in proc  # steps only in detail endpoint


async def test_get_procedure_detail(seeded_client):
    response = await seeded_client.get("/v1/procedures/scia-edilizia-cosenza")
    assert response.status_code == 200
    data = response.json()
    assert data["slug"] == "scia-edilizia-cosenza"
    assert "steps" in data
    assert len(data["steps"]) >= 1
    step = data["steps"][0]
    assert step["order"] == 1
    assert "documents" in step


async def test_get_procedure_steps(seeded_client):
    response = await seeded_client.get("/v1/procedures/scia-edilizia-cosenza/steps")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    orders = [s["order"] for s in data]
    assert orders == sorted(orders)


async def test_get_procedure_not_found(seeded_client):
    response = await seeded_client.get("/v1/procedures/procedura-inesistente")
    assert response.status_code == 404


async def test_get_procedure_steps_not_found(seeded_client):
    response = await seeded_client.get("/v1/procedures/procedura-inesistente/steps")
    assert response.status_code == 404
