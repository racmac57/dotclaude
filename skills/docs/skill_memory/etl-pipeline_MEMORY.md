# etl-pipeline — Skill Hardening Memory

**Scope:** GLOBAL (`C:\Users\carucci_r\.claude\skills\etl-pipeline\SKILL.md`)
**Type:** Read-only guidance (no executable code; no write side effects)
**Run date:** 2026-04-16
**Target:** `target=etl-pipeline`
**Harness:** `/qa-skill-hardening`

---

## Final Binary Scorecard

| # | Test | Result | Evidence |
|---|------|:------:|----------|
| 1 | Exists & Loadable | **PASS** | 42-line file at expected path; YAML frontmatter (`name`, `description`) parses cleanly; closing `---` on line 4 |
| 2 | Shared Context Access | **PASS** | All referenced paths resolve (see Evidence Log §T2) |
| 3 | Path Safety | **PASS** | Single `RobertCarucci` occurrence is a negation; no hardcoded `C:\…` or `~/` assumptions |
| 4 | Data Dictionary Compliance | **PASS** | `ReportNumberNew` matches CLAUDE.md canonical field; folder names match workspace layout |
| 5 | Idempotency / Safe Re-run | **PASS** | Guidance document is intrinsically idempotent; advocated patterns (archive-first, datestamped filenames) are themselves idempotent |
| 6 | Error Handling | **PASS** | Pipeline Shape steps 2 and 4 promote pre-write validation; archive-first rule in step 6 protects against destructive failures |
| 7 | Output Correctness | **PASS** | Clean markdown, valid frontmatter, well-formed code fence, six canonical sections |
| 8 | CLAUDE.md Rule Compliance | **PASS** | 9 of 9 applicable global rules reflected (see Evidence Log §T8) |
| 9 | Integration / Cross-Skill Safety | **PASS** | No shared write targets; boundary with `/arcgis-pro` explicitly respected; complementary to `/new-etl`, `/data-validation`, `/check-paths` |

**Total:** 9 / 9 PASS
**Status:** **PASS**
**Iterations required:** 1 (clean first pass — no fixes applied)

---

## Evidence Log

### T1 — Exists & Loadable
```
$ wc -l "C:\Users\carucci_r\.claude\skills\etl-pipeline\SKILL.md"
42 C:\Users\carucci_r\.claude\skills\etl-pipeline\SKILL.md

$ head -5 "…\etl-pipeline\SKILL.md"
---
name: etl-pipeline
description: Guides building and modifying ETL scripts …
---
```

