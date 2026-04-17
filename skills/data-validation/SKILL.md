---
name: data-validation
description: Run standard data quality checks (completeness, domain values, duplicates, case number format, null patterns, before/after deltas) on datasets before deployment to dashboards or reports.
---

# Data Validation — Standard Quality Checks

## When to Use

When validating any dataset before deployment to dashboards, reports, or
downstream consumers. Use after ETL processing, after normalization, and
before production handoff (ESRI polished layers, Power BI, etc.).

## Inputs & Failure Modes

**Required input:** path to an Excel (`.xlsx`) or CSV file. If the path does
not exist or cannot be read, stop and report the exact path that failed — do
not silently continue with an empty frame.

**Required column behavior:** if a check names a specific column
(e.g. `ReportNumberNew`, `Disposition`) and that column is absent, mark the
check **N/A** with the missing column name surfaced in the report. Do not
fabricate values, and do not coerce a missing column into a PASS.

## Load Conventions

When loading from Excel, **always** force string dtype on case-number columns
so the `YY-NNNNNN` format survives Excel's leading-zero stripping:

```python
pd.read_excel(path, dtype={'ReportNumberNew': str, 'CaseNumber': str})
```

Apply the same rule to CSV loads (`pd.read_csv(..., dtype={...})`). This is a
hard CLAUDE.md rule, not a preference.

## Checks

1. **Completeness** — Per column, report `notna()` share. Flag critical fields below **99%** populated (adjust list per project).
2. **Domain values** — Compare categorical columns to canonical lists in `09_Reference/Standards/` or project docs (e.g. disposition, how reported).
3. **Duplicates** — Count duplicates on natural keys (`ReportNumberNew`, etc.); list top offenders.
4. **Case number format** — Where `ReportNumberNew` exists, verify pattern `YY-NNNNNN` (after string dtype).
5. **Null patterns** — Cross-field nulls (e.g. address missing when disposition implies location).
6. **Before/after** — When replacing a file, summarize row counts and key metric deltas.

## Reporting

Output a concise table or bullet summary: PASS/FAIL per check, with counts and example row IDs or keys for failures.

## Thresholds

Default completeness threshold for **critical** fields: **99%**. Non-critical fields: report only; do not fail the run unless the user specifies stricter rules.

## References

- Canonical schemas: `09_Reference/Standards/CAD_RMS/DataDictionary/current/schema/` (and project `CLAUDE.md`)
