"""Generate analisi-tecnica.pdf from the markdown source."""
from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, Preformatted,
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER
import re

# ── paths ────────────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
MD   = ROOT / "docs" / "analisi-tecnica.md"
OUT  = ROOT / "docs" / "analisi-tecnica.pdf"

# ── styles ───────────────────────────────────────────────────────────────────
base = getSampleStyleSheet()

def S(name, parent="Normal", **kw):
    return ParagraphStyle(name, parent=base[parent], **kw)

styles = {
    "title":    S("DocTitle",  "Title",   fontSize=22, spaceAfter=6, textColor=colors.HexColor("#1a3a5c")),
    "meta":     S("Meta",      "Normal",  fontSize=9,  textColor=colors.grey, spaceAfter=16),
    "h1":       S("H1",        "Heading1",fontSize=16, spaceBefore=18, spaceAfter=6,
                  textColor=colors.HexColor("#1a3a5c"), borderPad=(0,0,2,0)),
    "h2":       S("H2",        "Heading2",fontSize=13, spaceBefore=14, spaceAfter=4,
                  textColor=colors.HexColor("#2c5f8a")),
    "h3":       S("H3",        "Heading3",fontSize=11, spaceBefore=10, spaceAfter=3,
                  textColor=colors.HexColor("#2c5f8a")),
    "body":     S("Body",      "Normal",  fontSize=9.5, leading=14, spaceAfter=6),
    "bullet":   S("Bullet",    "Normal",  fontSize=9.5, leading=13, spaceAfter=3,
                  leftIndent=14, firstLineIndent=0),
    "check_done": S("CheckDone","Normal", fontSize=9,  leading=12, spaceAfter=2,
                    leftIndent=18, textColor=colors.HexColor("#2e7d32")),
    "check_todo": S("CheckTodo","Normal", fontSize=9,  leading=12, spaceAfter=2,
                    leftIndent=18, textColor=colors.HexColor("#555555")),
    "code":     S("Code",      "Code",    fontSize=8,  leading=11, spaceAfter=8,
                  backColor=colors.HexColor("#f5f5f5"), leftIndent=10, rightIndent=10,
                  borderColor=colors.HexColor("#dddddd"), borderWidth=0.5, borderPad=5),
}

# ── helpers ──────────────────────────────────────────────────────────────────
def escape(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def inline(text: str) -> str:
    """Convert inline markdown (bold, code, italic) to reportlab XML."""
    text = escape(text)
    text = re.sub(r"`([^`]+)`", r'<font name="Courier" size="8" color="#c7254e">\1</font>', text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*(.+?)\*",     r"<i>\1</i>", text)
    return text

def parse_table(lines):
    """Parse a markdown table into a list of row lists."""
    rows = []
    for line in lines:
        if re.match(r"^\|[-:| ]+\|$", line.strip()):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows

def build_table_flowable(rows):
    if not rows:
        return None
    col_count = max(len(r) for r in rows)
    # normalise row lengths
    rows = [r + [""] * (col_count - len(r)) for r in rows]
    # convert cells to Paragraphs
    header_style = ParagraphStyle("TH", parent=base["Normal"], fontSize=8.5,
                                  fontName="Helvetica-Bold", textColor=colors.white)
    cell_style   = ParagraphStyle("TD", parent=base["Normal"], fontSize=8.5, leading=11)
    table_data = []
    for i, row in enumerate(rows):
        s = header_style if i == 0 else cell_style
        table_data.append([Paragraph(inline(cell), s) for cell in row])

    col_width = (A4[0] - 4*cm) / col_count
    t = Table(table_data, colWidths=[col_width] * col_count, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#1a3a5c")),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.HexColor("#f7f9fc"), colors.white]),
        ("GRID",      (0,0), (-1,-1), 0.4, colors.HexColor("#cccccc")),
        ("VALIGN",    (0,0), (-1,-1), "TOP"),
        ("TOPPADDING",(0,0), (-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1),4),
        ("LEFTPADDING",(0,0),(-1,-1),5),
    ]))
    return t

