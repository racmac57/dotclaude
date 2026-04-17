# Regression Test Log

**Run date:** 2026-04-16
**Scopes (cumulative):** `etl-pipeline`, `arcgis-pro`, `data-validation`

## Result

| Skill | Phase 2 Score | Phase 4 Re-run Score | Delta |
|-------|:-------------:|:--------------------:|:-----:|
| etl-pipeline | 9 / 9 | 9 / 9 | 0 |
| arcgis-pro | 8 / 9 (T6 FAIL) | 9 / 9 | +1 |
| data-validation | 7 / 9 (T6, T8 FAIL) | 9 / 9 | +2 |

**No regressions.** No PASS → FAIL transitions detected on any skill.

**No regressions.** No PASS → FAIL transitions detected.

## Regression Tests Added

### arcgis-pro — T6 Error Handling

A Python assertion block verifies the `SKILL.md` continues to demonstrate
defensive arcpy patterns. Any future edit that removes these must either
restore them or update the regression. See `arcgis-pro_MEMORY.md` for the full
assertion block; the key invariants are:

- `try` + `except` both present
- `arcpy.GetMessages` referenced
- `sys.exit` referenced
- `arcpy.ExecuteError` referenced
- `arcpy.AddMessage` / `arcpy.AddError` referenced

### data-validation — T6 Error Handling and T8 Load-Time dtype

A two-pronged grep guard against `data-validation/SKILL.md`:

| Marker (must remain present) | Protects |
|------------------------------|----------|
| `## Inputs & Failure Modes` (header) | T6 — missing-input clause |
| `dtype={'ReportNumberNew': str` (within a code block) | T8 — CLAUDE.md `dtype=str` rule at load time |

Verification commands (run from `~/.claude/skills/`):

```bash
grep -n "Inputs & Failure Modes" data-validation/SKILL.md   # expect 1 hit
grep -n "dtype={'ReportNumberNew': str" data-validation/SKILL.md   # expect 1 hit
```

If either grep returns no match, the corresponding test regresses. The fix is
to restore the section/line — see `data-validation_MEMORY.md` Iteration 2.

## Future regression coverage to consider

If the skill is later extended to cover Summons / Arrests ID columns, add a
regression check that verifies all named ID columns still appear on the
`dtype={...: str}` list. This is advisory, not blocking.
