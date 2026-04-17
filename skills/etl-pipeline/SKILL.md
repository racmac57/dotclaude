---
name: etl-pipeline
description: Guides building and modifying ETL scripts for law enforcement data (CAD, RMS, Arrests, Summons) under 02_ETL_Scripts, enforcing standard load patterns, path resolution, quality checks, and archive-first output conventions.
---

# ETL Pipeline — Standard Workflow

## When to Use

When building or modifying any ETL script that processes law enforcement data
(CAD, RMS, Arrests, Summons, Personnel, Benchmark, etc.) under `02_ETL_Scripts/`.

## Standard Load Pattern

Always force string dtype for case number columns to prevent Excel format
loss:

```python
import pandas as pd

df = pd.read_excel(path, dtype={"ReportNumberNew": str})
```

If columns are detected dynamically, apply `dtype=str` only to known ID/case columns, not entire sheets.

## Pipeline Shape

1. Resolve paths with `path_config.get_onedrive_root()` or project-relative paths — avoid hardcoded `RobertCarucci`.
2. Load source (Excel/CSV); validate required columns against `09_Reference/Standards/` where applicable.
3. Normalize fields (dates, categories, addresses) using existing project patterns.
4. Run quality checks (nulls, duplicates, domain values) before writing outputs.
5. Write outputs under the project folder or `13_PROCESSED_DATA/` as appropriate; use `YYYY_MM_DD_` naming for exports.
6. Never delete source data — archive with a datestamp under `archive/` if retiring a file.

## Libraries

Prefer: `pandas`, `openpyxl`, `pathlib`, `PyYAML` (where not ArcGIS Pro). Use `pyodbc` only when explicitly connecting to SQL sources defined in the project.

## References

- Canonical schemas and dictionaries: `09_Reference/Standards/`
- Archive-first and git checkpoint expectations: project `CLAUDE.md` and Standards
