---
name: xlsx-processing
description: >
  Use whenever a spreadsheet file is the primary input or output — creating,
  reading, editing, or fixing .xlsx/.xlsm/.csv/.tsv files. Trigger when the
  user mentions 'Excel', 'spreadsheet', '.xlsx', asks for data analysis with
  tabular output, wants formulas/computed columns, charting, or cleaning messy
  tabular data. Also trigger for converting between tabular formats. Do NOT
  trigger for Word documents, HTML reports, or Google Sheets API work.
---

# XLSX Creation, Editing, and Analysis

## Quick Reference

| Task | Approach |
|---|---|
| Read/analyze data | `pandas` — `pd.read_excel()`, `df.describe()` |
| Create new with formulas & formatting | `openpyxl` — `Workbook()`, styles, `sheet['A1'] = '=SUM(...)'` |
| Edit existing (preserve formulas) | `openpyxl` — `load_workbook()`, modify, save |
| Recalculate formulas after editing | `python scripts/recalc.py output.xlsx` |
| Quick CSV/TSV conversion | `pandas` — `pd.read_csv()` → `df.to_excel()` |
| Data cleaning | `pandas` — `dropna()`, `astype()`, vectorized ops |

**CRITICAL: Use Excel formulas, not hardcoded values.** Calculate in the spreadsheet, not in Python.

```python
# WRONG — hardcoding computed values
sheet['B10'] = 5000

# RIGHT — let Excel compute
sheet['B10'] = '=SUM(B2:B9)'
```

## Reading and Analyzing Data

```python
import pandas as pd

df = pd.read_excel('file.xlsx')              # First sheet
all_sheets = pd.read_excel('file.xlsx', sheet_name=None)  # All sheets
df = pd.read_csv('file.csv')                  # CSV
df = pd.read_csv('file.tsv', sep='\t')        # TSV

df.head()      # Preview
df.info()      # Column types, nulls
df.describe()  # Statistics
```

## Creating New Excel Files

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

wb = Workbook()
sheet = wb.active

# Data
sheet['A1'] = '季度'
sheet['B1'] = '营收（万元）'
sheet.append(['Q1', 1200])
sheet.append(['Q2', 1450])

# Formula
sheet['B5'] = '=SUM(B2:B4)'
sheet['B6'] = '=AVERAGE(B2:B4)'

# Formatting
header_font = Font(name='微软雅黑', bold=True, size=11)
header_fill = PatternFill('solid', fgColor='D5E8F0')
thin_border = Border(
    left=Side(style='thin'), right=Side(style='thin'),
    top=Side(style='thin'), bottom=Side(style='thin'))

for cell in sheet[1]:
    cell.font = header_font
    cell.fill = header_fill
    cell.border = thin_border
    cell.alignment = Alignment(horizontal='center')

sheet.column_dimensions['A'].width = 12
sheet.column_dimensions['B'].width = 18

wb.save('output.xlsx')
```

## Editing Existing Files

```python
from openpyxl import load_workbook

wb = load_workbook('existing.xlsx')
sheet = wb.active  # or wb['SheetName']

# Modify
sheet['A1'] = 'New Value'
sheet.insert_rows(3)   # Insert row at position 3
sheet.delete_cols(2)   # Delete column 2

# Add sheet
ws = wb.create_sheet('汇总')
ws['A1'] = '=Sheet1!B5'  # Cross-sheet reference

wb.save('modified.xlsx')
```

**Warning**: `load_workbook('file.xlsx', data_only=True)` reads cached values but
if saved, formulas are permanently replaced with values. Use only for reading.

## Recalculating Formulas

Files created by openpyxl contain formula strings but not calculated values.
Recalculate with LibreOffice:

```bash
python scripts/recalc.py output.xlsx [timeout_seconds]
```

The script scans all cells for errors (`#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?`)
and returns JSON with error locations.

## Formula Construction Rules

### Always Use Cell References

```python
# WRONG — hardcoded
sheet['C5'] = 0.15

# RIGHT — formula referencing assumption cell
sheet['B2'] = 0.15          # Assumption: growth rate
sheet['C5'] = '=C4*(1+$B$2)'  # Formula using it
```

### Assumptions Placement
- Place ALL assumptions (rates, margins, multiples) in dedicated cells
- Reference them with absolute references (`$B$2`) in formulas
- Document sources for hardcoded values in adjacent cells

### Zero Formula Errors
Every model MUST deliver zero errors. Test with edge cases:
- Zero values, negative numbers, very large values
- Check denominators before division: `=IF(B2=0,0,A1/B2)`

## Number Formatting

```python
from openpyxl.styles import numbers

sheet['B2'].number_format = '#,##0'        # 1,234
sheet['B3'].number_format = '#,##0.00'     # 1,234.56
sheet['B4'].number_format = '0.0%'         # 12.3%
sheet['B5'].number_format = '$#,##0;($#,##0);-'  # Currency, negatives in parens, zero as dash
```

**Currency**: Always specify units in headers ("营收（万元）"), not in each cell.

## Best Practices

### Library Selection
- **pandas**: Data analysis, bulk operations, CSV conversion
- **openpyxl**: Formulas, formatting, Excel-specific features

### openpyxl Tips
- Cell indices are 1-based: `sheet.cell(row=1, column=1)` = A1
- For large files: `load_workbook(..., read_only=True)` or `write_only=True`
- Formulas are preserved but not evaluated until opened in Excel or recalculated
- Use `sheet.max_row` / `sheet.max_column` to find data bounds

### pandas Tips
- Specify dtypes: `pd.read_excel('file.xlsx', dtype={'id': str})`
- Read specific columns: `pd.read_excel('file.xlsx', usecols=['A', 'C'])`
- Handle dates: `pd.read_excel('file.xlsx', parse_dates=['date'])`

## Common Pitfalls

| Issue | Fix |
|---|---|
| Formulas show as text, not computed | Run `scripts/recalc.py` after saving |
| `#REF!` errors | Verify cell references; check for deleted rows/columns |
| `#DIV/0!` errors | Guard with `IF(denominator=0, 0, numerator/denominator)` |
| `#VALUE!` errors | Check data types in formula arguments |
| `#NAME?` errors | Check formula function spelling; use English function names |
| Data lost on save with `data_only=True` | Never save after loading with `data_only=True` |
| Column width too narrow | Set with `sheet.column_dimensions['A'].width = 15` |
| Years showing as "2,024" | Format as text: `sheet['A1'].number_format = '@'` |

## Financial Model Color Standards

When building financial models (optional, unless user requests):

| Element | Color |
|---|---|
| Hardcoded inputs | Blue text (RGB: 0,0,255) |
| Formulas | Black text (RGB: 0,0,0) |
| Cross-sheet links | Green text (RGB: 0,128,0) |
| External file links | Red text (RGB: 255,0,0) |
| Key assumptions | Yellow background (RGB: 255,255,0) |
