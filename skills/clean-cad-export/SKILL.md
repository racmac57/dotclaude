---
name: clean-cad-export
description: CAD-export cleanup for Workbook_Redesign_2026 — strip \n from ReportNumberNew, normalize 15+ How Reported variants, force case-number string dtype, emit cleaned copy + diff. Run after /preflight-export, before timereport/arrest join.
---

# /clean-cad-export

Canonical CAD-export cleanup for the Hackensack PD FileMaker CAD system. The raw export accumulates variant text, embedded newlines, and column-name typos that silently break joins and group-bys. This skill codifies the fixes so each monthly drop gets the same treatment.

## When to trigger

- `/preflight-export` flagged a CAD file (WARN or FAIL)
- User says "clean the CAD export", "fix the CAD file", "normalize How Reported"
- Before `/run-mva-etl` or any join where CAD is the left or right table

## Inputs

- **Default:** latest `*CAD*.xlsx` in `Data_Ingest/CAD_RMS_Exports/`
- **Optional:** explicit path

## Transformations (apply in order)

### 1. Case-number string coercion
```python
cad = pd.read_excel(src, dtype={"ReportNumberNew": str})
```
Never let pandas infer — Excel strips leading zeros on numeric-looking IDs.

### 2. Strip embedded newlines
```python
cad["ReportNumberNew"] = (
    cad["ReportNumberNew"]
    .astype(str)
    .str.replace(r"\n", "", regex=True)
    .str.strip()
)
```
Known to affect ≥ 1 row per monthly drop. Unfixed, it creates a phantom key that fails every merge.

### 3. Normalize `How Reported`
Map all 15+ variants to the canonical set `{911, Email, Radio, Walk-In, Phone, Self-Initiated, Alarm, Other}`:
```python
HOW_REPORTED_MAP = {
    # 911 variants
    "9-1-1": "911", "911": "911", "9 1 1": "911",
    # Email variants
    "email": "Email", "Email": "Email", "eMail": "Email",
    "EMAIL": "Email", "emial": "Email", "email\n": "Email",
    # Radio variants
    "radio": "Radio", "Radio": "Radio", "RADIO": "Radio",
    "raid": "Radio", "row": "Radio",
    # Phone (non-911)
    "phone": "Phone", "Phone": "Phone", "PHONE": "Phone",
    # Walk-in
    "walk in": "Walk-In", "walk-in": "Walk-In", "Walk In": "Walk-In",
    # Self-initiated
    "self": "Self-Initiated", "Self": "Self-Initiated",
    "self initiated": "Self-Initiated", "Self-Initiated": "Self-Initiated",
    # Alarm
    "alarm": "Alarm", "Alarm": "Alarm",
}
cad["How Reported"] = (
    cad["How Reported"]
    .astype(str)
    .str.strip()
    .str.replace(r"\n", "", regex=True)
    .map(HOW_REPORTED_MAP)
    .fillna("Other")
)
```
Maintain this map in the skill. Add new variants as they appear.

### 4. Strip whitespace in categorical columns
`Incident`, `Disposition`, `Response Type`, `FullAddress2` — `.str.strip()` on each. Fixes "phantom category duplicates" caused by trailing spaces.

### 5. Fix `FullAddress2` leading `" & "`
19 rows per sample have `" & Main St"` from intersections with missing first street. Replace leading `" & "` with `""`.

### 6. Do NOT rename `HourMinuetsCalc` in place
The typo column name is load-bearing — Power BI M code references it. Leave the column name alone. Document the typo but don't "fix" it. (The downstream standardize_m_code.py handles the sister typo `"Crime Analysis "` → `"Crime Analysis"` in M code, not in the CAD data itself.)

## Outputs

1. **Cleaned file** → `Data_Ingest/CAD_RMS_Exports/_cleaned/<original_basename>__cleaned.xlsx`
   - Only the transformations above. Same column order, same column names (including `HourMinuetsCalc`), same row count unless totals-rows were filtered (S2 scope — not this skill's job).
2. **Diff report** → Markdown to stdout:
   ```
   # CAD Cleanup Report — 2026_03_CAD.xlsx
   - Input rows: 9,881
   - Output rows: 9,881 (no row filtering applied)
   - ReportNumberNew \n strips: 1 row
   - How Reported normalizations:
     - "emial" → "Email": 3 rows
     - "raid" → "Radio": 1 row
     - "email\n" → "Email": 2 rows
     - (12 more mappings, 47 rows total)
   - Incident trailing-space strips: 7 rows
   - FullAddress2 " & " prefix strips: 19 rows
   - Output: Data_Ingest/CAD_RMS_Exports/_cleaned/2026_03_CAD__cleaned.xlsx
   ```

## Hard rules

- Read-only on the original export. Never overwrite `Data_Ingest/CAD_RMS_Exports/2026_03_CAD.xlsx`.
- Cleaned file goes in `_cleaned/` subfolder.
- Never write to `01_Legacy_Copies/`.
- This skill does not apply S2 (totals filter) or S3 (dedupe) — those live in `/apply-s2-s3-s4` or `mva_crash_etl.py`. Separation of concerns: this skill normalizes text, S2/S3 reshape rows.

## Related skills
- Upstream: `/preflight-export`
- Downstream: `/run-mva-etl`, `/apply-s2-s3-s4`, `/clean-arrest-export` (sibling)
