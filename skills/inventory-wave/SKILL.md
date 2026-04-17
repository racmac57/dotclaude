---
name: inventory-wave
description: Phase 1 wave inventory generator for Workbook_Redesign_2026. Given 3–4 legacy Compstat workbooks, produce Docs/wave_<letter>_inventory.md with sheet list, last-6-month schemas, _mom + aux tables, validation gaps, macro audit, flat-schema mapping.
---

# /inventory-wave

Phase 1 recipe. Produces the per-wave Markdown inventory that downstream skills (`/standardize-compstat-wb`, etc.) read. Enforces scope discipline — always last 6 monthly sheets + `_mom` + aux tables, never more. This is what keeps a Cowork session from exploding the context window.

## When to trigger

- User says: "inventory Wave A", "generate wave inventory", "review these workbooks for Phase 1"
- User drops 3–4 workbook paths (typically from `01_Legacy_Copies/`)
- Any Phase 1 per-wave session

## Inputs

- **Required:** list of 3–4 workbook paths
- **Required:** wave letter (A, B, C, D) — determines the output filename
- **Optional:** date cutoff (default: today; controls the 6-month active window)

If any required input is missing, **stop and ask** — do not guess workbook paths or wave letter. If `Docs/wave_<letter>_inventory.md` already exists, offer **update** vs **regenerate** before re-reading binaries.

## Hard rules (Workbook_Redesign_2026/CLAUDE.md)

These rules come from the **Workbook_Redesign_2026** project `CLAUDE.md` (Redesign-Specific Context), not from `ai_enhancement/CLAUDE.md` or SCRPA `CLAUDE.md`.

1. **Read-only on `01_Legacy_Copies/`**
2. **6-month focus.** Examine last 6 monthly sheets + `_mom` + aux tables. Do not expand scope.
3. **Reading is fine** — `pd.read_excel(..., sheet_name=None)` or `openpyxl` read-only.
4. **No Python writes to the workbooks.**

## Scope discipline

Derive the 6-month window deterministically:
- Today's date from CLAUDE.md context or `datetime.date.today()`.
- Active 6-month window = (today - 5 months) through today, inclusive.
- Example: today = 2026-04-16 → window = `25_NOV` through `26_APR`.
- Sheet-name conventions vary per workbook:
  - `chief_monthly` uses `25_NOV`, `26_01`, …
  - `csb_monthly` uses `_23_06`, `25_11`, `26_01`, …
  - `patrol_monthly` uses day-of-month columns inside month sheets
- Match flexibly (prefix-match on `YY_MM` or `YY_MMM`), then keep only the last 6 matches sorted chronologically.

## Steps

For each workbook in the wave:

### 1. Open read-only
```python
from openpyxl import load_workbook
wb = load_workbook(path, read_only=True, data_only=True)
```
Also `pd.read_excel(path, sheet_name=None, dtype=str)` for a first-pass schema.

### 2. Sheet inventory
List every sheet, flag which are:
- Monthly sheets (match `YY_MM`/`YY_MMM` pattern) — keep last 6 only per scope rule.
- `_mom` / `MoM` / `MonthOverMonth` variants — include one (the active one).
- Aux tables (`Categories`, `Raw_Input`, `AI_Context_Reference`, named lookup tables) — include up to 4.
- Year summary sheets (`<Unit>_Annual_Summary_Table`) — note but don't deep-inspect.
- Empty / placeholder 2026 shells — note count, don't inspect.

### 3. Per-monthly-sheet schema
For each of the last 6 monthly sheets:
- Column list (A, B, C, …)
- Row count (non-empty)
- Structure type: pivoted (day-of-month columns) vs. flat (row-per-event)
- Implicit dtypes
- Known inconsistencies (e.g., day headers padded `'01'` in some months, `'1'` in others)

### 4. `_mom` schema
- Wide pivot column list (typically `MM-YY` strings).
- Row count × column count.
- **Flag:** any hardcoded month-year headers → violates `pReportMonth` mandate.

### 5. Aux tables
For each aux table:
- Columns + dtypes
- Row count
- FK candidates (does this table lookup-bind to something in monthly sheets?)
- Null rate per column

### 6. Validation gaps (checklist)
Check and report:
- Day-of-month columns: is there data validation? (Numeric-only? Range check?)
- Metric label column: dropdown bound to a controlled list, or free text?
- Raw-input `Event` field: FK'd to a `Categories` table, or unbound?
- `Date` columns: format-locked (`mm/dd/yyyy`)?