### T2 — Shared Context Access
| Reference | Resolves to | Status |
|-----------|------------|--------|
| `02_ETL_Scripts/` | `…\OneDrive - City of Hackensack\02_ETL_Scripts\` | ✓ exists |
| `09_Reference/Standards/` | `…\OneDrive - City of Hackensack\09_Reference\Standards\` | ✓ exists (CAD, CAD_RMS, NIBRS, Personnel subfolders) |
| `13_PROCESSED_DATA/` | `…\OneDrive - City of Hackensack\13_PROCESSED_DATA\` | ✓ exists |
| `CLAUDE.md` (global) | `C:\Users\carucci_r\.claude\CLAUDE.md` | ✓ exists — declares `path_config.py` convention |
| `path_config.get_onedrive_root()` | Documented convention in global CLAUDE.md line 31 and in `cad_rms_data_quality\CLAUDE.md` line 25 | ✓ convention established |
| `archive/` | Generic per-project convention enforced by CLAUDE.md "Archive-first" rule | ✓ |

### T3 — Path Safety
Single `RobertCarucci` match in SKILL.md is in a negation clause:
> "Resolve paths with `path_config.get_onedrive_root()` or project-relative paths — avoid hardcoded `RobertCarucci`."
No absolute `C:\` paths. No `~/` or HOME-relative assumptions. All workspace folder references use the canonical numeric-prefix names.

### T4 — Data Dictionary Compliance
| Token | Source of truth | Match |
|-------|-----------------|-------|
| `ReportNumberNew` | Global CLAUDE.md "Case numbers" rule; `/data-validation` skill | ✓ |
| `02_ETL_Scripts` | Workspace Layout (CLAUDE.md) | ✓ |
| `09_Reference/Standards` | Canonical Data Sources (CLAUDE.md) | ✓ |
| `13_PROCESSED_DATA` | Workspace Layout (CLAUDE.md) | ✓ |

### T5 — Idempotency
No write side effects exist to re-run. Guidance recommends archive-first and datestamped filenames, both of which prevent destructive re-runs.

### T6 — Error Handling
Pipeline Shape steps that promote defensive behavior:
- Step 2: "validate required columns against `09_Reference/Standards/`"
- Step 4: "Run quality checks (nulls, duplicates, domain values) **before** writing outputs"
- Step 6: "Never delete source data — archive with a datestamp"

### T7 — Output Correctness
Sections (in order): `When to Use`, `Standard Load Pattern`, `Pipeline Shape`, `Libraries`, `References`. Code fence for `read_excel` example is syntactically valid Python. No unterminated fences, no dangling links.

### T8 — CLAUDE.md Rule Compliance
| CLAUDE.md rule | Reflected in SKILL.md? |
|----------------|------------------------|
| Use `carucci_r`, never `RobertCarucci` | ✓ line 28 |
| `path_config.get_onedrive_root()` for path resolution | ✓ line 28 |
| Workspace numeric-prefix layout | ✓ lines 28, 32, 41 |
| `YYYY_MM_DD_` naming for exports | ✓ line 32 |
| Force `ReportNumberNew` string dtype | ✓ lines 15-22 |
| Archive-first (no delete) | ✓ line 33 |
| Tech stack: pandas, openpyxl, pathlib, PyYAML | ✓ line 37 |
| ArcGIS Pro exception (no PyYAML, etc.) | ✓ line 37 ("where not ArcGIS Pro") |
| `PowerBI_Data` canonical (not `_Date`) | N/A — skill does not touch PowerBI paths |

### T9 — Integration / Cross-Skill Safety
| Sibling skill | Interaction | Safe? |
|---------------|-------------|-------|
| `/new-etl` | Complementary (scaffold → modify) | ✓ |
| `/data-validation` | Complementary (step 4 "quality checks" lines up with validator checks) | ✓ |
| `/check-paths` | Complementary (etl-pipeline promotes the rules `/check-paths` enforces) | ✓ |
| `/arcgis-pro` | Boundary respected ("where not ArcGIS Pro" exempts arcpy scripts from PyYAML) | ✓ |
| `/html-report`, `/chunk-chat`, `/frontend-slides`, `/frontend-design`, `/hpd-exec-comms`, `/claude-api`, `/simplify`, `/qa-skill-hardening` | No domain overlap | ✓ |

No shared write targets (read-only guidance).

---

## Iteration History

| Round | Action | Result |
|:-----:|--------|--------|
| 1 | Static validation of frontmatter, references, rule compliance | 9/9 PASS — no fix required |

No failure analyses generated (no failures occurred).

---

## Advisory Observations (Not Blocking)

Per `C:\Users\carucci_r\.claude\CLAUDE.md` Mentor Approach — calling these out even though tests passed:

1. **Cross-skill discoverability is implicit, not explicit.** The SKILL.md does not name `/new-etl`, `/data-validation`, or `/check-paths`. A future agent reading only this file would not know those exist. Adding a short "See also" section would make the skill ecosystem more navigable.

2. **`ReportNumberNew` is presented as the universal ID, but Summons/Arrests pipelines use different natural keys** (e.g. `ComplaintNum`, `SummonsNumber`). A user following this skill against a Summons dataset would hit blanks. Consider generalizing to "ID-like columns (ReportNumberNew, ComplaintNum, SummonsNumber, etc.)".

3. **Domain coverage omits NIBRS and Clery** — both named explicitly in the CLAUDE.md data domain glossary. The frontmatter lists "CAD, RMS, Arrests, Summons" but not these.

4. **No worked end-to-end example.** The Pipeline Shape is six bullets; a minimal `load → validate → normalize → QC → write → archive` snippet would make the pattern concrete.

These are enhancement opportunities, not defects. Test suite passes as-is.

---

## Final Status: **PASS (9/9)**
