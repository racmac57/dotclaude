---
name: preflight-export
description: Validate raw CAD/RMS/arrest/summons exports in Data_Ingest/CAD_RMS_Exports before ETL. Checks bytes, headers, embedded newlines, delimiters, header offsets. Run before mva_crash_etl.py or any /clean-*-export skill in Workbook_Redesign_2026.
---

# /preflight-export

Monthly-refresh guard rail for raw CAD/RMS/arrest/summons exports. Run this **before** any downstream ETL so stale/corrupt/format-drifted files are caught at the boundary instead of halfway through processing.

## When to trigger

- User says "preflight the new export", "check the monthly drop", "validate the export"
- Before `/run-mva-etl` or `python mva_crash_etl.py`
- Before any `/clean-*-export` skill
- After a fresh CAD/RMS drop into `Data_Ingest/CAD_RMS_Exports/`

## Inputs

- **Default:** latest file matching each known pattern in `Data_Ingest/CAD_RMS_Exports/`:
  - `*CAD*.xlsx`
  - `*timereport*.xlsx`
  - `*LawSoft*Arrest*.xlsx`
  - `*eticket*.csv`
  - `*ATS*.xlsx`
  - `*RMS*.xlsx`
- **Optional:** explicit file path or glob from user.

## Checks to run

For each discovered export:

1. **Non-zero bytes.** `stat -c %s <file>` — flag anything under 10 KB; the RMS export has been seen as 7.2 MB of pure null bytes, so also sniff `head -c 100 | od -c | grep -c '\\0'` and flag if > 50.
2. **Openable.** `pd.read_excel(..., nrows=5)` (or `pd.read_csv(..., sep=auto-detect, nrows=5)`). Surface the exception verbatim if it fails.
3. **Header contract.** Compare observed columns against the expected set for the export type:
   - CAD → must include `ReportNumberNew`, `Incident`, `Time of Call`, `How Reported`, `Squad`, `HourMinuetsCalc` (sic — typo is expected).
   - Timereport → must include `ReportNumberNew`, `Squad`.
   - Arrest (LawSoft) → must include `ReportNumberNew`, `Charge`, `Race`, `Reviewed`.
   - E-Ticket → must include `Case Type Code`, `License Plate Number`, `Charge Time`.
   - ATS → header is on row 5 (4-row title block); check after `skiprows=4`.
4. **Delimiter sniff (CSV only).** E-Ticket uses `;` not `,`. Read with `csv.Sniffer().sniff(sample)` and flag if mismatch.
5. **Gotcha scans** (first 1000 rows):
   - CAD: count rows where `ReportNumberNew` contains `\n` (should be ≥ 0 — report exact count).
   - CAD: list all distinct `How Reported` values — flag if > 10 distinct (signals variant drift).
   - CAD: count leading-zero-stripped `ReportNumberNew` values (numeric-looking strings shorter than the expected 8–9 chars).
   - Arrest: detect trailing whitespace on `Charge`, `Race`, `Address` (these exports historically have 14–18% trailing-whitespace contamination).
   - Any: detect rows that match `Total` in the key column (S2 filter target — report count so the user knows how many rows S2 will drop).
6. **Row-count sanity band.** Compare to previous month's row count in `Data_Load/` (or the most recent fact table). Flag if delta > ±30%.

## Output format

Emit a Markdown report to stdout. Do NOT write any files. Do NOT modify exports.

```
# Preflight Report — 2026-04-16

## 2026_03_CAD.xlsx
- [PASS] Size: 2.4 MB
- [PASS] Opens cleanly, 9,881 rows × 20 cols
- [PASS] Header contract: all required columns present
- [WARN] ReportNumberNew has 1 row with embedded \n → `/clean-cad-export` will fix
- [WARN] How Reported has 16 distinct values (threshold 10) → variant drift, normalize
- [PASS] No totals-rows detected
- [PASS] Row count within ±30% of prior month

## 2026_03_LawSoft_Arrest.xlsx
- [PASS] Size: 48 KB
- [PASS] Opens cleanly, 56 rows × 18 cols
- [FAIL] Reviewed column casing inconsistent (3 variants for same reviewer)
- ...

## Overall: 2 WARN, 1 FAIL
Recommended next step: `/clean-arrest-export 2026_03_LawSoft_Arrest.xlsx` before ETL
```

## Hard rules

- Read-only. Never modify, rename, or move export files. Never write to `01_Legacy_Copies/`.
- Use `openpyxl` read-only mode or `pd.read_excel(..., nrows=N)` for sampling. Do not call `to_excel` or `openpyxl.save`.
- Case numbers must load as string: `dtype={"ReportNumberNew": str, "Control #": str}`.

## Known gotchas (do not re-discover each run)

- CAD `How Reported` variants: `email`/`Email`/`eMail`/`emial`/`email\n`, `9-1-1`/`911`, `Radio`/`radio`/`RADIO`/`raid`/`row`.
- Column typos carried from FileMaker: `HourMinuetsCalc` (should be "Minutes").
- ATS: 4-row title header + footer contamination.
- RMS export `2024_11_to_2025_11_Rolling13_RMS.xlsx` is known-corrupt (7.2 MB of zero bytes). If it reappears, flag FAIL and stop — do not try to "repair".
- Overtime/TimeOff templates are headers-only (0 rows). Expected state; not a failure.

## Related skills
- `/clean-cad-export` — runs after this if CAD flagged
- `/clean-arrest-export` — runs after this if arrest flagged
- `/clean-summons-export` — runs after this if E-Ticket flagged
- `/run-mva-etl` — runs after this passes clean
