---
name: standardize-m-code
description: Wrapper around standardize_m_code.py in Workbook_Redesign_2026 with --target-dir 02_Legacy_M_Code pre-baked. Kills the hardcoded Windows OneDrive default. Dry-run first, explicit --apply. Run after editing any .m file or for bulk passes.
---

# /standardize-m-code

The bare `standardize_m_code.py` script defaults `--target-dir` to a Windows OneDrive path that doesn't exist on this Linux repo. This skill removes the footgun by always passing `--target-dir 02_Legacy_M_Code` and wraps the run with dry-run review semantics.

## When to trigger

- After editing any `.m` file in `02_Legacy_M_Code/`
- Before a bulk standardization pass (S2 totals filter / S3 dedupe / S4 Value=1 / "Crime Analysis " cleanup)
- User says "standardize the M code", "apply S2/S3/S4 to .m files", "fix Crime Analysis whitespace"

## Inputs

- **Mode:** `dry-run` (default) or `apply`
- **Scope:** all files (default) or single file via fuzzy match (`--file <name>`)

## Steps

### 1. Always run in dry-run mode first
```bash
cd /home/user/Workbook_Redesign
python standardize_m_code.py --target-dir 02_Legacy_M_Code
```
For a single file:
```bash
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file <fuzzy_name>
```

### 2. Review the unified diff
The script prints per-file diffs. Look for:
- **S2:** `Table.SelectRows(..., each not Text.Contains(Text.From([<col>]), "Total", Comparer.OrdinalIgnoreCase))` — totals filter added.
- **S3:** `Table.Distinct(..., {"<PK>"})` — dedupe step added on `Control #` or `ReportNumberNew`.
- **S4:** `Table.AddColumn(..., "Value", each 1, Int64.Type)` — shim added before unpivot.
- **CLN:** `"Crime Analysis "` → `"Crime Analysis"` — trailing-space fix.

Per-file SKIP reasons are normal:
- `S2: SKIP no targetable predicate` — file doesn't filter on a known metric column. OK.
- `S3: SKIP no known PK found` — file's primary key isn't `Control #` or `ReportNumberNew`. OK.
- `S4: SKIP not granular (no Unpivot)` — file is an aggregate query. OK.
- `S4: SKIP Value column already added` — already shimmed. OK.

### 3. Confirm with user before applying
Present a summary:
```
Dry-run complete: 67 files matched
- 12 files with S2 enhancements
- 8 files with S3 dedupe additions
- 5 files with S4 shim additions
- 3 files with Crime Analysis cleanup

Apply? [requires explicit user approval]
```

### 4. On user approval, apply
```bash
python standardize_m_code.py --target-dir 02_Legacy_M_Code --apply
```
For single file:
```bash
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file <fuzzy_name> --apply
```

### 5. Post-apply check
- Run `git diff 02_Legacy_M_Code/` to confirm changes match the dry-run preview.
- If they don't match, the script may have been re-run with different inputs — investigate.

## Hard rules

- **Never call the script without `--target-dir 02_Legacy_M_Code`.** The hardcoded Windows default at `standardize_m_code.py:34–36` will fail on this repo. Always pass the flag — that's the entire point of this wrapper.
- **Always dry-run first.** Apply only on explicit user confirmation.
- **One file at a time when possible.** Bulk apply across all 67 files is fine, but if reviewing a complex change, scope to `--file <name>`.
- **Don't apply twice.** The script is idempotent (S2/S3/S4 detect existing additions and SKIP), but a clean dry-run-then-apply cycle is cleaner audit-wise than running `--apply` repeatedly.
- **Read-only on `01_Legacy_Copies/`.** This skill only touches `02_Legacy_M_Code/`. Never point `--target-dir` at `01_Legacy_Copies/` or any other path.

## Common invocations

```bash
# Dry-run all .m files (canonical first step)
python standardize_m_code.py --target-dir 02_Legacy_M_Code

# Dry-run a specific file (fuzzy match)
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file csb_monthly.m
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file patrol

# Apply to all
python standardize_m_code.py --target-dir 02_Legacy_M_Code --apply

# Apply to one file
python standardize_m_code.py --target-dir 02_Legacy_M_Code --file traffic.m --apply
```

## Why this skill exists

The script's signature footgun is at `standardize_m_code.py:34–36`:
```python
DEFAULT_TARGET_DIR = Path(
    r"C:\Users\carucci_r\OneDrive - City of Hackensack\06_Workspace_Management\m_code"
)
```
On Linux, calling the script with no flag does:
```
FileNotFoundError: [Errno 2] No such file or directory:
'C:\\Users\\carucci_r\\OneDrive - City of Hackensack\\06_Workspace_Management\\m_code'
```
This is the most common failure mode in fresh sessions. This skill exists exclusively to prevent it.

## Related skills
- Sibling: `/apply-s2-s3-s4` (generic, for raw tables; this skill is for `.m` files only)
- Used by: `/standardize-compstat-wb` (per-workbook redesign calls this for the M-code rewrite step)
- Upstream: `/inventory-wave` (identifies which `.m` files belong to which unit)
