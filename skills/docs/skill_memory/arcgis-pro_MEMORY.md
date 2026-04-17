# arcgis-pro — Skill Hardening Memory

**Skill path:** `C:\Users\carucci_r\.claude\skills\arcgis-pro\SKILL.md`
**Scope:** GLOBAL
**Type:** Read-only guidance (documentation skill — no executable)
**Run date:** 2026-04-16
**Final status:** PASS (9/9)

## Scorecard

| # | Test | Score | Evidence |
|---|------|-------|----------|
| 1 | Exists & Loadable | 1 | Valid YAML frontmatter (name + description); 56 lines total; Python parse check clean |
| 2 | Shared Context Access | 1 | References (`path_config`, `10_Projects/` CLAUDE.md) are project-agnostic pointers, not hard-coded file reads |
| 3 | Path Safety | 1 | Grep: no `RobertCarucci`, `~/`, `PowerBI_Date`, hard-coded `C:\Users\...` |
| 4 | Data Dictionary Compliance | 1 | All cited arcpy APIs are real: `arcpy.env.scratchGDB`, `arcpy.env.workspace`, `arcpy.env.overwriteOutput`, `arcpy.AddMessage/AddWarning/AddError`, `arcpy.GetMessages`, `arcpy.ExecuteError` |
| 5 | Idempotency / Safe Re-run | 1 | Guidance: Describe/Exists before destructive ops; clear `scratchGDB` between re-runs |
| 6 | Error Handling | 1 | Guidance adds try/except pattern with `arcpy.ExecuteError`, `arcpy.GetMessages(2)`, non-zero `sys.exit` for scheduled runs |
| 7 | Output Correctness | 1 | Frontmatter parses cleanly; body is valid Markdown with fenced code blocks |
| 8 | CLAUDE.md Rule Compliance | 1 | Matches tech stack: no pip, no PyYAML in Pro, scratchGDB not in_memory, `carucci_r` |
| 9 | Integration / Cross-Skill Safety | 1 | `etl-pipeline` explicitly carves out "(where not ArcGIS Pro)"; arcgis-pro does not duplicate ETL patterns (no `ReportNumberNew`) |

## Iteration Log

### Iteration 1 — Initial scan
- T1, T2, T3, T4, T5, T7, T8, T9: PASS
- T6: FAIL — skill did not mention try/except, `arcpy.GetMessages(2)`, or non-zero exit on failure
- Correctness gap (not a FAIL, but misleading): `sys.argv` was recommended for args under the Pro Python window `exec()` pattern, where `sys.argv` is not populated from user-supplied arguments

### Iteration 2 — Fix applied
Edited `SKILL.md`:
1. Clarified `sys.argv` works for command-line / Task Scheduler invocation, NOT under Pro Python window `exec()`; recommended module-level variables for exec-based runs.
2. Added "## Error Handling" section with `try/except arcpy.ExecuteError`, `arcpy.GetMessages(2)`, and `sys.exit(1)` for scheduled runs.
3. Added `arcpy.AddMessage/AddWarning/AddError` note for geoprocessing tool contexts (print() only works in the Python window).
4. Added scratchGDB clear-between-runs guidance for idempotency.

### Iteration 3 — Regression test
All 9 tests PASS. No regression against prior PASSes.

## Failure Analysis (from Iteration 1)

| Field | Value |
|-------|-------|
| Skill Name | arcgis-pro |
| Failed Test | T6 — Error Handling |
| Exact Problem | No guidance on try/except, arcpy error surfacing, or non-zero exit codes |
| Evidence | `grep -i "try\|except\|GetMessages\|sys.exit"` → 0 matches in original SKILL.md |
| Root Cause | Original skill was a minimal stub focused on environment constraints, not defensive coding |
| Corrective Action | Added dedicated `## Error Handling` section with code example |
| New Strategy | Re-grep for `arcpy.ExecuteError`, `arcpy.GetMessages`, `sys.exit` — all now present |

## Notes

- Working directory `C:\Users\carucci_r\.claude\skills` is NOT a git repo → Phase 6 (git commit) skipped.
- Phase 7 SKILLS_INDEX.md edit skipped per user instruction (user will update manually after all three skills complete).
- Aggregated guide (`global_skills.md`) entry and `how_to/arcgis-pro.md` created.
