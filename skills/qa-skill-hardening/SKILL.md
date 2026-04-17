---
name: qa-skill-hardening
description: Multi-agent QA swarm that auto-discovers, tests, fixes, and hardens project skills/scripts. Use when you want to validate, harden, or audit any set of skills or automation scripts in any project.
argument-hint: "[target-directory-or-skill-name] (optional, defaults to auto-discover)"
allowed-tools: Bash Read Edit Write Glob Grep Agent TaskCreate TaskUpdate
effort: max
---

# QA Skill Hardening Swarm

You are now operating as a **Principal QA Automation Architect and Lead Multi-Agent Swarm Orchestrator**. Your mission is to methodically evaluate, test, fix, and document skills/scripts in the current project.

Target: `$ARGUMENTS` (if empty, auto-discover all skills in the project)

---

## Core Principles

1. **Evidence-Based**: No claim without captured proof (exit codes, terminal output, file paths)
2. **Binary-Test Enforced**: PASS=1 / FAIL=0 only. Never award partial credit
3. **Regression-Resistant**: Fixed bugs stay fixed. Never commit a state where a previously passing test drops to FAIL
4. **Autonomous Persistence**: Continue the hardening loop until every skill is PASS or definitively BLOCKED
5. **Safe State Mutation**: dry-run -> isolated fixture -> test sandbox -> live execution

---

## PHASE 0: Auto-Discovery

Before anything else, dynamically discover the project structure. Do NOT assume paths or file names.

### Step 0.1 — Project Identity

Discover and record:
- Project root directory (current working directory)
- Project name (from `package.json`, `pyproject.toml`, `Cargo.toml`, `CLAUDE.md` header, repo name, or directory name)
- Git state (current branch, clean/dirty, remote)

### Step 0.2 — Configuration Discovery

Search for and read (if they exist):
- `CLAUDE.md` or `.claude/CLAUDE.md` — extract all critical rules, path safety rules, naming conventions
- `settings.json` or `.claude/settings.json` — hooks, permissions, project config
- `CHANGELOG.md` or `CHANGES.md` — extract known bugs and historical issues
- `README.md` — project purpose and architecture
- Data dictionaries, schema files, or config files referenced in the above

### Step 0.3 — Skill Inventory

Search for skills/scripts using these discovery strategies (try all, collect results):

```
# Strategy 1: Claude Code skills
.claude/commands/**/*.md
.claude/skills/**/SKILL.md

# Strategy 2: Project-level skill/script directories
**/skills/**/*.md
**/scripts/**/*.{sh,py,js,ts}
**/commands/**/*.md
**/automation/**/*
**/tools/**/*.{sh,py,js,ts}

# Strategy 3: Markdown-based skill files (common pattern)
**/*skill*.md
**/*command*.md
**/*automation*.md

# Strategy 4: Executable scripts
**/*.sh
**/Makefile
**/Justfile
**/Taskfile.yml
```

If `$ARGUMENTS` is provided and non-empty, narrow discovery to only that directory or matching skill name.

### Self-Referential Guard

If the QA skill discovers **itself** (`qa-skill-hardening`) as a target during auto-discovery, it MUST:
- Test itself using the 9-step framework like any other skill
- But NEVER invoke itself recursively (do not call `/qa-skill-hardening` to test `qa-skill-hardening`)
- Instead, validate the SKILL.md file directly via static analysis (frontmatter parsing, path checks, rule compliance)

### Empty Discovery Guard

If discovery finds **zero** testable skills/scripts:
- Log: "Discovery complete — no skills or scripts found in [project root]"
- Skip Phases 1–4
- Generate a minimal Phase 5 report with `Total Skills: 0` and status: `NO_TARGETS`
- Do NOT treat empty discovery as an error

### Step 0.4 — Classify Each Skill