# ── parser ───────────────────────────────────────────────────────────────────
def md_to_flowables(md_text: str):
    flowables = []
    lines = md_text.splitlines()
    i = 0
    in_code = False
    code_buf = []
    table_buf = []

    while i < len(lines):
        line = lines[i]

        # ── fenced code block ────────────────────────────────────────────────
        if line.startswith("```"):
            if not in_code:
                in_code = True
                code_buf = []
            else:
                in_code = False
                flowables.append(Preformatted("\n".join(code_buf), styles["code"]))
                code_buf = []
            i += 1
            continue
        if in_code:
            code_buf.append(line)
            i += 1
            continue

        # ── markdown table ───────────────────────────────────────────────────
        if line.startswith("|"):
            table_buf.append(line)
            i += 1
            continue
        else:
            if table_buf:
                t = build_table_flowable(parse_table(table_buf))
                if t:
                    flowables.append(t)
                    flowables.append(Spacer(1, 8))
                table_buf = []

        # ── headings ─────────────────────────────────────────────────────────
        if line.startswith("# ") and not line.startswith("## "):
            text = line[2:].strip()
            if text.startswith("Navigatore"):
                # Document title
                flowables.append(Paragraph(escape(text), styles["title"]))
            else:
                flowables.append(Paragraph(escape(text), styles["h1"]))
                flowables.append(HRFlowable(width="100%", thickness=0.8,
                                            color=colors.HexColor("#1a3a5c"), spaceAfter=4))
            i += 1
            continue

        if line.startswith("## "):
            flowables.append(Paragraph(escape(line[3:].strip()), styles["h2"]))
            i += 1
            continue

        if line.startswith("### "):
            flowables.append(Paragraph(escape(line[4:].strip()), styles["h3"]))
            i += 1
            continue

        # ── horizontal rule ──────────────────────────────────────────────────
        if re.match(r"^---+$", line.strip()):
            flowables.append(HRFlowable(width="100%", thickness=0.5,
                                        color=colors.HexColor("#cccccc"),
                                        spaceBefore=6, spaceAfter=6))
            i += 1
            continue

        # ── meta lines (bold key: value at top) ─────────────────────────────
        if re.match(r"^\*\*\w", line):
            flowables.append(Paragraph(inline(line), styles["meta"]))
            i += 1
            continue

        # ── checklist items ──────────────────────────────────────────────────
        if line.strip().startswith("- [x]"):
            text = line.strip()[5:].strip()
            flowables.append(Paragraph("&#x2611; " + inline(text), styles["check_done"]))
            i += 1
            continue
        if line.strip().startswith("- [ ]"):
            text = line.strip()[5:].strip()
            flowables.append(Paragraph("&#x2610; " + inline(text), styles["check_todo"]))
            i += 1
            continue

        # ── bullet list ──────────────────────────────────────────────────────
        if re.match(r"^\s*[-*] ", line):
            text = re.sub(r"^\s*[-*] ", "", line)
            flowables.append(Paragraph("&#x2022;  " + inline(text), styles["bullet"]))
            i += 1
            continue

        # ── blank line ───────────────────────────────────────────────────────
        if not line.strip():
            flowables.append(Spacer(1, 4))
            i += 1
            continue

        # ── normal paragraph ─────────────────────────────────────────────────
        flowables.append(Paragraph(inline(line), styles["body"]))
        i += 1

    # flush pending table
    if table_buf:
        t = build_table_flowable(parse_table(table_buf))
        if t:
            flowables.append(t)

    return flowables

# ── build ─────────────────────────────────────────────────────────────────────
def main():
    md_text = MD.read_text(encoding="utf-8")

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm,
        topMargin=2.2*cm, bottomMargin=2.2*cm,
        title="Navigatore Burocratico — Analisi Tecnica",
        author="Navigatore Burocratico",
    )

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(colors.grey)
        canvas.drawString(2*cm, 1.2*cm, "Navigatore Burocratico — Analisi Tecnica v0.1")
        canvas.drawRightString(A4[0]-2*cm, 1.2*cm, f"Pagina {doc.page}")
        canvas.restoreState()

    story = md_to_flowables(md_text)
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"PDF creato: {OUT}")

if __name__ == "__main__":
    main()
