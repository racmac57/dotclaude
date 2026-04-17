---
name: clean-arrest-export
description: LawSoft arrest-export cleanup for Workbook_Redesign_2026 — S2 totals filter, string dtype, strip whitespace on Charge/Race, normalize Reviewed casing, split Race/UCR codes, drop artifact cols, handle ATS 4-row header skip + footer trim.
---

# /clean-arrest-export

Canonical cleanup for LawSoft arrest exports (and ATS arrest exports, which use a different header structure). The raw files leak internal LawSoft report fields as columns, carry 14–18% trailing whitespace on key groupby fields, and have case-inconsistent reviewer names that break "per-reviewer" aggregations.

## When to trigger

- `/preflight-export` flagged an arrest file
- User says "clean the arrest export", "normalize arrest data", "fix ATS header"
- Before Phase 1 arrest-workbook inventory or Phase 2 redesign

## Inputs

- **Default:** latest `*LawSoft*Arrest*.xlsx` in `Data_Ingest/CAD_RMS_Exports/`
- **Detect ATS variant** by filename match `*ATS*.xlsx` → apply 4-row header skip + footer trim
- **Optional:** explicit path

## Transformations (apply in order)

### 1. Load with correct header offset
```python
if "ATS" in src.name:
    df = pd.read_excel(src, skiprows=4, dtype={"ReportNumberNew": str})
else:
    df = pd.read_excel(src, dtype={"ReportNumberNew": str})
```

### 2. ATS footer trim
ATS exports have a 1–3-row footer (totals / export timestamp). Drop from the bottom until the last row has a non-null `ReportNumberNew`:
```python
while df.iloc[-1]["ReportNumberNew"] in (None, "", "nan") or pd.isna(df.iloc[-1]["ReportNumberNew"]):
    df = df.iloc[:-1]
```

### 3. S2 totals filter
Drop rows where any key column contains "Total":
```python
totals_mask = df.apply(
    lambda r: r.astype(str).str.contains("Total", case=False, na=False).any(),
    axis=1,
)
df = df.loc[~totals_mask]
```
Report the row count dropped.

### 4. ReportNumberNew cleanup
```python
df["ReportNumberNew"] = (
    df["ReportNumberNew"]
    .astype(str)
    .str.replace(r"\n", "", regex=True)
    .str.strip()
)
```

### 5. Trailing-whitespace strip on key groupby fields
`Charge`, `Race`, `Address`, `Place of Arrest Street`, `Place of Arrest City` — all known to have trailing spaces in 14–18% of rows. These silently break groupby.
```python
for col in ["Charge", "Race", "Address", "Place of Arrest Street", "Place of Arrest City"]:
    if col in df.columns:
        df[col] = df[col].astype(str).str.strip()
```

### 6. Split `Race` compound codes
Values like `"1B     White Non Hisp.   "` are code + description + irregular spacing. Split into two columns:
```python
race_split = df["Race"].str.extract(r"^(\S+)\s+(.+?)\s*$")
df["Race_Code"] = race_split[0]
df["Race_Description"] = race_split[1].str.strip()
# Retain original Race column for legacy compatibility; downstream can drop
```

### 7. Normalize `Reviewed` reviewer casing
Same reviewer appears as `briggs_S`, `briggs_s`, `BRIGGS_S`. Canonicalize to uppercase_lastname format:
```python
def normalize_reviewer(v):
    if pd.isna(v) or not v:
        return None
    s = str(v).strip()
    # Split on underscore, uppercase the last name, lowercase the initial
    parts = s.split("_")
    if len(parts) == 2:
        return f"{parts[0].upper()}_{parts[1].upper()}"
    return s.upper()
df["Reviewed"] = df["Reviewed"].apply(normalize_reviewer)
```

### 8. Split `UCR #` compound field
`"260  All Other Offenses"` → `UCR_Code=260`, `UCR_Description="All Other Offenses"`:
```python
ucr_split = df["UCR #"].astype(str).str.extract(r"^(\d+)\s+(.+?)\s*$")
df["UCR_Code"] = ucr_split[0]
df["UCR_Description"] = ucr_split[1].str.strip()
```

### 9. Drop artifact columns
LawSoft report internals that leak into row data:
- `blank` (100% null)
- `ReportCalcSummary` (same value every row)
```python
df = df.drop(columns=[c for c in ["blank", "ReportCalcSummary"] if c in df.columns])
```

### 10. Coerce nullable ints
`Place of Arrest StNumber` loads as float64 due to nulls. Convert to pandas nullable Int:
```python
if "Place of Arrest StNumber" in df.columns:
    df["Place of Arrest StNumber"] = (
        df["Place of Arrest StNumber"].astype("Int64")
    )
```

### 11. PII warning (don't strip — just flag)
`SS#Calc` column carries PII. Do NOT silently drop; flag in the diff report and ask the user whether to retain, hash, or null out.

## Outputs

1. **Cleaned file** → `Data_Ingest/CAD_RMS_Exports/_cleaned/<original_basename>__cleaned.xlsx`
2. **Diff report (Markdown to stdout):**
   ```
   # Arrest Cleanup Report — 2026_03_LawSoft_Arrest.xlsx
   - Input rows: 56 | Output rows: 55 (1 totals row dropped by S2)
   - Trailing whitespace strips: Charge=10, Race=8, Address=4
   - Race compound-code splits: 56 → (Race_Code, Race_Description)
   - Reviewer casing normalizations: briggs_S/briggs_s/BRIGGS_S → BRIGGS_S (8 rows)
   - UCR # splits: 56 → (UCR_Code, UCR_Description)
   - Artifact columns dropped: blank, ReportCalcSummary
   - Place of Arrest StNumber coerced to Int64
   - ⚠  PII: SS#Calc column retained (11 populated / 45 null) — confirm handling with user
   - Output: Data_Ingest/CAD_RMS_Exports/_cleaned/2026_03_LawSoft_Arrest__cleaned.xlsx
   ```

## Repository context

This skill targets the `Workbook_Redesign_2026` repository layout. Before running transforms, confirm these paths exist relative to the active repo root:

- `Data_Ingest/CAD_RMS_Exports/` (raw inputs)
- `Data_Ingest/CAD_RMS_Exports/_cleaned/` (output target, create if missing)
- `01_Legacy_Copies/` (must remain untouched)

## Hard rules

- Read-only on original. Never overwrite source. Cleaned file goes in `_cleaned/`.
- Never write to `01_Legacy_Copies/`.
- PII handling: never paste raw `SS#Calc` values into chat, logs, or commit messages.
- Case numbers must be string dtype on load.

## Known gotchas (codified)

- LawSoft exports leak `blank` column (100% null) and `ReportCalcSummary` column (constant value).
- ATS has 4-row title header + 1–3-row footer.
- `Race` code-description concatenation with irregular spacing (codes like `1B`, `1C`, `2B`).
- `Reviewed` field has 3+ casing variants per reviewer.
- `JuvenileFlag` is 98% null — convert to boolean (null → False) if the downstream model needs it.
- `UCR #` is always code + description jammed together.

## Failure modes

If any of these occur, stop and return a clear error instead of guessing:

1. Input file not found or unreadable (`.xlsx` open failure).
2. Required column missing: `ReportNumberNew`, `Race`, `Reviewed`, or `UCR #`.
3. ATS file detected but 4-row header skip still yields malformed columns.
4. `_cleaned/` output path cannot be created or written.

## Related skills
- Upstream: `/preflight-export`
- Sibling: `/clean-cad-export`, `/clean-summons-export`
- Downstream: `/apply-s2-s3-s4` (for flat-table unpivot), `/standardize-compstat-wb`
