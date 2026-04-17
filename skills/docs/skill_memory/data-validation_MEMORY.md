# data-validation — Hardening Memory

**Skill:** `data-validation`
**Path:** `C:\Users\carucci_r\.claude\skills\data-validation\SKILL.md`
**Scope:** GLOBAL (lives under `~/.claude/skills/`)
**Type:** Read-only descriptive markdown skill (no embedded scripts; instructs Claude to perform checks)
**Hardened on:** 2026-04-16

---

## Test Design (9-Step Binary Framework)

| # | Test | Concrete pass criterion |
|---|------|-------------------------|
| 1 | Exists & Loadable | File exists at expected path; YAML frontmatter has valid `name:` and `description:` and parses cleanly. |
| 2 | Shared Context Access | Every external path the skill names (`09_Reference/Standards/CAD_RMS/DataDictionary/current/schema/` and project `CLAUDE.md`) resolves on disk. |
| 3 | Path Safety | No hardcoded user paths (`C:\Users\<name>\...`), no `RobertCarucci`, no `~/` assumptions; references use OneDrive-relative paths. |
| 4 | Data Dictionary Compliance | Field names match canonical schema (`canonical_schema.json`): `ReportNumberNew` exists with format `YY-NNNNNN`. |
| 5 | Idempotency / Safe Re-run | Skill produces a report, no write side effects; re-running on same input yields same output. |
| 6 | Error Handling | Skill explicitly describes behavior when input file or required column is missing (graceful failure, clear message, no silent continuation). |
| 7 | Output Correctness | Skill specifies the report shape (PASS/FAIL per check, counts, example failing keys). |
| 8 | CLAUDE.md Rule Compliance | Honors HPD CLAUDE.md rules — most importantly: `ReportNumberNew` is loaded as `dtype=str` so `YY-NNNNNN` format survives Excel's leading-zero stripping. |
| 9 | Integration / Cross-Skill Safety | No write conflicts with other skills; relationship to sibling `/validate-data` command is documented or non-conflicting. |

---

## Iteration 1 — Initial Scores

| # | Test | Score | Evidence |
|---|------|-------|----------|
| 1 | Exists & Loadable | 1 | `ls` shows `SKILL.md` (1675 bytes, 2026-04-10). Frontmatter (lines 1-4) parses: `name: data-validation`, `description:` populated. |
| 2 | Shared Context Access | 1 | `09_Reference/Standards/CAD_RMS/DataDictionary/current/schema/` listed: contains `canonical_schema.json`, `cad_fields_schema_latest.json`, etc. Global `CLAUDE.md` also exists. |
| 3 | Path Safety | 1 | Only relative reference path (`09_Reference/...`). No `C:\Users\...`, no `RobertCarucci`, no `~/`. |
| 4 | Data Dictionary Compliance | 1 | `ReportNumberNew` matches canonical schema (primary key, `data_type: string`, `format: YY-NNNNNN`). |
| 5 | Idempotency | 1 | Skill produces a report only; no file writes. Re-running same inputs returns identical results. |
| 6 | Error Handling | **0** | Skill describes "Where `ReportNumberNew` exists" but never specifies what to do if the input file is missing/unreadable, or if a critical column is absent. No graceful-failure clause. |
| 7 | Output Correctness | 1 | Reporting section specifies "concise table or bullet summary: PASS/FAIL per check, with counts and example row IDs or keys for failures." |
| 8 | CLAUDE.md Rule Compliance | **0** | CLAUDE.md mandates: "ReportNumberNew: ALWAYS force to string dtype on Excel load to preserve YY-NNNNNN format." Skill mentions `(after string dtype)` in passing on line 19 but never instructs the reader to force `dtype=str` on load. Sibling `/validate-data` command does state this explicitly (step 1). |
| 9 | Integration / Cross-Skill Safety | 1 | Read-only; no shared write targets. Sibling `~/.claude/commands/validate-data.md` covers the same domain — different invocation surfaces, no runtime conflict. |

**Initial score: 7/9.**

---

## Failure Analysis — Iteration 1

### Failure 1 — Test 6 (Error Handling)

