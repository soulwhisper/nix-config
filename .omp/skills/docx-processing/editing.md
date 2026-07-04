# Editing Existing .docx Documents

When you need to modify an existing `.docx` rather than create from scratch.

## Workflow

### 1. Read and Analyze

Always start by extracting text to understand the document structure:

```python
import zipfile, xml.etree.ElementTree as ET

with zipfile.ZipFile('document.docx') as z:
    with z.open('word/document.xml') as xml:
        tree = ET.parse(xml)
        ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        for p in tree.findall('.//w:p', ns):
            texts = [t.text or '' for t in p.findall('.//w:t', ns)]
            print(''.join(texts))
```

### 2. Edit XML Directly

For surgical edits, modify the XML inside the ZIP without full unpacking:

```python
import zipfile, os, shutil

src = 'document.docx'
dst = 'modified.docx'

# Read and modify in memory
with zipfile.ZipFile(src) as zin:
    content = zin.read('word/document.xml').decode()
    content = content.replace('old text', 'new text')

# Write new ZIP preserving other entries
with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        if item.filename == 'word/document.xml':
            zout.writestr(item, content.encode())
        else:
            zout.writestr(item, zin.read(item.filename))
```

### 3. Unpack → Edit → Repack (Full Workflow)

For complex edits involving multiple files:

```bash
# Unpack
python scripts/office/unpack.py document.docx unpacked/

# Edit files in unpacked/word/ (document.xml, styles.xml, etc.)

# Repack with validation
python scripts/office/pack.py unpacked/ output.docx --original document.docx
```

**Note**: These scripts are from the Anthropic skills repo. On NixOS without them,
use the Python approach above or manual ZIP manipulation.

## XML Editing Patterns

### Replacing Text in a Paragraph

Original:
```xml
<w:p>
  <w:r><w:rPr><w:b/></w:rPr><w:t>Old Title</w:t></w:r>
</w:p>
```

Modified:
```xml
<w:p>
  <w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">New Title</w:t></w:r>
</w:p>
```

**CRITICAL**: Copy the original `<w:rPr>` to preserve formatting (bold, font, size, color).

### Adding Tracked Changes

```xml
<!-- Deletion -->
<w:del w:id="1" w:author="Claude" w:date="2025-01-01T00:00:00Z">
  <w:r><w:rPr><!-- copy original rPr --></w:rPr><w:delText>old text</w:delText></w:r>
</w:del>

<!-- Insertion -->
<w:ins w:id="2" w:author="Claude" w:date="2025-01-01T00:00:00Z">
  <w:r><w:rPr><!-- copy original rPr --></w:rPr><w:t>new text</w:t></w:r>
</w:ins>
```

Tracked change elements are siblings of `<w:r>`, never nested inside them.

### Restoring Deleted Content

When rejecting another author's deletion:
```xml
<w:del w:author="Jane" w:id="5">
  <w:r><w:delText>deleted text</w:delText></w:r>
</w:del>
<w:ins w:author="Claude" w:id="10">
  <w:r><w:t>deleted text</w:t></w:r>
</w:ins>
```

### Deleting Entire Paragraphs

When removing ALL content from a paragraph, also mark the paragraph mark as deleted:
```xml
<w:p>
  <w:pPr>
    <w:rPr>
      <w:del w:id="1" w:author="Claude" w:date="..."/>
    </w:rPr>
  </w:pPr>
  <w:del w:id="2" w:author="Claude" w:date="...">
    <w:r><w:delText>Entire paragraph being removed...</w:delText></w:r>
  </w:del>
</w:p>
```

Without the `<w:del/>` in `<w:pPr><w:rPr>`, accepting changes leaves an empty paragraph.

## Common Pitfalls

| Issue | Fix |
|---|---|
| Formatting lost after text replacement | Copy original `<w:rPr>` into new `<w:r>` |
| Double-escaped entities | Don't escape already-escaped XML content |
| Whitespace collapsed | Add `xml:space="preserve"` to `<w:t>` |
| Smart quotes → ASCII | Use `&#x201C;` / `&#x201D;` entities |
| Tracked change elements nested in `<w:r>` | Put them as siblings of `<w:r>`, not inside |
| Empty paragraphs after accepting changes | Add `<w:del/>` in `<w:pPr><w:rPr>` for full deletions |
| `<w:rPr>` element order wrong | Order: `<w:rFonts>`, `<w:b>`, `<w:sz>`, `<w:color>` last |
