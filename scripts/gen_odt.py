"""Generate analisi-tecnica.odt from the markdown source."""
from pathlib import Path
import re

from odf.opendocument import OpenDocumentText
from odf.style import (
    Style, TextProperties, ParagraphProperties, TableProperties,
    TableColumnProperties, TableRowProperties, TableCellProperties,
)
from odf.text import (
    H, P, Span, List, ListItem, ListStyle,
)
from odf import text as odftext
from odf.table import Table, TableColumn, TableRow, TableCell
from odf.namespaces import TEXTNS

ROOT = Path(__file__).resolve().parent.parent
MD   = ROOT / "docs" / "analisi-tecnica.md"
OUT  = ROOT / "docs" / "analisi-tecnica.odt"


# ── document & styles ────────────────────────────────────────────────────────
doc = OpenDocumentText()

def add_style(name, family, parent=None, **props):
    s = Style(name=name, family=family)
    if parent:
        s.setAttribute("parentstylename", parent)
    tp_props = {k: v for k, v in props.items() if k in {
        "fontsize","fontweight","fontstyle","color","backgroundcolor",
        "fontfamily","fontname",
    }}
    pp_props = {k: v for k, v in props.items() if k in {
        "marginleft","marginright","margintop","marginbottom",
        "textalign","borderlinewidth","borderleft","borderbottom","padding",
        "backgroundcolor2",
    }}
    if tp_props:
        kw = {}
        if "fontsize" in tp_props:      kw["fontsize"]      = tp_props["fontsize"]
        if "fontweight" in tp_props:    kw["fontweight"]     = tp_props["fontweight"]
        if "fontstyle" in tp_props:     kw["fontstyle"]      = tp_props["fontstyle"]
        if "color" in tp_props:         kw["color"]          = tp_props["color"]
        if "fontfamily" in tp_props:    kw["fontfamily"]     = tp_props["fontfamily"]
        if "fontname" in tp_props:      kw["fontname"]       = tp_props["fontname"]
        s.addElement(TextProperties(**kw))
    if pp_props or "backgroundcolor2" in props:
        kw2 = {}
        if "marginleft"   in pp_props: kw2["marginleft"]   = pp_props["marginleft"]
        if "marginright"  in pp_props: kw2["marginright"]  = pp_props["marginright"]
        if "margintop"    in pp_props: kw2["margintop"]    = pp_props["margintop"]
        if "marginbottom" in pp_props: kw2["marginbottom"] = pp_props["marginbottom"]
        if "textalign"    in pp_props: kw2["textalign"]    = pp_props["textalign"]
        if "backgroundcolor2" in props: kw2["backgroundcolor"] = props["backgroundcolor2"]
        s.addElement(ParagraphProperties(**kw2))
    doc.styles.addElement(s)
    return s

add_style("DocTitle",  "paragraph", fontsize="22pt", fontweight="bold",
          color="#1a3a5c", margintop="0cm", marginbottom="0.4cm", textalign="left")
add_style("Meta",      "paragraph", fontsize="9pt",  color="#888888", marginbottom="0.5cm")
add_style("Heading1",  "paragraph", fontsize="16pt", fontweight="bold", color="#1a3a5c",
          margintop="0.6cm", marginbottom="0.2cm")
add_style("Heading2",  "paragraph", fontsize="13pt", fontweight="bold", color="#2c5f8a",
          margintop="0.45cm", marginbottom="0.15cm")
add_style("Heading3",  "paragraph", fontsize="11pt", fontweight="bold", color="#2c5f8a",
          margintop="0.3cm", marginbottom="0.1cm")
add_style("Body",      "paragraph", fontsize="10pt", margintop="0cm", marginbottom="0.15cm")
add_style("Bullet",    "paragraph", fontsize="10pt", marginleft="0.5cm", marginbottom="0.1cm")
add_style("CheckDone", "paragraph", fontsize="9.5pt", color="#2e7d32",
          marginleft="0.6cm", marginbottom="0.08cm")
add_style("CheckTodo", "paragraph", fontsize="9.5pt", color="#555555",
          marginleft="0.6cm", marginbottom="0.08cm")
add_style("Code",      "paragraph", fontsize="8.5pt", fontfamily="Courier New",
          backgroundcolor2="#f5f5f5", marginleft="0.4cm", marginright="0.4cm",
          margintop="0.1cm", marginbottom="0.2cm")

# inline styles
bold_style = Style(name="Bold", family="text")
bold_style.addElement(TextProperties(fontweight="bold"))
doc.styles.addElement(bold_style)

code_inline = Style(name="CodeInline", family="text")
code_inline.addElement(TextProperties(fontfamily="Courier New", fontsize="9pt", color="#c7254e"))
doc.styles.addElement(code_inline)

italic_style = Style(name="Italic", family="text")
italic_style.addElement(TextProperties(fontstyle="italic"))
doc.styles.addElement(italic_style)

# table styles
tbl_style = Style(name="TableStyle", family="table")
tbl_style.addElement(TableProperties(width="16cm", align="left"))
doc.styles.addElement(tbl_style)

col_style = Style(name="ColStyle", family="table-column")
doc.styles.addElement(col_style)

row_style = Style(name="RowStyle", family="table-row")
doc.styles.addElement(row_style)

hdr_cell = Style(name="HeaderCell", family="table-cell")
hdr_cell.addElement(TableCellProperties(backgroundcolor="#1a3a5c", padding="0.1cm"))
doc.styles.addElement(hdr_cell)

