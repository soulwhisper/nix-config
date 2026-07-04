---
name: pptx-processing
description: >
  Use whenever a .pptx file is involved — creating slide decks, pitch decks,
  or presentations from scratch or templates; reading, parsing, or extracting
  text from any .pptx file; editing, modifying, or updating existing
  presentations; combining or splitting slide files. Trigger when the user
  mentions 'deck', 'slides', 'presentation', 'PowerPoint', or references a
  .pptx filename. Do NOT trigger for Word documents, spreadsheets, or PDFs.
---

# PPTX Creation, Editing, and Analysis

## Quick Reference

| Task | Guide |
|---|---|
| Read/analyze content | `python -m markitdown presentation.pptx` |
| Edit or create from template | Read [editing.md](editing.md) |
| Create from scratch | Read [pptxgenjs.md](pptxgenjs.md) |
| Visual overview (thumbnails) | `python scripts/thumbnail.py presentation.pptx` |

## Reading Content

```bash
# Text extraction
python -m markitdown presentation.pptx

# Visual overview (thumbnail grid)
python scripts/thumbnail.py presentation.pptx

# Raw XML access
python scripts/office/unpack.py presentation.pptx unpacked/
```


---

## Design Principles

**Don't create boring slides.** See [pptxgenjs.md](pptxgenjs.md) for API details.

### Before Starting

- **Pick a bold, content-informed palette** — one color should dominate (60-70% weight)
- **Dark/light contrast** — dark for title/conclusion, light for content
- **Commit to a visual motif** — repeat one element across slides

### Color Palettes

| Theme | Primary | Secondary | Accent |
|---|---|---|---|
| Midnight Executive | `1E2761` navy | `CADCFC` ice blue | `FFFFFF` white |
| Charcoal Minimal | `36454F` charcoal | `F2F2F2` off-white | `212121` black |
| Teal Trust | `028090` teal | `00A896` seafoam | `02C39A` mint |
| Cherry Bold | `990011` cherry | `FCF6F5` off-white | `2F3C7E` navy |

### Layout Options

- **Two-column**: text left, illustration right
- **Icon + text rows**: icon in colored circle, bold header, description
- **2×2 or 2×3 grid**: blocks with icons and short text
- **Large stat callouts**: 60-72pt numbers with small labels
- **Timeline/process flow**: numbered steps

### Common Mistakes

- Don't repeat the same layout — vary across slides
- Don't center body text — left-align paragraphs
- Don't create text-only slides — every slide needs a visual element
- **NEVER use accent lines under titles** — AI-generated hallmark

---

## QA (Required)

**Assume there are problems. Find them.**

```bash
# Content check
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|placeholder"

# Visual inspection
python scripts/office/soffice.py --headless --convert-to pdf output.pptx
pdftoppm -jpeg -r 150 output.pdf slide
```

**Use subagents** for visual QA — fresh eyes catch what you'll miss.

### Verification Loop
1. Generate → Convert → Inspect
2. List issues (if none, look more critically)
3. Fix → Re-verify affected slides
4. Repeat until clean pass

## Dependencies

```bash
pip install "markitdown[pptx]" Pillow
npm install -g pptxgenjs
```
LibreOffice + Poppler for PDF/image conversion.

