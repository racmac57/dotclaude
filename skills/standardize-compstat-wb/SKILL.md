---
name: standardize-compstat-wb
description: Phase 3 showpiece — redesign one legacy Compstat workbook from sheet-per-month + _mom pivot into macro-free .xlsx on canonical Date|Unit|MetricGroup|Metric|Value schema. Wires pReportMonth, rewrites M code (S2/S3/S4), audits macros. Per-workbook.
---

# /standardize-compstat-wb

End-to-end redesign recipe for a single legacy Compstat workbook. Repeated 14 times across the workbook inventory. This is the highest-leverage skill in the project — it enforces the canonical schema, kills the `_mom` pivot, re-parameterizes M code on `pReportMonth`, and ships a macro-free `.xlsx`.

## When to trigger

- Phase 2/3 per-workbook redesign session
- User names a legacy workbook: "standardize csb_monthly", "redesign patrol_monthly", etc.
- After `/inventory-wave` has produced the wave inventory Markdown and the workbook's current structure is documented

## Inputs

- **Required:** path to legacy workbook in `01_Legacy_Copies/` (e.g., `01_Legacy_Copies/patrol_monthly.xlsm`)
- **Required:** target output path (e.g., `02_Redesigned/patrol_monthly_flat.xlsx`)
- **Required:** the wave inventory Markdown for this workbook (found in `Docs/wave_<letter>_inventory.md`)
- **Auto-detected:** unit name from filename; whether workbook is part of Community Outreach cluster

## Hard rules (Workbook_Redesign_2026)

Authoritative product rules for paths, legacy read-only behavior, and Power BI integration live in **`Claude.md`** at the Workbook_Redesign_2026 repository root, not in other projects’ AI rule files.

1. **Read-only on `01_Legacy_Copies/`** — never open the source file with write intent. Read with `openpyxl` read-only or `pd.read_excel`.
2. **No Python for Excel structural writes** — the new `.xlsx` is produced by Excel GUI or by XML surgery on the `.xlsx` parts (zipfile manipulation of `xl/worksheets/*.xml`, `xl/tables/*.xml`). Never use `openpyxl.save()` or `pandas.to_excel()` for the structural rewrite. This skill **prepares the content plan** and **generates the M code**; the user applies the structural change in Excel or this skill emits a zipfile-based writer only if the user explicitly opts in.
3. **Macro-free output** — target is `.xlsx`, not `.xlsm`. Document each legacy macro behavior and map it to Power Query or DAX.
4. **`pReportMonth` parameter** — no hardcoded month-year column names. Every time-filter is derived from `pReportMonth`.

## Repository context

Paths such as `01_Legacy_Copies/`, `02_Legacy_M_Code/`, `Docs/`, and `02_Redesigned/` resolve from the **Workbook_Redesign_2026** repository root (a sibling to other OneDrive folders such as `00_dev` / `ai_enhancement`), not from `ai_enhancement` alone. Use `$CLAUDE_PROJECT_DIR` when that repo is the active workspace. If it is not open, ask the user for the Workbook tree root or explicit paths before reading legacy workbooks or writing `Docs/redesign_<unit>.md`.

`standardize_m_code.py` lives in that tree — run it per Step 7 only after `cd` (or terminal cwd) is set to that repo root.

## Steps

### 1. Read the wave inventory for this workbook
Open `Docs/wave_<letter>_inventory.md` and locate the per-workbook section. Extract:
- Current sheet list
- Monthly sheet schema (pivoted columns, tracked metrics)
- `_mom` sheet structure
- Aux tables (Categories, Raw_Input, etc.)
- Named ranges, external connections
- Legacy macros (if `.xlsm`)

### 2. Catalog the metrics
For each unit, produce the metric catalog:

| MetricGroup | Metric | Source (legacy location) | Dtype |
|---|---|---|---|
| e.g., "Patrol Activity" | "Traffic Stops" | `25_NOV!B5:AF5` | count (int) |
| e.g., "Patrol Activity" | "Arrests" | `25_NOV!B6:AF6` | count (int) |
| ... | ... | ... | ... |

### 3. Produce the flat-table content plan
Transform the pivoted legacy data into a preview of the flat schema:

```python
# Read-only — for preview and row-count sanity ONLY. Do not write.
import pandas as pd
legacy = pd.read_excel(src, sheet_name=None, dtype=str)
# Melt each monthly sheet (e.g., 25_NOV) into long form:
#   - Row header (A column) = Metric
#   - Col headers (B..AF) = day-of-month '01'..'31' (watch inconsistent padding!)
#   - Values = counts
# Target: Date | Unit | MetricGroup | Metric | Value
```