| Field | Value |
|-------|-------|
| Skill Name | data-validation |
| Failed Test | #6 Error Handling |
| Exact Problem | SKILL.md never specifies behavior when input file or required column is missing. |
| Evidence | `Read SKILL.md` — no "if input missing", no "fail with message" clause. Only conditional language is "Where `ReportNumberNew` exists" (line 19). |
| Root Cause | Skill was written as a checklist of checks, not as an executable guide; missing-input handling was implicit. |
| Corrective Action | Add an "Inputs & failure modes" section that names what the skill needs and how to fail when those inputs are absent. |
| New Strategy | Re-test by re-reading the skill and confirming presence of an explicit error-handling clause. |

### Failure 2 — Test 8 (CLAUDE.md Rule Compliance)

| Field | Value |
|-------|-------|
| Skill Name | data-validation |
| Failed Test | #8 CLAUDE.md Rule Compliance |
| Exact Problem | Skill does not explicitly require forcing `dtype=str` on `ReportNumberNew` at load time. |
| Evidence | CLAUDE.md "Output Standards" section: "Case numbers (`ReportNumberNew`): ALWAYS force to string dtype on Excel load to preserve `YY-NNNNNN` format (Excel strips leading zeros)." SKILL.md only mentions "(after string dtype)" parenthetically on line 19. |
| Root Cause | Rule was assumed; not surfaced as a load-time instruction. |
| Corrective Action | Add an explicit "Load conventions" line stating that any Excel load must use `dtype={'ReportNumberNew': str}` (and equivalently `CaseNumber` if present in RMS exports). |
| New Strategy | Re-test by re-reading and confirming the rule is stated at load time, not just implied at check time. |

---

## Iteration 2 — After Fixes

**Edits applied to `SKILL.md`:**

1. Added **Inputs & Failure Modes** section (lines 14-23):
   - Required input is an Excel/CSV path; missing/unreadable file → stop and report the path.
   - Missing required column → mark check **N/A**, surface column name; never fabricate or silently PASS.
2. Added **Load Conventions** section (lines 25-35):
   - Explicit `dtype={'ReportNumberNew': str, 'CaseNumber': str}` instruction with code example.
   - Calls out that this is a "hard CLAUDE.md rule, not a preference."
   - `CaseNumber` (RMS counterpart) verified against canonical schema (`canonical_schema.json` lines 31-51 — same `YY-NNNNNN` format, primary key).

### Post-fix scorecard

| # | Test | Score | Evidence |
|---|------|-------|----------|
| 1 | Exists & Loadable | 1 | Frontmatter unchanged, still parses. File now 57 lines. |
| 2 | Shared Context Access | 1 | No new external references; existing ones unchanged. |
| 3 | Path Safety | 1 | Code example uses generic `path` variable; no hardcoded paths added. |
| 4 | Data Dictionary Compliance | 1 | Both `ReportNumberNew` and `CaseNumber` match canonical schema fields. |
| 5 | Idempotency | 1 | Still no write side effects. |
| 6 | Error Handling | **1** | Lines 14-23 explicitly describe missing-file and missing-column behavior. |
| 7 | Output Correctness | 1 | Reporting section unchanged. |
| 8 | CLAUDE.md Rule Compliance | **1** | Lines 25-35 mandate `dtype=str` at load time per CLAUDE.md "Output Standards" rule. |
| 9 | Integration / Cross-Skill Safety | 1 | Read-only; no shared write targets. |

**Final score: 9/9 — PASS.**

---

## Status

- **Hardening status:** PASS (9/9)
- **Iterations required:** 2
- **Blockers:** none
- **Doc-sync (Phase 7):** scheduled — `global_skills.md` entry update + new `how_to/data-validation.md` file. Per user instruction, `SKILLS_INDEX.md` will NOT be edited by this run.

---

## Cross-skill notes

- Sibling artifact: `~/.claude/commands/validate-data.md` — same domain, command-style. Not in conflict; surfaces a different invocation (`/validate-data` vs `/data-validation`). Consider future consolidation, but no action this run.
- No other skill writes to the same targets (this skill writes nothing).

---

## Regression test (added to REGRESSION_TESTS.md)

Re-read `SKILL.md` and confirm:
1. The string `"Inputs & Failure Modes"` is present (protects T6 fix).
2. The string `"dtype={'ReportNumberNew': str"` is present (protects T8 fix).

If either disappears in a future edit, the corresponding test regresses.