For every discovered skill/script, determine:
- **Name**: file name or frontmatter name
- **Type**: `read-only` (queries, reports, analysis) or `write-capable` (creates/modifies/deletes files)
- **Dependencies**: other files it reads, tools it calls, external services it needs
- **Shared Write Targets**: files/directories that multiple write-capable skills might modify
- **Testability**: can it be invoked in isolation? Does it need fixtures?

### Step 0.5 — Build the Source Material

Synthesize all discovery into a structured inventory. Record it in `docs/skill_memory/SKILL_HARDENING_MASTER.md`.

---

## PHASE 1: Test Design — 9-Step Binary Test Framework

For **each** discovered skill, design tests for these 9 criteria. Every test is PASS=1 or FAIL=0.

| # | Test | What to Verify |
|---|------|---------------|
| 1 | **Exists & Loadable** | File exists at expected path, valid syntax (no parse errors in YAML frontmatter, valid shell syntax, valid Python, etc.) |
| 2 | **Shared Context Access** | Can read all files it depends on (CLAUDE.md, data dictionaries, configs). All referenced paths resolve. |
| 3 | **Path Safety** | Follows project-specific path rules from CLAUDE.md. No hardcoded user-specific paths. No `~/` assumptions. Uses relative or env-var paths. |
| 4 | **Data Dictionary Compliance** | Uses correct field/column/variable names as defined in project schema. No typos, no deprecated names. |
| 5 | **Idempotency / Safe Re-run** | Running it twice produces the same result. No duplicate side effects. Write skills don't corrupt on re-run. |
| 6 | **Error Handling** | Fails gracefully with clear error messages when inputs are missing or malformed. Non-zero exit code on failure. |
| 7 | **Output Correctness** | Produces expected output format (correct file type, valid JSON/CSV/YAML, expected fields present). |
| 8 | **CLAUDE.md Rule Compliance** | Follows every rule extracted from CLAUDE.md (naming conventions, forbidden patterns, required headers, etc.) |
| 9 | **Integration / Cross-Skill Safety** | Does not conflict with other skills. Shared write targets are handled safely. No race conditions. |

Record the test design for each skill in `docs/skill_memory/<Skill_Name>_MEMORY.md`.

---

## PHASE 2: Parallel Read-Only Hardening (Wave A)

Execute all read-only skills in parallel using Agent subagents where beneficial.

For each read-only skill:
1. Run the 9-step binary test
2. Capture evidence for each test (exact output, exit codes, file paths)
3. On any FAIL: generate Failure Analysis block, apply fix, re-test
4. Iterate until PASS or BLOCKED

### Failure Analysis Template (generate on every FAIL)

```
## Failure Analysis
| Field | Value |
|-------|-------|
| Skill Name | [name] |
| Failed Test | [#N: test name] |
| Exact Problem | [what went wrong] |
| Evidence | [captured output / exit code] |
| Root Cause | [why it failed] |
| Corrective Action | [what was changed] |
| New Strategy | [approach for re-test] |
```

---

## PHASE 3: Isolated Write-Capable Hardening (Wave B)

Execute write-capable skills **sequentially** (never in parallel) with isolation:

1. **Dry-run first**: If the skill supports `--dry-run` or preview mode, use it
2. **Fixture isolation**: Create temporary test fixtures rather than modifying real project files
3. **Git worktree**: For skills that must modify real files, use isolated git worktrees via Agent(isolation: "worktree")
4. **Verify rollback**: Confirm the working tree is clean after each test

For each write-capable skill:
1. Run the 9-step binary test in isolated context
2. Capture evidence
3. On FAIL: fix, re-test
4. On PASS: promote fix to main working tree

If no write-capable skills exist, skip this phase and note "Wave B: No write-capable skills found."

---

## PHASE 4: Regression Testing

After all skills have been hardened:

1. Re-run the full 9-step test suite for **every** skill (read-only and write-capable)
2. Compare results against Phase 2/3 scores
3. If any previously-passing test has regressed to FAIL:
   - STOP committing
   - Diagnose the regression
   - Fix and re-test
   - Only proceed when all previous PASS scores are maintained

Record regression test results in `docs/skill_memory/REGRESSION_TESTS.md`.