Preview the first 100 rows in the diff report. **Do not save.**

### 4. Community Outreach cluster check
If this workbook is one of {Patrol, CSB, Community Engagement, STACP}, the flat-table schema **must be identical** to the canonical Community Outreach schema so Power Query can append. Cross-check columns, column order, Unit labels, and MetricGroup labels against the canonical list kept in `Docs/community_outreach_schema.md` (create this doc the first time if it doesn't exist). Flag any divergence.

### 5. Data validation rules
Propose the validation ruleset in Markdown for the user to apply in Excel:

- Column `Date` → Date type, range `>= 2023-01-01` and `<= TODAY()`, format `yyyy-mm-dd`.
- Column `Unit` → List (Stop error alert), source = named range `lst_Unit`.
- Column `MetricGroup` → List, source = `lst_MetricGroup_<unit>`.
- Column `Metric` → List, source = dependent-list formula `INDIRECT("lst_Metric_" & B2)` keyed off MetricGroup.
- Column `Value` → Number, `>= 0`, Stop error alert.

### 6. Summons bypass (Patrol only)
If this workbook is `patrol_monthly.xlsm`, the Summons table is **removed** from the redesign. Power BI handles Summons via DAX join against `summons_slim_for_powerbi.csv`. Explicitly document in the redesign plan that no Summons sheet exists in the new `.xlsx`. Cross-reference `/clean-summons-export`.

### 7. Rewrite the M code
For the matching `.m` files in `02_Legacy_M_Code/<unit>/`:

- Replace hardcoded month-year column names (`"01-25"`, `"02-25"`, etc.) with `pReportMonth`-driven filtering.
- Apply S2 (totals filter) → S3 (dedupe on primary key) → S4 (Value=1 shim where unpivoting is count-only).
- Remove the `_mom` source entirely; new M reads the flat `.xlsx` table directly.
- Delete the unpivot step (was only needed because the legacy data was pivoted).

Run the existing helper after edits:
```bash
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file <unit>.m
# review diff, then:
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file <unit>.m --apply
```
(See `/standardize-m-code` for the wrapper.)

### 8. Macro audit (if legacy is `.xlsm`)
List every VBA macro in the legacy workbook with a proposed disposition:

| Macro | Purpose | Disposition |
|---|---|---|
| e.g., `RefreshMoM` | Recalculate `_mom` XLOOKUPs | **Abandoned** — flat table + Power Query refresh replaces this |
| e.g., `ArchiveMonth` | Copy month to archive sheet | **Reimplemented in Power Query** as `fnArchive` |
| e.g., `SendEmail` | Monthly email notification | **Out of scope** — move to Power Automate or keep as separate .xlsm |

### 9. Emit the redesign plan document
Write a Markdown doc per workbook to `Docs/redesign_<unit>.md` with:
- Metric catalog (step 2)
- Flat-table content preview (step 3)
- Validation rules (step 5)
- M-code diff summary (step 7)
- Macro audit (step 8)
- Checklist of human actions needed in Excel (create the new `.xlsx`, set up the Table, paste the validation rules, wire the PQ parameter).

### 10. Do NOT produce the new `.xlsx` from Python (default mode)
The plan document from step 9 is what the user acts on — they create the `.xlsx` structure in Excel GUI. This skill does not call `openpyxl.save` (Hard Rule 2).

**Opt-in exception:** if the user explicitly asks for "XML surgery" output, generate the new workbook via a zipfile-based writer that assembles `[Content_Types].xml`, `xl/workbook.xml`, `xl/worksheets/sheet1.xml`, `xl/tables/table1.xml`, and a PQ parameter definition in `xl/connections.xml`. This is Phase-3-explicit territory — ask for confirmation before taking this path.

## Outputs

1. `Docs/redesign_<unit>.md` — the full redesign plan
2. Updated `.m` files in `02_Legacy_M_Code/<unit>/` (dry-run preview by default, `--apply` to write)
3. (Opt-in) New `.xlsx` in user-specified location via XML surgery

## Related skills
- Upstream: `/inventory-wave` (produces the wave inventory this skill reads)
- Used during: `/apply-s2-s3-s4`, `/standardize-m-code`, `/clean-summons-export` (for the Patrol DAX bypass)
- Downstream: Power BI model refresh to pick up the new flat source

## Canonical schema reference (do not drift)

```
Date        — date, no time component
Unit        — string (from project list)
MetricGroup — string (category)
Metric      — string (leaf)
Value       — numeric (count or measured value; 1 for S4 shim)
```

Any deviation breaks Power Query append across the Community Outreach cluster.