body_cell = Style(name="BodyCell", family="table-cell")
body_cell.addElement(TableCellProperties(backgroundcolor="#f7f9fc", padding="0.1cm",
                                          bordertop="0.5pt solid #cccccc",
                                          borderbottom="0.5pt solid #cccccc"))
doc.styles.addElement(body_cell)

hdr_text = Style(name="HeaderText", family="paragraph")
hdr_text.addElement(TextProperties(fontweight="bold", color="#ffffff", fontsize="9pt"))
doc.styles.addElement(hdr_text)

cell_text = Style(name="CellText", family="paragraph")
cell_text.addElement(TextProperties(fontsize="9pt"))
doc.styles.addElement(cell_text)

# ── helpers ──────────────────────────────────────────────────────────────────
def make_p(text: str, style_name: str) -> P:
    p = P(stylename=style_name)
    _add_inline(p, text)
    return p

def _add_inline(parent, text: str):
    """Render inline markdown into ODF spans."""
    # pattern: **bold**, *italic*, `code`
    pattern = re.compile(r"(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*)")
    parts = pattern.split(text)
    for part in parts:
        if part.startswith("**") and part.endswith("**"):
            sp = Span(stylename="Bold")
            sp.addText(part[2:-2])
            parent.addElement(sp)
        elif part.startswith("*") and part.endswith("*"):
            sp = Span(stylename="Italic")
            sp.addText(part[1:-1])
            parent.addElement(sp)
        elif part.startswith("`") and part.endswith("`"):
            sp = Span(stylename="CodeInline")
            sp.addText(part[1:-1])
            parent.addElement(sp)
        else:
            parent.addText(part)

def parse_table_rows(lines):
    rows = []
    for line in lines:
        if re.match(r"^\|[-:| ]+\|$", line.strip()):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows

def build_odt_table(rows):
    if not rows:
        return None
    col_count = max(len(r) for r in rows)
    rows = [r + [""] * (col_count - len(r)) for r in rows]
    col_w = f"{16 / col_count:.2f}cm"

    cs = Style(name=f"Col_{id(rows)}", family="table-column")
    cs.addElement(TableColumnProperties(columnwidth=col_w))
    doc.styles.addElement(cs)

    t = Table(stylename="TableStyle")
    for _ in range(col_count):
        t.addElement(TableColumn(stylename=cs.getAttribute("name")))

    for ri, row in enumerate(rows):
        tr = TableRow(stylename="RowStyle")
        for ci, cell_text_val in enumerate(row):
            cell_style = "HeaderCell" if ri == 0 else "BodyCell"
            text_style = "HeaderText" if ri == 0 else "CellText"
            tc = TableCell(stylename=cell_style)
            p = P(stylename=text_style)
            _add_inline(p, cell_text_val)
            tc.addElement(p)
            tr.addElement(tc)
        t.addElement(tr)
    return t

# ── parser ───────────────────────────────────────────────────────────────────
def parse(md_text: str):
    lines = md_text.splitlines()
    i = 0
    in_code = False
    code_buf = []
    table_buf = []

    while i < len(lines):
        line = lines[i]

        # fenced code block
        if line.startswith("```"):
            if not in_code:
                in_code = True
                code_buf = []
            else:
                in_code = False
                for cline in code_buf:
                    doc.text.addElement(P(stylename="Code", text=cline if cline else " "))
            i += 1
            continue
        if in_code:
            code_buf.append(line)
            i += 1
            continue

        # table
        if line.startswith("|"):
            table_buf.append(line)
            i += 1
            continue
        else:
            if table_buf:
                t = build_odt_table(parse_table_rows(table_buf))
                if t:
                    doc.text.addElement(t)
                    doc.text.addElement(P(stylename="Body", text=" "))
                table_buf = []

        # headings
        if re.match(r"^# [^#]", line):
            text = line[2:].strip()
            if "Navigatore" in text:
                doc.text.addElement(make_p(text, "DocTitle"))
            else:
                doc.text.addElement(H(outlinelevel=1, stylename="Heading1", text=text))
            i += 1
            continue
        if line.startswith("## "):
            doc.text.addElement(H(outlinelevel=2, stylename="Heading2", text=line[3:].strip()))
            i += 1
            continue
        if line.startswith("### "):
            doc.text.addElement(H(outlinelevel=3, stylename="Heading3", text=line[4:].strip()))
            i += 1
            continue

        # hr
        if re.match(r"^---+$", line.strip()):
            doc.text.addElement(P(stylename="Body", text=" "))
            i += 1
            continue

        # checklist
        if line.strip().startswith("- [x]"):
            text = line.strip()[5:].strip()
            doc.text.addElement(make_p("✅ " + text, "CheckDone"))
            i += 1
            continue
        if line.strip().startswith("- [ ]"):
            text = line.strip()[5:].strip()
            doc.text.addElement(make_p("☐ " + text, "CheckTodo"))
            i += 1
            continue

        # bullet
        if re.match(r"^\s*[-*] ", line):
            text = re.sub(r"^\s*[-*] ", "", line)
            doc.text.addElement(make_p("• " + text, "Bullet"))
            i += 1
            continue

        # blank
        if not line.strip():
            doc.text.addElement(P(stylename="Body", text=" "))
            i += 1
            continue

        # normal
        doc.text.addElement(make_p(line, "Body"))
        i += 1

    if table_buf:
        t = build_odt_table(parse_table_rows(table_buf))
        if t:
            doc.text.addElement(t)


# ── run ───────────────────────────────────────────────────────────────────────
parse(MD.read_text(encoding="utf-8"))
doc.save(str(OUT))
print(f"ODT creato: {OUT}")
