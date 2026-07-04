# PptxGenJS — Creating Presentations from Scratch

Use when no template or reference presentation exists.

## Setup

```bash
npm install -g pptxgenjs
```

```javascript
const pptxgen = require("pptxgenjs");
const pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';  // 10" × 5.625"
pres.author = 'Your Name';
pres.title = 'Presentation Title';
```

## Layout Dimensions (inches)

| Layout | Width | Height |
|---|---|---|
| `LAYOUT_16x9` (default) | 10.0 | 5.625 |
| `LAYOUT_16x10` | 10.0 | 6.25 |
| `LAYOUT_4x3` | 10.0 | 7.5 |
| `LAYOUT_WIDE` | 13.3 | 7.5 |

Custom: `pres.defineLayout({ name: "A4_LANDSCAPE", width: 11.69, height: 8.27 });`

## Text & Formatting

```javascript
// Basic text
slide.addText("Title Text", {
  x: 1, y: 1, w: 8, h: 2,
  fontSize: 36, fontFace: "Arial", color: "363636",
  bold: true, align: "center", valign: "middle"
});

// Rich text arrays (multiple runs)
slide.addText([
  { text: "Bold ", options: { bold: true } },
  { text: "Italic ", options: { italic: true, breakLine: true } },
  { text: "Normal text" }
], { x: 1, y: 3, w: 8, h: 1 });

// Multi-line text — requires breakLine: true
slide.addText([
  { text: "Line 1", options: { breakLine: true } },
  { text: "Line 2", options: { breakLine: true } },
  { text: "Line 3" }  // Last item doesn't need breakLine
], { x: 0.5, y: 0.5, w: 8, h: 2 });

// Text box margin — set to 0 when aligning with shapes/icons
slide.addText("Title", { x: 0.5, y: 0.3, w: 9, h: 0.6, margin: 0 });
```

**Tip**: Text boxes have internal margin by default. Set `margin: 0` when aligning text with shapes, lines, or icons at the same x-position.

## Lists & Bullets

```javascript
// CORRECT: Multiple bullets
slide.addText([
  { text: "First item", options: { bullet: true, breakLine: true } },
  { text: "Second item", options: { bullet: true, breakLine: true } },
  { text: "Third item", options: { bullet: true } }
], { x: 0.5, y: 0.5, w: 8, h: 3 });

// NEVER use unicode bullets — creates double bullets
// slide.addText("• First item", { ... });  // WRONG

// Sub-items and numbered lists
{ text: "Sub-item", options: { bullet: true, indentLevel: 1 } }
{ text: "First", options: { bullet: { type: "number" }, breakLine: true } }
```

## Shapes

```javascript
// Rectangle
slide.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 0.8, w: 1.5, h: 3.0,
  fill: { color: "FF0000" },
  line: { color: "000000", width: 2 }
});

// Circle
slide.addShape(pres.shapes.OVAL, {
  x: 4, y: 1, w: 2, h: 2,
  fill: { color: "0000FF" }
});

// Line
slide.addShape(pres.shapes.LINE, {
  x: 1, y: 3, w: 5, h: 0,
  line: { color: "FF0000", width: 3, dashType: "dash" }
});

// Rounded rectangle
slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x: 1, y: 1, w: 3, h: 2,
  fill: { color: "FFFFFF" }, rectRadius: 0.1
});

// With transparency
slide.addShape(pres.shapes.RECTANGLE, {
  x: 1, y: 1, w: 3, h: 2,
  fill: { color: "0088CC", transparency: 50 }
});

// With shadow
slide.addShape(pres.shapes.RECTANGLE, {
  x: 1, y: 1, w: 3, h: 2,
  fill: { color: "FFFFFF" },
  shadow: { type: "outer", color: "000000", blur: 6, offset: 2, angle: 135, opacity: 0.15 }
});
```

Shadow options: `type` ("outer"/"inner"), `color` (6-char hex, no `#`), `blur` (0-100), `offset` (must be ≥ 0), `angle` (0-359), `opacity` (0.0-1.0).

## Images

```javascript
// From file
slide.addImage({ path: "chart.png", x: 1, y: 1, w: 5, h: 3 });

// From URL
slide.addImage({ path: "https://example.com/image.jpg", x: 1, y: 1, w: 5, h: 3 });

// From base64
slide.addImage({ data: "image/png;base64,iVBORw0KGgo...", x: 1, y: 1, w: 5, h: 3 });

// Sizing modes
{ sizing: { type: 'contain', w: 4, h: 3 } }   // Fit inside, preserve ratio
{ sizing: { type: 'cover', w: 4, h: 3 } }      // Fill area, may crop
{ sizing: { type: 'crop', x: 0.5, y: 0.5, w: 2, h: 2 } }  // Crop portion

// Preserve aspect ratio
const maxHeight = 3.0;
const calcWidth = maxHeight * (origWidth / origHeight);
const centerX = (10 - calcWidth) / 2;
slide.addImage({ path: "img.png", x: centerX, y: 1.2, w: calcWidth, h: maxHeight });

// Options
{ rotate: 45, rounding: true, transparency: 50, flipH: true, altText: "Description" }
```

## Tables

```javascript
slide.addTable([
  ["Header 1", "Header 2"],
  ["Cell 1", "Cell 2"],
], {
  x: 1, y: 1, w: 8, h: 2,
  border: { pt: 1, color: "999999" },
  fill: { color: "F1F1F1" },
  colW: [4, 4]  // Column widths in inches
});

// With per-cell formatting
[
  [{ text: "Header", options: { fill: { color: "6699CC" }, color: "FFFFFF", bold: true } }, "Cell"],
  [{ text: "Merged", options: { colspan: 2 } }],
]
```

## Charts

```javascript
slide.addChart(pres.charts.BAR, [{
  name: "Sales", labels: ["Q1", "Q2", "Q3", "Q4"], values: [4500, 5500, 6200, 7100]
}], {
  x: 0.5, y: 0.6, w: 6, h: 3,
  barDir: 'col',           // 'col' = vertical bars, 'bar' = horizontal
  showTitle: true, title: "Quarterly Sales",
  catAxisLabelColor: "666666", valAxisLabelColor: "666666",
  plotArea: { fill: { color: "FFFFFF" } }
});

// Available chart types: BAR, LINE, PIE, DOUGHNUT, SCATTER, AREA, RADAR
```

## Slide Backgrounds

```javascript
slide.background = { color: "F1F1F1" };
slide.background = { color: "FF3399", transparency: 50 };
slide.background = { path: "https://example.com/bg.jpg" };
slide.background = { data: "image/png;base64,iVBORw0KGgo..." };
```

## Page Numbers

```javascript
slide.addText("Slide 1", {
  x: 0, y: 5.2, w: "100%", h: 0.4,
  align: "center", fontSize: 10, color: "999999"
});
```

## Write File

```javascript
pres.writeFile({ fileName: "output.pptx" })
  .then(() => console.log("Done"));
```

## Dependencies

```bash
npm install -g pptxgenjs
# For icons (optional):
npm install -g react-icons react react-dom sharp
```
