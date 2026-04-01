"""MCP server — Procedure Agent per Navigatore Burocratico.

Espone strumenti per creare, validare e gestire le procedure burocratiche
nel formato JSON usato dall'app. Pensato per essere usato dall'AI (Claude
o altro) che fornisce il contenuto ricercato; il server gestisce schema,
validazione e persistenza.

Avvio standalone:
    python -m procedure_agent.server

Registrazione in Claude Code (.mcp.json nella root del progetto):
    { "mcpServers": { "procedure-agent": { "command": "python",
      "args": ["-m", "procedure_agent.server"] } } }
"""

import json
import re
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# ── Costanti ──────────────────────────────────────────────────────────────────

DATA_DIR = Path(__file__).parent.parent / "data" / "procedures" / "calabria" / "cosenza"

VALID_CATEGORIES = {
    "anagrafe": "Documenti d'identità, certificati anagrafici, residenza",
    "stato-civile": "Nascite, matrimoni, decessi, cittadinanza",
    "tributi": "IMU, TARI, TASI e altri tributi locali",
    "edilizia": "Permessi di costruire, SCIA edilizia, agibilità",
    "mobilita": "ZTL, contrassegni disabili, parcheggi, patenti",
    "attivita-produttive": "Apertura attività, SCIA commercio, licenze",
    "lavoro": "Centro impiego, NASPI, sussidi, tirocini",
    "sociale": "Bonus, assegni familiari, servizi sociali",
}

REQUIRED_TOP_FIELDS = {"slug", "name", "category", "description", "ente_competente", "tags", "steps"}
REQUIRED_STEP_FIELDS = {"order", "title", "description"}
REQUIRED_DOC_FIELDS = {"name"}

SCHEMA_DESCRIPTION = """
# Schema JSON — Procedura Burocratica

## Campi radice (tutti obbligatori salvo nota)

| Campo | Tipo | Descrizione |
|---|---|---|
| slug | string | Identificatore kebab-case, es. "carta-identita-cosenza" |
| name | string | Nome completo della procedura |
| category | string | Vedi categorie valide sotto |
| description | string | Descrizione breve (2-4 righe) per l'utente |
| ente_competente | string | Ufficio/i responsabili, es. "Comune di Cosenza — Anagrafe" |
| tags | array[string] | Parole chiave per la ricerca |
| tempo_stimato_giorni | integer | (opzionale) Giorni stimati per completare |
| costo_stimato_eur | number | (opzionale) Costo totale stimato in euro (0 se gratuito) |
| steps | array[Step] | Lista degli step nell'ordine corretto |

## Categorie valide

{categories}

## Step

| Campo | Tipo | Descrizione |
|---|---|---|
| order | integer | Posizione (1, 2, 3…) |
| title | string | Titolo breve dello step |
| description | string | Istruzioni dettagliate per il cittadino |
| ufficio | string | (opzionale) Ufficio specifico per questo step |
| costo_stimato_eur | number | (opzionale) Costo di questo step |
| tempo_stimato_giorni | integer | (opzionale) Giorni per questo step |
| documents | array[Document] | Documenti necessari per questo step |

## Document

| Campo | Tipo | Descrizione |
|---|---|---|
| name | string | Nome del documento |
| required | boolean | true se obbligatorio, false se condizionale |
| notes | string | (opzionale) Note aggiuntive, condizioni, dove ottenerlo |

## Note editoriali
- Usa il tono diretto rivolto al cittadino ("Presenta la domanda…", "Verifica che…")
- Non inventare costi o tempistiche: usa solo dati verificati da fonti ufficiali
- Se un dato non è trovato, ometti il campo opzionale (non mettere null né 0 a caso)
- Il slug deve essere univoco: controlla con list_procedures() prima di salvare
"""


# ── MCP server ────────────────────────────────────────────────────────────────

mcp = FastMCP(
    "procedure-agent",
    instructions=(
        "Sei un agente specializzato nella creazione di procedure burocratiche per "
        "la Provincia di Cosenza. Usa gli strumenti per consultare lo schema, "
        "verificare le procedure esistenti e salvare quelle nuove dopo averle "
        "ricercate da fonti ufficiali (comune.cosenza.it, regione.calabria.it, "
        "agenziaentrate.gov.it, inps.it, ecc.)."
    ),
)


# ── Tools ─────────────────────────────────────────────────────────────────────

@mcp.tool()
def get_schema() -> str:
    """Restituisce lo schema completo con descrizioni dei campi e categorie valide.
    Chiamalo prima di generare una nuova procedura per conoscere il formato atteso.
    """
    categories_table = "\n".join(
        f"- **{k}**: {v}" for k, v in VALID_CATEGORIES.items()
    )
    return SCHEMA_DESCRIPTION.format(categories=categories_table)


