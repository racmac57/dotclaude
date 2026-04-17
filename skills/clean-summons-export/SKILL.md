---
name: clean-summons-export
description: E-Ticket summons cleanup for Workbook_Redesign_2026 — handle `;` delimiter, strip whitespace in 16+ cols, parse 4 date formats, drop 11 null cols, split slash cols by Case Type. Emits summons_slim_for_powerbi.csv for DAX join in Power BI.
---

# /clean-summons-export

Monthly E-Ticket summons cleanup. The Summons table is **removed from the new Patrol workbook** (Hard Rule from CLAUDE.md) — Power BI handles Summons natively in DAX by joining this skill's output (`summons_slim_for_powerbi.csv`) against `___DimMonth`. This skill produces that slim file.

## When to trigger

- Monthly summons drop into `Data_Ingest/CAD_RMS_Exports/`
- `/preflight-export` flagged an E-Ticket file
- User says "clean the summons export", "refresh the summons slim file"

## Inputs

- **Default:** latest `*eticket*.csv` in `Data_Ingest/CAD_RMS_Exports/`
- **Optional:** explicit path

## Transformations (apply in order)

### 1. Read with semicolon delimiter
```python
df = pd.read_csv(
    src,
    sep=";",                   # NOT comma — default pd.read_csv gives 1-column garbage
    dtype=str,                 # parse all as string first; coerce later per column
    na_values=["", " ", "NA"],
    on_bad_lines="warn",       # 1 malformed row per sample — log not fail
    encoding="utf-8",
)
```

### 2. Strip whitespace on text columns
Known affected: `Offense Street Name`, `Defendant Last Name`, `License Plate Number`, `Defendant Address City`, `Defendant Address State`, and ~12 others.
```python
text_cols = df.select_dtypes(include=["object"]).columns
df[text_cols] = df[text_cols].apply(lambda s: s.str.strip())
```

### 3. Drop fully-null columns (11 known)
```python
known_empty = [
    "Court Street 2", "Hours Of Operation", "Vehicle VIN", "Unit Code",
    "Officer Middle Name", "Defendant Middle Name", "Vehicle Sub Model",
    "Vehicle Color 2", "Officer Rank", "Defendant Prefix", "Defendant Suffix",
]
df = df.drop(columns=[c for c in known_empty if c in df.columns])
```

### 4. Parse 4 date formats
- ISO timestamps with ms: `2026-03-14T08:22:11.000`
- Date-only strings: `2026-03-14`
- HHMM integers: `Charge Time` = `0310` → `03:10`
- `MM/YYYY` format: e.g., `Vehicle Registration Expiration`

```python
df["Offense Date"] = pd.to_datetime(df["Offense Date"], errors="coerce")
df["Charge Time"] = df["Charge Time"].astype(str).str.zfill(4).str[:2] + ":" + df["Charge Time"].astype(str).str.zfill(4).str[2:4]
# etc.
```

### 5. Resolve dual-purpose slash columns
Columns whose meaning depends on `Case Type Code`:
- `Meter Number/Speed MPH Zone Number` → Meter Number if `Case Type Code == "P"` (parking), Speed MPH Zone otherwise.
- `Area/Speed MPH` → same split.
- `Visibility/Is Commercial Vehicle` → same split.

```python
is_parking = df["Case Type Code"] == "P"
df["Meter Number"] = df["Meter Number/Speed MPH Zone Number"].where(is_parking)
df["Speed MPH Zone"] = df["Meter Number/Speed MPH Zone Number"].where(~is_parking)
df = df.drop(columns=["Meter Number/Speed MPH Zone Number"])
# Repeat for Area/Speed MPH and Visibility/Is Commercial Vehicle
```

### 6. Emit slim schema for DAX join
The Power BI model consumes only these columns — everything else is dropped at this stage:

| Column | Type | Source |
|---|---|---|
| `Date` | date | `Offense Date.dt.normalize()` |
| `MonthKey` | string (YYYY-MM) | `Offense Date.dt.strftime("%Y-%m")` — joins to `___DimMonth[MonthKey]` |
| `CaseTypeCode` | string | `Case Type Code` (P or M) |
| `Metric` | string | "Parking Summons" if P else "Moving Summons" |
| `OfficerBadge` | string | `Officer Badge Number` |
| `OffenseCode` | string | `Offense Code` |
| `OffenseDescription` | string | `Offense Description` |
| `PleadingAmount` | numeric | `Pleading Amount` (coerce to float) |
| `Value` | int | Literal `1` (S4 shim) |

```python
slim = pd.DataFrame({
    "Date": df["Offense Date"].dt.normalize(),
    "MonthKey": df["Offense Date"].dt.strftime("%Y-%m"),
    "CaseTypeCode": df["Case Type Code"],
    "Metric": df["Case Type Code"].map({"P": "Parking Summons", "M": "Moving Summons"}).fillna("Other Summons"),
    "OfficerBadge": df["Officer Badge Number"],
    "OffenseCode": df["Offense Code"],
    "OffenseDescription": df["Offense Description"],
    "PleadingAmount": pd.to_numeric(df["Pleading Amount"], errors="coerce"),
    "Value": 1,
})
slim = slim.dropna(subset=["Date"])
```

### 7. Write slim CSV
```python
slim.to_csv(PROJECT_ROOT / "Data_Load" / "summons_slim_for_powerbi.csv", index=False)
```

## Outputs

1. **Slim file** → `Data_Load/summons_slim_for_powerbi.csv` (overwrites — this file is idempotent)
2. **Diff report (stdout):**
   ```
   # Summons Cleanup Report — 2026_03_eticket_export.csv
   - Input rows: 4,160 | Slim output rows: 4,159 (1 row dropped: null Offense Date)
   - Delimiter: ; (as expected)
   - Trailing-whitespace strips: 16 columns, ~1,100 rows total
   - Empty columns dropped: 11
   - Slash-column splits: 3 (Meter/Speed, Area/Speed, Visibility/Commercial)
   - Parking (P): 3,204 rows | Moving (M): 955 rows
   - Output: Data_Load/summons_slim_for_powerbi.csv
   - ⚠  1 malformed row skipped at source parse — investigate 2026_03_eticket_export.csv line ~<N>
   ```

## Hard rules

- Read-only on the source file.
- Output goes to `Data_Load/summons_slim_for_powerbi.csv` — overwrites each month (idempotent by design; Power BI refresh re-reads).
- Never write to `01_Legacy_Copies/`.
- Never produce a "Summons" sheet in the Patrol workbook — that schema is abandoned per CLAUDE.md.
- PII: `Defendant Last Name`, `License Plate Number`, `Defendant Address` are in the source but **NOT in the slim output**. Do not leak them into commits or logs.

## Known gotchas (codified)

- Delimiter is `;`, not `,`. `pd.read_csv(..., sep=";")` required.
- `Charge Time` is a 4-digit integer (0310 = 03:10 AM), not a time type.
- 11 columns are fully null and must be dropped (not retained as all-NaN).
- 3 slash columns carry dual meaning dependent on `Case Type Code`.
- ~1 malformed row per monthly drop — CSV parser skips with warning. Investigate in source, don't try to recover.
- 4 distinct date formats across columns — no single `pd.to_datetime` invocation covers all.

## Related skills
- Upstream: `/preflight-export`
- Sibling: `/clean-cad-export`, `/clean-arrest-export`
- Downstream: Power BI refresh (no further skill needed — DAX handles the join)
