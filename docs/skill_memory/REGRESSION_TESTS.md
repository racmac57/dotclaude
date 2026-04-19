# Regression Tests — `.claude` Global Skills

Captured invariants that must remain true across future edits. Any future `/qa-skill-hardening` run re-asserts these and must not regress.

---

## session-handoff

**Last verified:** 2026-04-19 — all PASS.

### R1 — Frontmatter contract

- YAML parses with **exactly 3 keys**: `name`, `description`, `agents`.
- `name: session-handoff` (unchanged).
- `agents: [main_agent, general_purpose]`.
- Violation check: `python -c "import yaml; print(list(yaml.safe_load(open(...).read().split('---')[1]).keys()))"` must return `['name', 'description', 'agents']`.

### R2 — Badge number pinning

- The token `#261` appears in the file **exactly 2 times**.
- Location 1: task header `**R. A. Carucci (#261)**, Principal Analyst, SSOCC — Hackensack Police Department`.
- Location 2: Part 1 blockquote role spec `**Role:** R. A. Carucci (#261), Principal Analyst, SSOCC, Hackensack PD, NJ`.
- Any third occurrence or any occurrence of `#241`, `#216`, etc. is a regression.

### R3 — Nil-state clauses present

SKILL.md must contain literal strings for every empty-case fallback:

- `Active domains: none mentioned this session.`
- `Tech stack: none mentioned this session.`
- `If no options were rejected this session, write exactly: "No rejected options this session."`
- `If no artifacts were produced or touched this session, write a single line: 'No artifacts this session.'`
- Trivial-conversation short-circuit in PROJECT / TASK.

### R4 — Behavioral directive verbatim set

All seven behavioral directives must appear verbatim, in order, inside the Part 1 blockquote instructions:

1. `Output-first. No preamble or summary before the main answer.`
2. `If asked for code, give code first.`
3. `Fix code first; add a short note only if necessary.`
4. `No filler, no motivational language, no generic best practices.`
5. `No theory-first responses. No pseudocode unless explicitly requested.`
6. `Prefer complete scripts over fragments when enough context exists.`
7. `Act as a rigorous, honest mentor. Challenge flawed assumptions. Do not default to agreement.`

### R5 — Structural invariants

- Exactly one H1 at the top: `# Session handoff generator`.
- `SESSION METADATA` is a mandatory subsection of HANDOFF BODY (never omitted).
- Word-ceiling rule reads `≤900 words for standard sessions. Artifact-heavy sessions may exceed this but must not exceed 1,400 words absolute.`
- Never truncate `ARTIFACTS` or `NEXT BEST ACTION` — regression is any edit that removes this guarantee.

### R6 — NEXT BEST ACTION single-item rule

The text `One item only. No sub-bullets, no secondary suggestions.` must remain in the NEXT BEST ACTION block.

### R7 — CRITICAL CONTEXT category-form rule

The valid-category list must remain: `Data source, Dependency, Constraint, Version, Dead end, Deadline.` Edits that replace with freeform prose are a regression of T8 compliance.
