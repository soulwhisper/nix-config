# Editing Presentations — Template-Based Workflow

Use when adapting an existing `.pptx` template or making surgical edits.

## Workflow

### 1. Analyze Template

```bash
python scripts/thumbnail.py template.pptx
python -m markitdown template.pptx
```

Review the thumbnail grid to see layouts, and markitdown output to see placeholder text.

### 2. Plan Slide Mapping

For each content section, choose a template slide. **Use varied layouts** — don't
default to basic title+bullet slides. Seek out:

- Multi-column layouts (2-column, 3-column)
- Image + text combinations
- Quote or callout slides
- Section dividers
- Stat/number callouts
- Icon grids or icon + text rows

Match content type to layout style. Avoid repeating the same layout.

### 3. Unpack

```bash
python scripts/office/unpack.py template.pptx unpacked/
```

Extracts PPTX, pretty-prints XML, escapes smart quotes.

### 4. Structure (complete before editing content)

- Delete unwanted slides: remove `<p:sldId>` from `<p:sldIdLst>` in `ppt/presentation.xml`
- Duplicate slides: `python scripts/add_slide.py unpacked/ slide2.xml`
- Reorder slides: rearrange `<p:sldId>` elements
- Run `python scripts/clean.py unpacked/` to remove orphans

Slide order is in `ppt/presentation.xml` → `<p:sldIdLst>`.

### 5. Edit Content

Each slide is a separate `ppt/slides/slideN.xml` file. Use subagents for parallel editing.

**Formatting Rules:**

- **Bold all headers and subheadings**: use `b="1"` on `<a:rPr>`
- **Never use unicode bullets** (•): use `<a:buChar>` or `<a:buAutoNum>`
- **Bullet consistency**: let bullets inherit from layout; only specify when overriding
- **Multi-item content**: create separate `<a:p>` elements for each item — never concatenate

### 6. Clean and Pack

```bash
python scripts/clean.py unpacked/
python scripts/office/pack.py unpacked/ output.pptx --original template.pptx
```

## Slide XML Structure

```xml
<p:sld xmlns:p="..." xmlns:a="...">
  <p:cSld>
    <p:spTree>
      <p:sp>  <!-- shape (text box, image, chart) -->
        <p:nvSpPr>...</p:nvSpPr>
        <p:spPr>...</p:spPr>  <!-- position, size, fill -->
        <p:txBody>
          <a:bodyPr/>
          <a:p>  <!-- paragraph -->
            <a:r>  <!-- run -->
              <a:rPr lang="en-US" sz="2400" b="1"/>
              <a:t>Text content</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>
```

Positioning in EMUs (914400 EMU = 1 inch):
```xml
<a:xfrm>
  <a:off x="914400" y="1828800"/>      <!-- left, top -->
  <a:ext cx="8229600" cy="2743200"/>    <!-- width, height -->
</a:xfrm>
```

## Formatting

### Text Formatting

```xml
<!-- Bold header -->
<a:r><a:rPr lang="en-US" sz="2400" b="1"/><a:t>Section Title</a:t></a:r>

<!-- Normal body text -->
<a:r><a:rPr lang="en-US" sz="1800"/><a:t>Description text here.</a:t></a:r>

<!-- Smart quotes — always use XML entities -->
<a:t>the &#x201C;Agreement&#x201D;</a:t>
```

| Character | Entity |
|---|---|
| `"` (left double) | `&#x201C;` |
| `"` (right double) | `&#x201D;` |
| `'` (left single) | `&#x2018;` |
| `'` (right single) | `&#x2019;` |

### Bullets

```xml
<!-- Bullet character -->
<a:r><a:rPr lang="en-US" sz="1800">
  <a:buChar char="•"/>
</a:rPr><a:t>Bullet item</a:t></a:r>

<!-- Numbered -->
<a:r><a:rPr lang="en-US" sz="1800">
  <a:buAutoNum type="arabicPeriod"/>
</a:rPr><a:t>Numbered item</a:t></a:r>

<!-- No bullet -->
<a:r><a:rPr lang="en-US" sz="1800">
  <a:buNone/>
</a:rPr><a:t>Plain text</a:t></a:r>
```

### Whitespace

Add `xml:space="preserve"` to `<a:t>` elements with leading/trailing spaces.

## Common Pitfalls

| Issue | Fix |
|---|---|
| Template has more items than source | Delete entire shape groups, not just text |
| Text overflow after replacement | Shorten text or split across slides |
| Smart quotes converted to ASCII by Edit tool | Re-escape as `&#x201C;` etc. |
| Namespace corruption | Use `defusedxml.minidom`, not `xml.etree.ElementTree` |
| Orphaned media after slide deletion | Run `clean.py` |
| Bullets appear doubled | Use `<a:buChar>`, never type `•` in text |
| All items in one paragraph | Create separate `<a:p>` for each item |

## Scripts Reference

| Script | Purpose |
|---|---|
| `scripts/office/unpack.py` | Extract and pretty-print PPTX |
| `scripts/add_slide.py` | Duplicate slide or create from layout |
| `scripts/clean.py` | Remove orphaned files |
| `scripts/office/pack.py` | Repack with validation |
| `scripts/thumbnail.py` | Create visual grid of slides |

**Note**: These scripts are from the Anthropic skills repo. On NixOS, install equivalents:
- `python -m markitdown presentation.pptx` for text extraction
- LibreOffice + `pdftoppm` for visual inspection
- Manual XML editing with `edit` tool for content changes
