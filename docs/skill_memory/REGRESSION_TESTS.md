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