### 7. Named ranges + external connections
- Named ranges: list each with its refers-to formula.
- External connections: any ODBC / Power Query refresh sources? Document the source.
- M code: cross-reference against `02_Legacy_M_Code/<unit>/*.m` — note which queries exist.

### 8. Macro audit (if `.xlsm`)
- List every VBA module and each public Sub/Function.
- One-line purpose per macro (best-effort from name + comments).
- Flag any macro that does structural things (sheet add/rename, table create) — these become macro-free in the redesign.

### 9. Proposed flat-schema mapping
For each metric currently tracked in this workbook, propose the mapping to canonical:

| Legacy Location | Proposed `MetricGroup` | Proposed `Metric` | Notes |
|---|---|---|---|
| `25_NOV!A5:AF5` (Traffic Stops row) | "Patrol Activity" | "Traffic Stops" | day-of-month columns → melt to Date |
| `_mom!B2:AR2` (rolling total) | — | — | **Drop — derivable from flat source** |

### 10. Community Outreach cluster flag
If the workbook is one of {Patrol, CSB, Community Engagement, STACP}, call out explicitly that it must land on the **unified Community Outreach schema** (see CLAUDE.md Redesign-Specific Context). Compare its current metrics to the canonical unified set.

### 11. Patrol-specific: Summons removal note
If the workbook is `patrol_monthly.xlsm`, surface a **REMOVED** section noting that Summons is not carried into the redesign (DAX-joined from `summons_slim_for_powerbi.csv` instead). List the Summons-related sheets/tables as "out of scope for redesign."

## Output

Single Markdown file: `Docs/wave_<letter>_inventory.md`

Structure:
```markdown
// 🕒 <ISO timestamp>
// # Workbook_Redesign_2026/Docs/wave_<letter>_inventory.md
// # Author: R. A. Carucci
// # Purpose: Phase 1 inventory of Wave <letter> workbooks (<list>) — columns, dtypes, validation gaps, macro audit, proposed flat-schema mapping.

# Wave <letter> Inventory — HPD Compstat Workbook Redesign

**Scope:** <workbook list>
**Date cutoff:** <today>. Active 6-month window = <YY_MMM> → <YY_MMM>.

---

## 1. File-by-File Breakdown

### 1.1 <workbook_filename>
(sections 2–11 per workbook)

### 1.2 <next workbook>
...

---

## 2. Cross-Workbook Observations

- Shared metric naming drift (e.g., "Traffic Stops" vs "Traffic Stop")
- Community Outreach cluster reconciliation (if this wave touches the cluster)
- Naming convention violations
- Macros that exist in multiple workbooks with similar purpose

---

## 3. Proposed Redesign Order

Rank the wave's workbooks by redesign complexity (simplest first). Flag any blockers (missing data, corrupt sheets, unresolved external connections).

---

## 4. Checklist for Phase 2

- [ ] Produce canonical metric catalog for each workbook
- [ ] Resolve naming drift across Community Outreach cluster (if applicable)
- [ ] Capture validation-rule catalog
- [ ] Decide macro dispositions (abandon / PQ / DAX / out-of-scope)
```

## Scope guardrails (DO NOT EXPAND)

- Do not inventory more than 6 monthly sheets per workbook.
- Do not open the full legacy `_mom` 44-column sheet — just schema + header row.
- Do not try to parse XLOOKUP formulas; just note their presence.
- Do not deep-inspect every annual summary or pre-created 2026 shell.
- Do not re-read workbooks if the inventory for this wave already exists (check `Docs/wave_<letter>_inventory.md` first — offer to update vs. regenerate).

## Repository context (shared files)

Workbook paths, `01_Legacy_Copies/`, `02_Legacy_M_Code/`, and `Docs/wave_<letter>_inventory.md` are relative to the **Workbook_Redesign_2026** repository root (sibling to other OneDrive projects such as `00_dev`), not to `ai_enhancement`. Resolve paths using the active project root (`$CLAUDE_PROJECT_DIR`) for that repo.

If Workbook_Redesign_2026 is not the open project, **ask the user** for the repo or workbook paths before inventorying.

## Related skills
- Upstream: `/preflight-export` (for Data_Ingest exports, not WBs)
- Downstream: `/standardize-compstat-wb` (per-WB redesign; reads this inventory)
- Sibling: `/apply-s2-s3-s4` (applied during Phase 2 per metric)
