---
name: apply-s2-s3-s4
description: Generic S2/S3/S4 applier for Workbook_Redesign_2026 — given a raw flat table + primary-key column, emit refactored DataFrame (S2 totals dropped, S3 deduped, S4 Value=1 shim) + equivalent Power Query M snippet. Use for any non-MVA unit in Phase 2.
---

# /apply-s2-s3-s4

Generic version of the refactor pattern that's hardcoded inside `mva_crash_etl.py` and `standardize_m_code.py`. Use when redesigning any non-MVA unit so the S2/S3/S4 sequence stays consistent across the 14-workbook estate.

## When to trigger

- User says "apply S2/S3/S4 to <unit>", "refactor this table", "prep for unpivot"
- During Phase 2 per-workbook redesign for any unit beyond MVA
- When generating M-code stubs for the new flat-table source

## Inputs

- **Required:** path to a raw flat file (CSV or Excel) OR a pandas DataFrame in scope
- **Required:** primary-key column name (e.g., `Control #`, `ReportNumberNew`, `IncidentID`)
- **Required:** totals-row identifier — typically the literal `"Total"` substring; user can override (e.g., `"GRAND TOTAL"`)
- **Optional:** column to scan for totals (default: scan ALL string columns; safer)
- **Optional:** Value-column behavior — `shim` (add Value=1, default for count-only events) or `existing` (a Value column already exists, do nothing)

## Apply order (matters)

Always **S2 → S3 → S4 → unpivot**. Order is non-negotiable:
- S2 before S3, because totals rows can have duplicate PKs and we want them dropped first.
- S3 before S4, because adding the shim column shouldn't influence dedup keys.
- S4 before unpivot, because unpivot needs Value to exist.

## Steps

### 1. Read the input
```python
if path.suffix == ".csv":
    df = pd.read_csv(path, dtype=str)
else:
    df = pd.read_excel(path, dtype=str)
```

### 2. S2 — Totals filter
```python
def _is_totals_row(row, totals_label="Total"):
    return row.astype(str).str.contains(totals_label, case=False, na=False).any()

before = len(df)
df = df.loc[~df.apply(_is_totals_row, axis=1)]
s2_dropped = before - len(df)
```

### 3. S3 — Dedupe on primary key
```python
before = len(df)
# Force PK to string before dedup (Excel float-coercion artifacts)
df[pk_col] = df[pk_col].astype(str).str.replace(r"\n", "", regex=True).str.strip()
df = df.drop_duplicates(subset=[pk_col], keep="first")
s3_dropped = before - len(df)
```

### 4. S4 — Value=1 shim
```python
if value_behavior == "shim":
    if "Value" in df.columns:
        # Existing Value column — coerce to numeric but don't overwrite
        df["Value"] = pd.to_numeric(df["Value"], errors="coerce")
    else:
        df["Value"] = 1
```

### 5. Emit the equivalent M-code snippet
Generate a Power Query M code block the user can paste into the redesigned `.m` file:

```m
let
    Source = Excel.Workbook(File.Contents(SourcePath), null, true),
    Raw = Source{[Item="<TableName>",Kind="Table"]}[Data],

    // S2 — Totals filter
    NoTotals = Table.SelectRows(
        Raw,
        each not Text.Contains(Text.From([<PK_COL>]), "Total", Comparer.OrdinalIgnoreCase)
    ),

    // S3 — Dedupe on primary key
    Deduped = Table.Distinct(NoTotals, {"<PK_COL>"}),

    // S4 — Value=1 shim (count-only events)
    WithValue = Table.AddColumn(Deduped, "Value", each 1, Int64.Type),

    // Caller's job: continue with Table.UnpivotOtherColumns or join
    Result = WithValue
in
    Result
```

Substitute `<TableName>` and `<PK_COL>` based on inputs.

### 6. Diff report (Markdown to stdout)

```
# Apply S2/S3/S4 — <input filename>

## Inputs
- File: <path>
- Primary key: <pk_col>
- Totals label: "<totals_label>"
- Value behavior: <shim|existing>

## Transformations
- S2 (totals): dropped <s2_dropped> rows
- S3 (dedupe on <pk_col>): dropped <s3_dropped> rows
- S4 (Value): added Value=1 (or coerced existing)

## Output
- Rows: <before> → <after>
- New columns: Value (if S4 shim added)
- Saved to: <_refactored.csv path>

## Equivalent M code
(snippet above, with substitutions applied)
```

### 7. Save refactored file (optional)
If the user asked for a written output, save to `<original_dir>/_refactored/<basename>__s2s3s4.csv`. Otherwise return the DataFrame in memory.

## Hard rules

- Never apply S2/S3/S4 to legacy `01_Legacy_Copies/` files in place — always read-only on those.
- Never apply S2 with a totals label so generic that it might match real metrics. "Total" is project-default; if the user has metrics like "Total Stops" the literal `"Total"` would over-match — surface this risk and ask.
- Default behavior assumes one PK column. For composite keys, accept a list and pass to `drop_duplicates(subset=[...])`.
- If the input has > 1M rows, warn before running — `apply(axis=1)` for S2 gets slow.

## Repository context (shared files)

The code references below live in the **Workbook_Redesign_2026** working tree (sibling to other OneDrive projects such as `00_dev`), not in `ai_enhancement`. When resolving paths, use the active project root (`$CLAUDE_PROJECT_DIR`) for that repo:

- `mva_crash_etl.py` — MVA pipeline (S2/S3/S4 inlined for crashes)
- `standardize_m_code.py` — bulk S2/S3/S4 on `.m` files (`/standardize-m-code`)
- `01_Legacy_Copies/` — **read-only** legacy exports; never write in place

If Workbook_Redesign_2026 is not the open project, ask the user for the folder or CSV path before applying transforms.

## Failure modes (agent must surface clearly)

| Situation | Behavior |
|-----------|----------|
| Input path does not exist | Stop; report `FileNotFoundError` with the path |
| `pk_col` not in columns | Stop; list available columns and ask for the correct primary key |
| Input reads empty (0 rows) after load | Warn; emit empty refactored frame if saving |
| Totals label would over-match real metrics (e.g. `"Total"` vs `"Total Stops"`) | Warn per Hard rules; confirm or narrow the label / column scan |

## Related skills
- Sibling: `/standardize-m-code` (applies S2/S3/S4 to existing `.m` files)
- Used by: `/standardize-compstat-wb`
- Generalizes: `mva_crash_etl.py` (which has S2/S3/S4 hardcoded for the MVA case)
