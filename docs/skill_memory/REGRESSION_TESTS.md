# Regression Tests — `.claude` Global Skills

Captured invariants that must remain true across future edits. Any future `/qa-skill-hardening` run re-asserts these and must not regress.

---

## session-handoff

**Last verified:** 2026-04-22 — all PASS (post write-capable redesign).
**R4 v1 retired this pass.** Replaced with R4-v2. Added R8–R12 to lock in the new Pre-flight, Persistence, Anti-inference, SESSION METADATA, and forbidden-substring invariants.

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

### R4-v2 — No CLAUDE.md restatement (formerly: 7 verbatim directives)

**R4 v1 retired 2026-04-22.** The verbatim 7-directive block was removed because it duplicated `~/CLAUDE.md` Communication Style + Mentor Approach sections, which the next session loads automatically. Restating them was noise.

**New invariant:** SKILL.md must contain the literal `Session-specific deviations` clause inside the Part 1 blockquote instructions, plus the `none — follow CLAUDE.md defaults` nil-state, plus an explicit rule against restating CLAUDE.md defaults.

Required substrings in SKILL.md:

- `Session-specific deviations` (header for the bullet)
- `Session-specific deviations: none — follow CLAUDE.md defaults.` (nil-state)
- `Do **not** restate CLAUDE.md defaults` (anti-duplication rule)

Forbidden substrings (re-introduction of any of these is a regression — they were deliberately removed):

- `Output-first. No preamble or summary before the main answer.`
- `Act as a rigorous, honest mentor. Challenge flawed assumptions. Do not default to agreement.`
- `No filler, no motivational language, no generic best practices.`

### R5 — Structural invariants

- Exactly one H1 at the top: `# Session handoff generator`.
- `SESSION METADATA` is a mandatory subsection of HANDOFF BODY (never omitted).
- Word-ceiling rule reads `≤900 words for standard sessions. Artifact-heavy sessions may exceed this but must not exceed 1,400 words absolute.`
- Never truncate `ARTIFACTS` or `NEXT BEST ACTION` — regression is any edit that removes this guarantee.

### R6 — NEXT BEST ACTION single-item rule

The text `One item only. No sub-bullets, no secondary suggestions.` must remain in the NEXT BEST ACTION block.

### R7 — CRITICAL CONTEXT category-form rule

The valid-category list must remain: `Data source, Dependency, Constraint, Version, Dead end, Deadline.` Edits that replace with freeform prose are a regression of T8 compliance.

### R8 — Pre-flight section present with 3 ordered steps (added 2026-04-22)

SKILL.md must contain a `## Pre-flight (run before drafting)` section with three numbered steps in this order:

1. **Prior handoff in this conversation?** — scan + version bump + delta-only rule
2. **Repo state?** — git branch / log / status capture instruction
3. **Date resolution.** — convert relative dates to absolute ISO

Required substrings:

- `## Pre-flight (run before drafting)`
- `Prior handoff in this conversation?`
- `Cover **only the delta since the prior version**`
- `git -C <repo-root> rev-parse --abbrev-ref HEAD`
- `git -C <repo-root> log --oneline -5`
- `git -C <repo-root> status --short`
- `Date resolution.`

### R9 — Persistence section present with canonical path + Save failed fallback (added 2026-04-22)

SKILL.md must contain a `## Persistence` section with:

