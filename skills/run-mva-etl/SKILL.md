---
name: run-mva-etl
description: Wrap mva_crash_etl.py in Workbook_Redesign_2026 with preflight + post-checks — schema validation, row-count delta vs prior, S2/S3/S4 proof, unit/metric distribution sanity. Emits a Markdown run report. Use for the monthly MVA crash refresh.
---

# /run-mva-etl

The MVA ETL is a one-shot script with zero arguments — easy to forget the validation harness around it. This skill wraps `python mva_crash_etl.py` with preflight + post-checks so the monthly refresh has an auditable trail.

## When to trigger

- Monthly MVA refresh
- User says "run the MVA ETL", "refresh crashes", "regenerate fact_mva_crashes"
- After a fresh CAD + timereport drop has passed `/preflight-export`

## Inputs

- None. Script reads from `Data_Ingest/CAD_RMS_Exports/` and writes to `Data_Load/`.

## Steps

### 1. Capture prior state
Before running, read the existing fact table for delta comparison:
```python
prior = pd.read_csv("Data_Load/fact_mva_crashes_2026.csv")
prior_count = len(prior)
prior_max_date = prior["Date"].max()
prior_unit_dist = prior["Unit"].value_counts().to_dict()
prior_metric_dist = prior["Metric"].value_counts().to_dict()
```
If the file doesn't exist, this is the first run — note that and skip delta comparison.

### 2. Preflight (lightweight; defer heavy checks to /preflight-export)
- Confirm `Data_Ingest/CAD_RMS_Exports/` contains a `*CAD*.xlsx` and a `*timereport*.xlsx`.
- Confirm both files are > 10 KB.
- If either is missing, abort with a clear error and recommend running `/preflight-export`.

### 3. Run the ETL

From the **Workbook_Redesign_2026** repository root (the folder that contains `mva_crash_etl.py` — open it as the active Claude Code project so relative paths like `Data_Ingest/` resolve). Avoid Linux-only placeholders such as `/home/user/...`.

```bash
python mva_crash_etl.py
```

Capture stdout (the script already prints unit + metric distributions).

### 4. Post-checks
Read the freshly written `Data_Load/fact_mva_crashes_2026.csv` and validate:

#### 4a. Schema check
Columns must be exactly `Date, Unit, MetricGroup, Metric, Value` in order. Anything else = FAIL.

#### 4b. Dtype check
- `Date`: parseable to datetime, no nulls.
- `Unit`: string, in `{"Patrol Division", "Traffic Bureau", "Other/Admin"}`.
- `MetricGroup`: string, all rows == `"Motor Vehicle Accidents"`.
- `Metric`: string, in the expected `{"Crash - Standard", "Crash - Hit and Run", "Crash - With Injury", "Crash - Pedestrian Struck", "Crash - Bicyclist Struck", "Crash - Police Vehicle", "Crash - Other"}`.
- `Value`: numeric, all values `>= 0`, no nulls.

#### 4c. S2/S3/S4 proof
- **S2:** confirm no row's `Metric` contains "Total" (mva_crash_etl.py applies S2; this is a safety net).
- **S3:** the script dedupes on `ReportNumberNew` internally — output rows ≤ input crash rows. Surface the dedup count from the script's stdout.
- **S4:** every row has `Value == 1` for crashes (count-only events). Flag if any other Value seen.

#### 4d. Row-count delta vs prior
- Compute `delta = current_count - prior_count`.
- Expected: positive delta (new month added). If negative, FAIL — something rolled off unexpectedly.
- If `|delta|` > 30% of prior, WARN — investigate.

#### 4e. Date coverage
- Confirm `current.Date.max() > prior.Date.max()` — new month landed.
- Confirm no gaps in `Date` between min and max month (no skipped months).

#### 4f. Unit distribution sanity
- Patrol Division typically dominates (≥80%). If Patrol < 50% or Traffic > 30%, WARN — Squad attribution may be drifting.
- "Other/Admin" rows are the squad-attribution gap. Surface count and recommend reviewing if > 25 (this is the "integrity metric" called out in `handoff_gemini_2026_04_15.md`).

### 5. Emit Markdown run report

```markdown
# MVA ETL Run Report — 2026-04-16

## Sources
- CAD: 2026_03_CAD.xlsx (2.4 MB, 9,881 rows)
- Timereport: 2026_03_timereport.xlsx (1.8 MB, 9,878 rows)

## Output
- Path: Data_Load/fact_mva_crashes_2026.csv
- Rows: 211 (prior: 198, delta: +13, +6.6%)
- Date range: 2026-01-01 → 2026-03-31

## Schema [PASS]
- Columns: Date, Unit, MetricGroup, Metric, Value (canonical)
- Dtypes: all valid
- No nulls in Date or Value

## S2/S3/S4 Proof [PASS]
- S2 totals filter: 0 totals rows in output (CAD had 4, all dropped)
- S3 dedupe: 211 unique ReportNumberNew (input had 215 crash rows, 4 dupes removed)
- S4 Value shim: all 211 rows have Value=1

## Unit Distribution
- Patrol Division: 188 (89%) [PASS]
- Traffic Bureau: 4 (2%)
- Other/Admin: 19 (9%) [INFO — review if Squad join coverage degrades]

## Metric Distribution
- Crash - Standard: 142
- Crash - With Injury: 38
- Crash - Hit and Run: 21
- Crash - Pedestrian Struck: 6
- Crash - Bicyclist Struck: 3
- Crash - Police Vehicle: 1

## Overall: PASS — fact_mva_crashes_2026.csv ready for Power BI refresh
```

### 6. Stop on FAIL
If any check fails, do NOT mark the run complete. Surface the failure prominently and recommend:
- Schema FAIL → likely `mva_crash_etl.py` was modified; run `git diff mva_crash_etl.py`.
- Negative delta → confirm the old fact table wasn't archived correctly; restore from git.
- Other/Admin > 25 → check timereport Squad coverage; some incidents may need manual unit assignment.

## Hard rules

- This skill is read-mostly: it runs an existing script; it does not modify the script.
- Do not delete the prior fact table before the new one is validated. The script overwrites `Data_Load/fact_mva_crashes_2026.csv` directly — if validation fails post-write, the prior version is already gone. Acceptable (the prior is in git history) but flag this in the run report so the user can `git checkout HEAD~1 -- Data_Load/fact_mva_crashes_2026.csv` if needed.

## Related skills
- Upstream: `/preflight-export`, `/clean-cad-export`
- Sibling: `/apply-s2-s3-s4` (generic), `/standardize-m-code`
- Downstream: Power BI refresh
