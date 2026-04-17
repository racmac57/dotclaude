# Skill Hardening — Master Tracker

**Host:** `C:\Users\carucci_r\.claude\skills\` (global skills directory)
**Last run:** 2026-04-16
**Harness (most recent):** `/qa-skill-hardening target=data-validation`
**Prior runs (this date):** `target=etl-pipeline`, `target=arcgis-pro`

## Global status table

| Skill | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Score | Status |
|-------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:-----:|:------:|
| etl-pipeline | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 9/9 | **PASS** |
| arcgis-pro | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 9/9 | **PASS** |
| data-validation | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 9/9 | **PASS** |

Only the targeted skills have been hardened in this cycle. Other global skills
(`chunk-chat`, `frontend-slides`, `hpd-exec-comms`, `html-report`,
`qa-skill-hardening`) are outside the current scope and were not re-tested —
their status from prior runs stands.

## Cross-skill dependency map (for etl-pipeline)

```
etl-pipeline (guidance)
├── cites rule from → global CLAUDE.md (ReportNumberNew, path_config, archive-first)
├── complementary to → /new-etl        (scaffolds the project etl-pipeline modifies)
├── complementary to → /data-validation (implements the QC step in Pipeline Shape §4)
├── complementary to → /check-paths     (enforces the path rules etl-pipeline teaches)
└── boundary with    → /arcgis-pro      ("where not ArcGIS Pro" carve-out for PyYAML)
```

No skill writes to a path that etl-pipeline also writes to (etl-pipeline is
read-only guidance).

## Cross-skill dependency map (for arcgis-pro)

```
arcgis-pro (guidance)
├── cites rule from → global CLAUDE.md (carucci_r, scratchGDB, no pip in Pro)
├── boundary with    → /etl-pipeline    ("where not ArcGIS Pro" carve-out)
├── boundary with    → /new-etl         (etl scaffolder — does not target arcpy)
└── complementary to → /check-paths     (shared path-safety rules)
```

arcgis-pro is read-only guidance; no write conflicts.

## Cross-skill dependency map (for data-validation)

```
data-validation (guidance)
├── cites rule from   → global CLAUDE.md (ReportNumberNew dtype=str at load)
├── cites schema from → 09_Reference/Standards/CAD_RMS/DataDictionary/current/schema/canonical_schema.json
├── sibling artifact  → ~/.claude/commands/validate-data.md  (same domain, different invocation surface)
├── complementary to  → /etl-pipeline (data-validation is the QC step in pipeline §4)
└── boundary with     → none (read-only; no shared write targets)
```

`data-validation` is read-only guidance; no write conflicts.

## Shared lessons learned

- **Guidance skills require a mentor-mode review layer.** Binary 9/9 passes do
  not equal "perfect." The scorecard says the skill is internally consistent
  and rule-compliant; the advisory observations in `etl-pipeline_MEMORY.md`
  capture what it is *missing* for users. Keep both layers separate.
- **`path_config.get_onedrive_root()` is a convention, not a shared module.**
  Only one deployed Python file defines it (`Summons/.../verify_summons_march_reconciliation.py`).
  Agents applying etl-pipeline guidance in a new ETL project may need to
  scaffold the helper first — `/new-etl` is the natural companion for that.

## Risk register

| ID | Risk | Likelihood | Mitigation |
|----|------|:----------:|------------|
| R1 | Skill remains minimal; a user may produce a non-compliant pipeline because the skill does not enumerate all ID columns or cross-link sibling skills | Medium | Track in advisory observations; revisit if a Summons/Arrests ETL is authored against this skill |
| R2 | `path_config.py` convention drift (e.g. a new project forgets to create the helper) | Low | `/check-paths` already flags hardcoded absolutes; compensating control exists |

## Autonomous swarm completion

- Status: **YES**
- Phases executed: 0, 1, 2, 4, 5 (Phase 3 skipped — no write-capable skills in scope; Phase 6 commit skipped — global skills directory is not a git repo; Phase 7 executed below)

### arcgis-pro run notes (2026-04-16)

- Iteration 1 first-pass: 8/9 PASS (T6 Error Handling failed — no try/except, no `arcpy.GetMessages`, no `sys.exit`).
- Iteration 2 fix: added `## Error Handling` section with `arcpy.ExecuteError` + `arcpy.GetMessages(2)` + `sys.exit(1)`; clarified `sys.argv` vs Pro Python window `exec()`; added `arcpy.AddMessage/AddWarning/AddError` note.
- Iteration 3 regression: 9/9 PASS. No prior-PASS → FAIL transitions.
- Phase 7 SKILLS_INDEX.md edit **skipped** per user directive (user updates manually after all parallel runs complete).

### data-validation run notes (2026-04-16)

- Iteration 1 first-pass: 7/9 PASS. T6 (Error Handling) failed — no missing-input clause; T8 (CLAUDE.md compliance) failed — `dtype=str` rule mentioned only parenthetically, not at load time.
- Iteration 2 fix: added `## Inputs & Failure Modes` (missing path → stop; missing column → mark N/A) and `## Load Conventions` (`dtype={'ReportNumberNew': str, 'CaseNumber': str}` shown as code block, marked as a hard CLAUDE.md rule).
- Iteration 2 regression: 9/9 PASS. No prior-PASS → FAIL transitions.
- Sibling artifact noted: `~/.claude/commands/validate-data.md` covers same domain via different invocation; no runtime conflict, but doc consolidation is a future cleanup candidate.
- Phase 7 SKILLS_INDEX.md edit **skipped** per user directive.