- The canonical OneDrive path under `carucci_r`: `C:\Users\carucci_r\OneDrive - City of Hackensack\00_dev\handoffs\`
- The filename pattern `YYYY_MM_DD_<short-topic>_handoff_v<N>.md`
- A `Saved: <full path>` confirmation rule
- A `Save failed: <reason>` fallback rule

Required substrings:

- `## Persistence`
- `C:\Users\carucci_r\OneDrive - City of Hackensack\00_dev\handoffs\`
- `YYYY_MM_DD_<short-topic>_handoff_v<N>.md`
- `Saved: <full path>`
- `Save failed:`

### R10 — Forbidden substring guard (added 2026-04-22)

The literal substring `RobertCarucci` must **never** appear in SKILL.md. Per `~/CLAUDE.md` Path Resolution rule: "Always use `carucci_r` in Windows user paths. Never use `RobertCarucci` in scripts or configs."

Violation check:

```bash
grep -F "RobertCarucci" skills/session-handoff/SKILL.md
# must produce zero output
```

This was a real bug fixed in this pass — the original Persistence section explained the junction by naming the underlying profile, which is exactly what CLAUDE.md forbids.

### R11 — ARTIFACTS anti-inference guard (added 2026-04-22)

ARTIFACTS section must include a leading sentence forbidding inference, mirroring the existing tech-stack rule.

Required substring:

- `Do **not** infer artifacts from CLAUDE.md, repo structure, or general knowledge`

### R12 — SESSION METADATA defaults (added 2026-04-22)

SESSION METADATA must:

- Default `Generated:` to today's date (no longer `not available` as the lead suggestion)
- Include a `Supersedes:` line for v2+ handoffs

Required substrings:

- `use today's date from context; write` (in the Generated: instruction)
- `Supersedes:` (label)
- `omit line entirely on v1` (rule)

---

## chunk-chat

**Last verified:** 2026-04-19 — all PASS (post-fix for stdin-mode `UnboundLocalError`).

### R1 — Stdin mode: no `src` reference after the branch split

The `process()` function in `chat_chunker.py` binds a local `src = Path(input_path)` only inside the file-path branch. After the branch, all remaining code must reference the branch-neutral variables `src_name`, `src_stem`, `src_display`, `src_size` — never `src.*` directly.

Violation check:
```bash
grep -n "\\bsrc\\." C:/Users/carucci_r/.claude/scripts/chat_chunker.py
```
Must return only the five lines inside the `else:` branch (223–227). Any match outside that block is a regression of the 2026-04-19 fix.

### R2 — Live stdin end-to-end

```python
import subprocess, os, tempfile, json
sandbox = os.path.join(tempfile.gettempdir(), "chunk_chat_regression")
os.makedirs(sandbox, exist_ok=True)
r = subprocess.run(
    [
        "python",
        r"C:\Users\carucci_r\.claude\scripts\chat_chunker.py",
        "-",
        sandbox,
        "--name=regression_probe",
    ],
    input="Short transcript. Two sentences.",
    capture_output=True,
    text=True,
    encoding="utf-8",
)
assert r.returncode == 0, r.stderr
assert "UnboundLocalError" not in (r.stderr or "")
data = json.loads(r.stdout)
assert data["chunks_created"] >= 1
```

### R3 — File-path branch still works

Same invocation without `-` and with a real fixture path must produce a sidecar whose `source_path` is the resolved path (not `<stdin>`) and an origin whose `file_size_bytes` matches the fixture size on disk.

### R4 — SKILL.md Step 3 has both branches

`SKILL.md` must contain the literal `if file_path:` and `else:` split inside the Step 3 Python block. A single-branch subprocess call would silently route file-path invocations to stdin (the bug fixed in the 2026-04-19 review pass).

### R5 — Encoding on the outer subprocess.run call

`encoding="utf-8"` must appear as a top-level keyword argument on the `subprocess.run` call (not buried in the stdin branch's `run_kwargs`), otherwise the file-path branch decodes stdout using the Windows system default (cp1252) and chokes on non-ASCII chunker output.

### R6 — Non-zero exit is surfaced

`SKILL.md` Step 3 must contain the literal check `if result.returncode != 0:` followed by a `raise RuntimeError(...)` that includes `result.stderr`. Silent empty-stdout parsing is a regression.

### R7 — Forbidden-pattern guards

- No `RobertCarucci` substring in `SKILL.md` or `chat_chunker.py`.
- No `python3 chat_chunker` invocation (Windows has no `python3` on PATH).
- No `/tmp` used as an actual path — only referenced inside the path-safety warning in earlier versions; the refactor removed it entirely.
- Canonical `C:\Users\carucci_r\OneDrive - City of Hackensack` substring present in both files.
