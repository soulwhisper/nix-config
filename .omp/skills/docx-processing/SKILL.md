---
name: docx-processing
description: >
  Use whenever reading or generating .docx files — extracting text, creating
  new Word reports with tables/headings/formatted text, or editing existing
  documents. Trigger when the user mentions 'Word doc', '.docx', asks for a
  report/memo/letter as a .docx, needs to extract content from a .docx, or
  references a .docx file by path. Do NOT use for PDFs, spreadsheets (.xlsx),
  Google Docs, or presentations (.pptx).
---

# DOCX Creation, Editing, and Analysis

## Quick Reference

| Task | Approach |
|---|---|
| Read/extract text | `zipfile` + `xml.etree.ElementTree` (stdlib, no deps) |
| Create simple report (text+tables) | Raw XML via Python stdlib — see [Creating New Documents](#creating-new-documents) |
| Create complex document (TOC, images, headers) | `docx-js` (npm) — see [docx-js Approach](#docx-js-approach) |
| Edit existing document | See [editing.md](editing.md) |
| Convert to images for QA | LibreOffice → PDF → `pdftoppm` |
| GB/T 9704 Chinese reports | See [GB/T 9704-2012 Standard](#gbt-9704-2012-standard) |

## Reading .docx

```python
import zipfile, xml.etree.ElementTree as ET

with zipfile.ZipFile('file.docx') as z:
    with z.open('word/document.xml') as xml:
        tree = ET.parse(xml)
        ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        for p in tree.findall('.//w:p', ns):
            texts = [t.text or '' for t in p.findall('.//w:t', ns)]
            line = ''.join(texts)
            if line.strip():
                print(line)
```

For tables, walk `.//w:tbl` → `.//w:tr` → `.//w:tc` → `.//w:p`/`.//w:t`.

## Creating New Documents

### Mode A: Raw XML (stdlib, no dependencies)

Best for text-heavy reports with tables. No `npm` or `pip` needed.

A `.docx` is a ZIP with these members:

| Entry | Content |
|---|---|
| `[Content_Types].xml` | MIME types (boilerplate) |
| `_rels/.rels` | Root relationship → `word/document.xml` |
| `word/document.xml` | **The document body** |
| `word/_rels/document.xml.rels` | Document relationships (often empty) |

**Minimal boilerplate XML files** — use exactly these:

`[Content_Types].xml`:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
```

`_rels/.rels`:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
```

#### XML Element Reference

Namespace: `xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"`

| Element | Purpose |
|---|---|
| `<w:p>` | Paragraph. Contains `<w:pPr>` + `<w:r>` runs |
| `<w:pPr>` | Paragraph properties: `<w:jc>`, `<w:spacing>`, `<w:ind>` |
| `<w:r>` | Run (identically-formatted span). Contains `<w:rPr>` + `<w:t>` |
| `<w:rPr>` | Run properties: `<w:b/>`, `<w:sz w:val="24"/>`, `<w:color>`, `<w:rFonts>` |
| `<w:t xml:space="preserve">` | Text content. ALWAYS set `xml:space="preserve"` |
| `<w:tbl>` | Table: `<w:tblPr>` + `<w:tblGrid>` + `<w:tr>` rows |
| `<w:tr>` | Table row: `<w:tc>` cells |
| `<w:tc>` | Table cell: `<w:tcPr>` (width) + `<w:p>` |
| `<w:pStyle w:val="Heading1"/>` | Built-in heading style (1–9) |
| `<w:br w:type="page"/>` | Page break (inside a `<w:r>`) |
| `<w:sectPr>` | Section properties: `<w:pgSz>`, `<w:pgMar>` |

**Font sizes are in half-points**: sz=24 = 12pt, sz=32 = 16pt, sz=44 = 22pt.

**Line spacing**:
- `w:line="360" w:lineRule="auto"` = 1.5× (360/240)
- `w:line="560" w:lineRule="exact"` = fixed 28pt (560/20)

**Page margins in twips** (1440 twips = 1 inch = 25.4mm):
```
mm_to_twips = mm * 1440 / 25.4
```

#### Text Escaping

ALWAYS escape: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&apos;`.

#### Building with Helper Functions

Compose the document as a list of XML strings:

```python
def escape(text):
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;').replace("'", '&apos;')

def run(text, bold=False, sz=24, color=None, font_east='仿宋', font_ascii='Times New Roman'):
    rpr = ['<w:rPr>']
    if bold: rpr.append('<w:b/><w:bCs/>')
    rpr.append(f'<w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/>')
    if color: rpr.append(f'<w:color w:val="{color}"/>')
    rpr.append(f'<w:rFonts w:eastAsia="{font_east}" w:ascii="{font_ascii}" w:hAnsi="{font_ascii}"/>')
    rpr.append('</w:rPr>')
    return f'<w:r>{"".join(rpr)}<w:t xml:space="preserve">{escape(text)}</w:t></w:r>'

D = []  # document as list of XML strings
D.append('<w:p>' + run('Title', bold=True, sz=44, font_east='黑体') + '</w:p>')
# ... add more paragraphs, tables, etc ...

# Assemble
doc_xml = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
    ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<w:body>' + ''.join(D) + '</w:body></w:document>')
```

#### Writing the ZIP

```python
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', ct_xml)
    z.writestr('_rels/.rels', rels_xml)
    z.writestr('word/document.xml', doc_xml)
    z.writestr('word/_rels/document.xml.rels', doc_rels_xml)
```

#### CRITICAL Rules for Raw XML

- **ALWAYS** escape text content (`& < > " '`)
- **ALWAYS** set `xml:space="preserve"` on `<w:t>` elements
- **ALWAYS** set both `w:eastAsia` AND `w:ascii`/`w:hAnsi` on `<w:rFonts>`
- **NEVER** use `\n` — create separate `<w:p>` elements
- **NEVER** nest `<w:r>` inside another `<w:r>`
- **Page breaks** must be inside a `<w:r>`: `<w:r><w:br w:type="page"/></w:r>`
- **Tables need both** `<w:tblGrid>` column widths AND `<w:tcPr><w:tcW>` on each cell
- **Font sizes** are in half-points (sz=24 = 12pt; sz=32 = 16pt)
- **Line spacing** for `exact` mode is in twips (1pt = 20 twips)
- Put `<w:sectPr>` AFTER `<w:body>` content, not inside it

### Mode B: docx-js Approach

For complex documents needing images, headers/footers, TOC, tracked changes, or
multi-column layouts, use `docx-js` (Node.js):

```bash
npm install -g docx
```

Key patterns from the Anthropic docx skill:

```javascript
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType, LevelFormat,
        TableOfContents, HeadingLevel, BorderStyle, WidthType,
        ShadingType, PageNumber, PageBreak } = require('docx');

// CRITICAL: Always set page size explicitly
const doc = new Document({
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },  // A4 in DXA
        margin: { top: 2098, bottom: 1984, left: 1587, right: 1474 }
      }
    },
    children: [/* content */]
  }]
});

Packer.toBuffer(doc).then(buf => require('fs').writeFileSync('out.docx', buf));
```

**CRITICAL docx-js rules** (from Anthropic):
- Never use unicode bullets — use `LevelFormat.BULLET` with numbering config
- `PageBreak` must be inside a `Paragraph`
- `ImageRun` requires `type` parameter
- Tables need dual widths: `columnWidths` array AND cell `width`
- Use `ShadingType.CLEAR`, never `SOLID`
- Use `WidthType.DXA`, never `PERCENTAGE` (breaks in Google Docs)
- Override built-in heading styles with exact IDs: `"Heading1"`, `"Heading2"`

See the [Anthropic docx skill](https://github.com/anthropics/skills/blob/main/skills/docx/SKILL.md) for full details.

## Editing Existing Documents

See [editing.md](editing.md) for the full unpack→edit→repack workflow,
tracked changes patterns, and common pitfalls when modifying existing .docx files.

## GB/T 9704-2012 Standard

For Chinese SOE or government reports, follow 《党政机关公文格式》:

### Page Setup

A4 (210mm×297mm), margins in twips:

| Edge | mm | twips |
|---|---|---|
| Top | 37 | 2098 |
| Bottom | 35 | 1984 |
| Left | 28 | 1587 |
| Right | 26 | 1474 |

```xml
<w:pgMar w:top="2098" w:bottom="1984" w:left="1587" w:right="1474"/>
```

### Font Hierarchy

| Element | Font | Size | sz= | Bold |
|---|---|---|---|---|
| 主标题 | 方正小标宋简体 (fallback: 黑体) | 二号 22pt | 44 | No |
| 一级标题 "一、" | 黑体 | 三号 16pt | 32 | Yes |
| 二级标题 "（一）" | 楷体 | 三号 16pt | 32 | Yes |
| 三级标题 "1." | 仿宋 | 三号 16pt | 32 | Yes |
| 正文 | 仿宋 | 三号 16pt | 32 | No |
| 表格文字 | 仿宋 | 小四 12pt | 24 | No |

### Layout

- **Line spacing**: fixed 28pt — `w:line="560" w:lineRule="exact"`
- **First-line indent**: 2 characters — `w:ind w:firstLineChars="200"`
- **Numbering hierarchy**: 一、→（一）→ 1. →（1）→ ①
- **Each level restarts** its child numbering independently
- Headings are NOT indented; only body text gets first-line indent
- Latin font pairing: `Times New Roman` for 仿宋/楷体, `Arial` for 黑体

### Sub-items in Body

For enumerated points within body text (not headings), use plain body paragraphs
(仿宋, 2-char indent) without numbering. The heading structure alone provides
the hierarchy. This is more readable in Office than excessive numbering:

```
一、项目总体概况              ← H1 黑体
  通过结题验收65项...        ← 正文段落（仿宋，缩进，无编号）
  完成技术评审31项...
```

## Common Pitfalls

| Issue | Fix |
|---|---|
| Chinese text rendering wrong | Set `w:eastAsia` AND `w:ascii`/`w:hAnsi` on `<w:rFonts>` |
| Fixed line spacing too tight for Chinese | Use 28pt (560 twips) minimum for 三号 16pt text |
| Table cells missing borders | Set all four borders explicitly on each cell |
| Page break doesn't work | Must be `<w:r><w:br w:type="page"/></w:r>`, not standalone |
| Text cut off | Ensure `xml:space="preserve"` on `<w:t>` |
| Missing content after edit | Rebuild the edit tool anchor from a fresh `read` |
| Font not available on NixOS | Use 黑体/楷体/仿宋 — these are universally available |

## Validation

After generating, verify the output:

```bash
# Quick content check
python3 -c "
import zipfile
with zipfile.ZipFile('output.docx') as z:
    with z.open('word/document.xml') as f:
        content = f.read().decode()
        # Check for common issues
        assert '&amp;' not in content.replace('&amp;amp;', ''), 'double-escaped'
        print(f'OK: {len(content)} bytes')
"
```

## Reference Implementation

See `test/generate_report.py` for a complete working example: loads data from
a source docx, performs analysis, and generates a GB/T 9704-compliant report
with headings, body text, tables, and proper Chinese formatting.