@mcp.tool()
def get_template(category: str) -> str:
    """Restituisce un template JSON commentato per la categoria indicata.

    Args:
        category: Una delle categorie valide (anagrafe, stato-civile, tributi,
                  edilizia, mobilita, attivita-produttive, lavoro, sociale)
    """
    if category not in VALID_CATEGORIES:
        valid = ", ".join(VALID_CATEGORIES.keys())
        return f"Categoria non valida: '{category}'. Valide: {valid}"

    template = {
        "slug": f"nome-procedura-cosenza",
        "name": "Nome completo della procedura",
        "category": category,
        "description": "Descrizione per il cittadino (2-4 righe). Spiega cos'è, quando serve e l'iter generale.",
        "ente_competente": "Comune di Cosenza — Ufficio competente",
        "tags": [category, "cosenza", "parola-chiave"],
        "tempo_stimato_giorni": None,
        "costo_stimato_eur": None,
        "steps": [
            {
                "order": 1,
                "title": "Titolo dello step",
                "description": "Istruzioni dettagliate per il cittadino.",
                "ufficio": None,
                "costo_stimato_eur": None,
                "tempo_stimato_giorni": None,
                "documents": [
                    {
                        "name": "Nome documento",
                        "required": True,
                        "notes": "Dove ottenerlo o condizioni particolari",
                    }
                ],
            }
        ],
    }
    return json.dumps(template, ensure_ascii=False, indent=2)


@mcp.tool()
def list_procedures() -> str:
    """Elenca tutte le procedure già presenti nel progetto.
    Utile per evitare duplicati e capire cosa manca ancora.
    """
    if not DATA_DIR.exists():
        return f"Directory non trovata: {DATA_DIR}"

    files = sorted(DATA_DIR.glob("*.json"))
    if not files:
        return "Nessuna procedura trovata."

    results = []
    for path in files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            slug = data.get("slug", path.stem)
            name = data.get("name", "?")
            category = data.get("category", "?")
            n_steps = len(data.get("steps", []))
            results.append(f"- [{category}] **{slug}** — {name} ({n_steps} step)")
        except Exception:
            results.append(f"- {path.name} (errore lettura)")

    total = len(files)
    return f"**{total} procedure esistenti:**\n\n" + "\n".join(results)


@mcp.tool()
def read_procedure(slug: str) -> str:
    """Legge e restituisce il JSON di una procedura esistente.

    Args:
        slug: Il slug della procedura (es. "carta-identita-cosenza")
    """
    path = DATA_DIR / f"{slug}.json"
    if not path.exists():
        return f"Procedura non trovata: {slug}"
    return path.read_text(encoding="utf-8")


@mcp.tool()
def save_procedure(json_data: str, overwrite: bool = False) -> str:
    """Valida e salva una procedura nel progetto.

    Controlla che tutti i campi obbligatori siano presenti e che il formato
    sia corretto, poi salva il file in data/procedures/calabria/cosenza/.

    Args:
        json_data: Stringa JSON della procedura da salvare
        overwrite: Se True, sovrascrive una procedura esistente con lo stesso slug
    """
    # Parse
    try:
        data = json.loads(json_data)
    except json.JSONDecodeError as e:
        return f"JSON non valido: {e}"

    # Campi radice obbligatori
    missing = REQUIRED_TOP_FIELDS - set(data.keys())
    if missing:
        return f"Campi obbligatori mancanti: {', '.join(sorted(missing))}"

    # Slug
    slug = data["slug"]
    if not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", slug):
        return f"Slug non valido: '{slug}'. Usa solo lettere minuscole, numeri e trattini."

    # Categoria
    category = data["category"]
    if category not in VALID_CATEGORIES:
        valid = ", ".join(VALID_CATEGORIES.keys())
        return f"Categoria non valida: '{category}'. Valide: {valid}"

    # Tags
    if not isinstance(data["tags"], list) or len(data["tags"]) == 0:
        return "Il campo 'tags' deve essere una lista non vuota."

    # Steps
    steps = data.get("steps", [])
    if not isinstance(steps, list):
        return "Il campo 'steps' deve essere una lista."

    for i, step in enumerate(steps):
        missing_step = REQUIRED_STEP_FIELDS - set(step.keys())
        if missing_step:
            return f"Step {i+1}: campi obbligatori mancanti: {', '.join(sorted(missing_step))}"
        for j, doc in enumerate(step.get("documents", [])):
            missing_doc = REQUIRED_DOC_FIELDS - set(doc.keys())
            if missing_doc:
                return f"Step {i+1}, documento {j+1}: campi mancanti: {', '.join(sorted(missing_doc))}"

    # File esistente?
    path = DATA_DIR / f"{slug}.json"
    if path.exists() and not overwrite:
        return (
            f"Procedura '{slug}' già esistente. "
            "Usa overwrite=True per sovrascriverla, oppure leggi quella attuale con read_procedure()."
        )

    # Salva
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    action = "sovrascritta" if path.exists() else "salvata"
    return f"Procedura '{slug}' {action} in {path.relative_to(Path(__file__).parent.parent)}"


@mcp.tool()
def delete_procedure(slug: str) -> str:
    """Elimina una procedura esistente.

    Args:
        slug: Il slug della procedura da eliminare
    """
    path = DATA_DIR / f"{slug}.json"
    if not path.exists():
        return f"Procedura non trovata: '{slug}'"
    path.unlink()
    return f"Procedura '{slug}' eliminata."


# ── Entrypoint ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    mcp.run()