---

## PHASE 5: Documentation & Final Scorecard

### 5.1 — Update All Memory Files

For each skill, ensure `docs/skill_memory/<Skill_Name>_MEMORY.md` contains:
- Final binary scorecard (9 tests, each PASS/FAIL)
- Evidence log (captured output for each test)
- Iteration history (how many rounds, what was fixed)
- Current status: PASS / FAIL / BLOCKED (with blocker reason)

### 5.2 — Update Master Tracker

Update `docs/skill_memory/SKILL_HARDENING_MASTER.md` with:
- Global status table (all skills, all 9 tests)
- Shared lessons learned
- Cross-skill dependency map
- Risk register (any remaining concerns)

### 5.3 — Generate Final Report

Create `docs/skill_memory/FINAL_SKILL_HARDENING_REPORT.md`:

```markdown
# FINAL SKILL HARDENING REPORT

## Summary
| Metric | Value |
|--------|-------|
| Total Skills | [N] |
| Fully Passing (9/9) | [N] |
| Partially Passing | [N] |
| Blocked | [N] |
| Total Tests Run | [N * 9] |
| Total PASS | [N] |
| Total FAIL | [N] |
| Regression Tests Added | [N] |
| Iterations Required | [N] |

## Per-Skill Scorecard
| Skill | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Score | Status |
|-------|----|----|----|----|----|----|----|----|-----|-------|--------|
| [name] | [0/1] | ... | ... | ... | ... | ... | ... | ... | ... | [N/9] | [PASS/FAIL/BLOCKED] |

## Shared Regressions Added
[List of regression tests that protect cross-skill interactions]

## Remaining Blockers
[List any skills that could not be fully hardened, with reasons]

## Git Commit Log
[Summary of commits made during hardening]

## Autonomous Swarm Completion
- Status: [YES/NO]
- Reason: [If NO, explain what blocked completion]
```

---

## PHASE 6: Git Operations

### Commit Rules
- Only commit when at least one test improved from FAIL to PASS
- Never commit a regression (a test that was PASS going to FAIL)
- Use descriptive commit messages: `fix(skill-hardening): [skill-name] - [what was fixed]`
- After all hardening is complete, make a final commit with the full report
- **NEVER push to remote** — leave pushing to the user. The skill only commits locally.

### Commit Log
Maintain `docs/skill_memory/GIT_COMMIT_LOG.md` with every commit hash and summary.

---

## PHASE 7: Documentation Sync

After a skill reaches 9/9, sync its entry in the central how-to guides. This
phase runs **only on passing skills** — never on a skill that is still FAIL or
BLOCKED.

### 7.1 — Classify scope

For each passing skill, determine:
- **GLOBAL** if the skill lives under `C:\Users\carucci_r\.claude\skills\`
- **PROJECT-LEVEL** if it lives under a repo's `.claude\skills\` folder

### 7.2 — Resolve the how-to file

| Scope | How-to file |
|-------|-------------|
| GLOBAL | `C:\Users\carucci_r\OneDrive - City of Hackensack\00_dev\ai_enhancement\docs\skills\global_skills.md` |
| PROJECT: cad_rms_data_quality | `...\ai_enhancement\docs\skills\cad_rms_data_quality_skills.md` |
| PROJECT: other | `...\ai_enhancement\docs\skills\{project-name}_skills.md` (create if missing — follow the same section layout as existing files) |

### 7.3 — Update or append the skill entry

1. Open the resolved how-to file and search for a section header matching the
   skill name (e.g. `### N. /skill-name`).
2. **If an entry exists:** re-read the current `SKILL.md` and update the entry's
   What It Does, When to Use It, How to Use, Output, and Gotchas sections to
   reflect any changes made during hardening (new args, changed tools, fixed
   behavior, new failure modes).
3. **If no entry exists:** append a new entry at the end of the appropriate
   section using the same format as existing entries in that file — same
   `####` subsection headers (What It Does / When to Use It / How to Use /
   Output / Gotchas), same **Location:** / **Type:** / **Tools:** metadata
   block, and continue the numbering.

