# Skill Hardening — Master Tracker (`.claude` global skills)

**Repo:** `C:\Users\carucci_r\.claude`
**Scope:** GLOBAL skills installed under `skills/<name>/SKILL.md`
**Maintained by:** `/qa-skill-hardening`

This tracker records the most recent 9-step binary-test result per skill. It is appended-only across runs; each row reflects the latest hardening pass.

---

## Status Table

| Skill | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Score | Status | Last Hardened |
|-------|----|----|----|----|----|----|----|----|----|-------|--------|---------------|
| session-handoff | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 9/9 | PASS | 2026-04-22 |
| chunk-chat | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 9/9 | PASS | 2026-04-19 |

Other global skills (qa-skill-hardening, etl-pipeline, arcgis-pro, etc.) were hardened in previous runs whose memory files live in their owning project trees (Workbook_Redesign_2026, cad_rms_data_quality, etc.). This file tracks only skills hardened against the `.claude` repo itself.

---

## Cross-Skill Dependency Map

| Skill | Reads | Writes | Depends On |
|-------|-------|--------|------------|
| session-handoff | conversation transcript; CLAUDE.md context (today's date); optional `git status / log / branch` | `00_dev\handoffs\<date>_<topic>_handoff_v<N>.md` under canonical `carucci_r` OneDrive path | none (Bash for git capture is optional) |
| chunk-chat | in-memory transcript (stdin) OR user-supplied file path | `KB_Shared\04_output\{timestamp}_{name}\` (4 artifacts) | `scripts\chat_chunker.py` (stdlib-only) |

**No shared write targets between skills.** `session-handoff` writes only to `00_dev/handoffs/`; `chunk-chat` writes only to timestamp-keyed folders under `KB_Shared/04_output/`. Versioned filename (`_v<N>.md`) makes session-handoff re-runs on the same conversation idempotent (overwrites same file); a new conversation that detects a prior handoff bumps to `v2` and writes a separate file.

---

## Shared Lessons Learned

- **Prose-only skills** (SKILL.md as pure instruction to Claude, no executable code) can still earn 9/9 via static analysis. T1 requires valid YAML frontmatter + parseable Markdown body. T3–T9 reduce to content compliance rather than runtime behavior.
- **Nil-state clauses matter for T6.** Every field that can be empty needs an explicit fallback string, otherwise the renderer may fabricate content. Audit every optional field for an explicit empty-case instruction.
- **Badge / identity pinning.** Skills that render identity content (handoffs, exec comms) must specify the exact count and location of identity tokens (badge number, role, unit). This prevents drift across edits and makes regression checks trivial.

---

## Risk Register

| Risk | Skill | Likelihood | Severity | Mitigation |
|---|---|---|---|---|
| Embedded `## OPENING PROMPT` H2 appears as duplicate TOC entry in Markdown viewers | session-handoff | Low | Cosmetic | None — user chose this template format |
| Rejected nil-state rendered as bullet continuation in GFM | session-handoff | Low | Cosmetic | Add blank line before `If no options were rejected…` if TOC hygiene becomes important |
| Handoffs subdir does not exist on first run | session-handoff | Medium | Low | Skill instructs to `Create the handoffs/ subdirectory if missing` (line 152 of SKILL.md). Not test-blocking but verify on first real invocation |
| OneDrive sync conflict if same `_v<N>.md` written from two machines simultaneously | session-handoff | Very Low | Low | Versioned filename + workflow expectation that handoffs are written from one machine at a time. OneDrive will produce a `-machine-name` conflict file rather than overwrite |

None of the above are test-blocking.
