---
name: check-paths
description: Scan the current project's source files for path hygiene issues.
---

# Path Hygiene Scanner

## When to Use

Before committing changes, after a mass rename, or when auditing any HPD
project for path-convention drift. Runs against the current working directory.

## Steps

1. Recursively scan all `.py`, `.yaml`, `.yml`, `.json`, `.bat`, `.ps1`, and
   `.cmd` files under the current working directory.
2. Report each issue with **file path** and **line number** (best-effort for
   JSON, which may not carry useful line numbers in every reader).
3. End with a summary: total issues by category and recommended fixes.

## Issues to Flag

### Issue 1: `RobertCarucci` instead of `carucci_r`

Flag any non-comment line containing `RobertCarucci`. Scripts and configs on
this desktop must use the real Windows profile name `carucci_r`. The
`RobertCarucci` form only belongs in git history or clearly archived docs.

### Issue 2: Deprecated `unified_data_dictionary` references

Flag paths or imports pointing at `unified_data_dictionary`. The canonical
location is `09_Reference/Standards/` (see global `CLAUDE.md`).

### Issue 3: Hardcoded absolute paths

Flag hardcoded `C:\Users\...` or `D:\` paths that bypass `path_config` (the
`get_onedrive_root()` resolver) or project-relative layout. Allow when the
path is clearly intentional and documented in a comment.

### Issue 4: `PowerBI_Date` folder name

Flag `PowerBI_Date` — the canonical folder is `PowerBI_Data`. `PowerBI_Date`
is a known typo that must not re-enter scripts or configs.

### Issue 5: Stale artifact references

Flag references to `PD_BCI_01` or other known retired paths when they appear
outside `archive/` or docs folders.

## Output

A single report grouped by issue type. For each hit use `path:line` format
with a short excerpt, for example:

```
Issue 1 — RobertCarucci (2 hits)
  02_ETL_Scripts/foo/bar.py:14  source = r"C:\Users\RobertCarucci\OneDrive..."
  scripts.json:7                "root": "C:\\Users\\RobertCarucci\\..."

Issue 4 — PowerBI_Date (1 hit)
  10_Projects/YearEnd/export.py:52  out_dir = root / "PowerBI_Date" / "2025"

Summary
  Issue 1: 2
  Issue 4: 1
  Total: 3
Recommended fixes: rename `RobertCarucci` → `carucci_r`; rename
`PowerBI_Date` → `PowerBI_Data`.
```

Do not invent new issue categories. If a file looks suspicious but does not
match one of the five rules, note it under the summary as "needs manual
review" rather than as a flagged issue.

## Notes

- `scripts.json` legitimately uses `carucci_r` — not a bug.
- `path_config.py` and its `get_onedrive_root()` helper are the preferred
  resolver for absolute paths; prefer guiding fixes toward that rather than
  hand-edited string constants.
- Archive folders (`archive/`, `_Archived/`, `docs/history/`) may contain
  deprecated references legitimately; treat them as informational.