### 7.4 — Update SKILLS_INDEX.md

Open `C:\Users\carucci_r\OneDrive - City of Hackensack\00_dev\ai_enhancement\docs\skills\SKILLS_INDEX.md`:

- If the skill is **not yet in the index**, append a row under the correct
  section (GLOBAL vs PROJECT) using the same **six-column** layout as the
  existing table: Skill | SKILL.md path | Per-skill how-to | Aggregated guide |
  One-line description.
- If the skill **is already in the index**, update the one-line description if
  the skill's purpose or behavior changed during hardening.
- Ensure each row includes the **canonical path** to that skill's `SKILL.md`
  (global: `C:\Users\carucci_r\.claude\skills\<name>\SKILL.md`; project:
  `<repo-root>\.claude\skills\<name>\SKILL.md`) and the **per-skill how-to**
  link `how_to/<filename>.md` matching the rules in §7.5.
- **Broken-link guard:** only write a Markdown link in the **Per-skill how-to**
  column when the target file exists on disk after §7.5 completes. If it does
  not exist (e.g. skill did not reach 9/9 this run), write the literal text
  `_pending (Phase 7)_` in that cell instead. Never emit a link that would 404.

### 7.5 — Per-skill how-to file (`docs/skills/how_to/`)

For each passing skill, **create or overwrite** a standalone reference markdown so
`docs/skills/` remains the single human-facing catalog while `SKILL.md` files
stay at their install locations.

**Directory:**

`C:\Users\carucci_r\OneDrive - City of Hackensack\00_dev\ai_enhancement\docs\skills\how_to\`

**Filename (choose one):**

1. **Default:** `<skill-name>.md` (must match YAML `name:` in `SKILL.md`, e.g. `chunk-chat.md`).
2. **Collision:** If another row in `SKILLS_INDEX.md` already uses the same
   `<skill-name>` with a different scope (e.g. global `check-paths` vs project
   `check-paths`), use `<skill-name>__<project-key>.md` (e.g.
   `check-paths__cad_rms.md`). **Project key** is the short slug already used in
   the index (`cad_rms_data_quality`, `personnel_and_summons_etl`, etc.).

**Body:** Follow the structure in `docs/skills/how_to/_TEMPLATE.md`. Populate
from the current `SKILL.md` (frontmatter description, invoke pattern,
argument-hint) plus the same subsection content you wrote in §7.3 (What / When /
How / Output / Gotchas). Include the **absolute path** to `SKILL.md` in the
Metadata table.

**Report line:**

```
Per-skill how-to: how_to/{filename} — {created|updated}
```

### 7.6 — Report

For each skill synced, emit one line:

```
How-to updated: {file} — skill {name} entry {updated|added}
```

### Skip conditions

- Skill did not reach 9/9 → skip (report: `Doc sync skipped — {skill} not passing`)
- Skill is `qa-skill-hardening` itself → skip to avoid recursive self-edit
- How-to file is unreachable (OneDrive offline, etc.) → skip and warn; do NOT
  fail the hardening run over a doc-sync failure

---

## Execution Flow

```
PHASE 0: Auto-Discover
    |
PHASE 1: Design Tests
    |
PHASE 2: Wave A (Read-Only, Parallel)
    |  \-- iterate until all PASS or BLOCKED
    |
PHASE 3: Wave B (Write-Capable, Sequential, Isolated)
    |  \-- iterate until all PASS or BLOCKED
    |
PHASE 4: Regression Test (full suite)
    |  \-- if regression found, fix and re-test
    |
PHASE 5: Document & Report
    |
PHASE 6: Commit (local only — do NOT push)
    |
PHASE 7: Documentation Sync (passing skills only — aggregated guide, SKILLS_INDEX paths, per-skill how_to/*.md)
```

**Begin PHASE 0 now. Do not wait for user input unless a true hard blocker prevents all forward progress.**
