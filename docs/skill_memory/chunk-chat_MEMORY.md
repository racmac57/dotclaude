---
name: chunk-chat_MEMORY
description: Per-skill hardening memory for /chunk-chat — 9-step binary scorecard, evidence log, fixes applied
type: qa-skill-hardening
---

# chunk-chat — Hardening Memory

**Skill:** `chunk-chat`
**Scope:** GLOBAL (`C:\Users\carucci_r\.claude\skills\chunk-chat\SKILL.md`)
**Executable dependency:** `C:\Users\carucci_r\.claude\scripts\chat_chunker.py`
**Hardened on:** 2026-04-19
**Framework:** 9-step binary test (PASS=1 / FAIL=0)

---

## Final Scorecard

| # | Test | Result |
|---|------|:------:|
| T1 | Exists & Loadable | 1 |
| T2 | Shared Context Access | 1 |
| T3 | Path Safety | 1 |
| T4 | Data Dictionary Compliance | 1 |
| T5 | Idempotency / Safe Re-run | 1 |
| T6 | Error Handling | 1 |
| T7 | Output Correctness | 1 |
| T8 | CLAUDE.md Rule Compliance | 1 |
| T9 | Integration / Cross-Skill Safety | 1 |
| | **Score** | **9/9 PASS** |

---

## Evidence Log

### T1 — Exists & Loadable
- `SKILL.md` at expected path, 7067 bytes, YAML frontmatter parses (`name=chunk-chat`, `description` length 172).
- `chat_chunker.py` at `C:\Users\carucci_r\.claude\scripts\chat_chunker.py`, `ast.parse` clean.

### T2 — Shared Context Access
- CLAUDE.md readable from project root.
- Canonical script path `C:\Users\carucci_r\.claude\scripts\chat_chunker.py` present in SKILL.md (3 occurrences).
- Default output root `C:\Users\carucci_r\OneDrive - City of Hackensack\KB_Shared\04_output` referenced consistently in both files.

### T3 — Path Safety
- No occurrences of forbidden `RobertCarucci` or `PowerBI_Date` typo.
- `python` (not `python3`) throughout — Windows note explicitly calls this out.
- No `/tmp` as an actual path (it's referenced only in the forbidden-pattern callout before being removed by the refactor).
- Canonical OneDrive root used verbatim in both files.

### T4 — Data Dictionary Compliance
- Skill emits no CAD/RMS/NIBRS field references — not applicable.
- Sidecar schema emits expected keys: `source_type`, `language`, `enrichment_version`, `tags`, `key_terms`, `summary`, `source_hash`, `total_chars`, `total_chunks` — matches Enterprise Chunker consumer contract.

### T5 — Idempotency / Safe Re-run
- Two sequential runs on the same fixture produced two distinct timestamp-keyed folders (`2026_04_19_12_07_21_fixture_session`, `2026_04_19_12_07_22_fixture_session`).
- `chunks_created` identical (3) across runs.
- `source_hash` stable: `3386269f36f3f2be…` in both sidecar files.

### T6 — Error Handling
- No-args invocation → exit 1, prints usage to stderr (starts with `Usage: chat_chunker.py <input_file|-> [output_dir] [--name=BASENAME]`).
- Invalid file path → non-zero exit, Python traceback surfaced to stderr (loud failure, not silent).
- SKILL.md Step 3 subprocess block raises `RuntimeError` with `result.stderr` attached when `returncode != 0`.

### T7 — Output Correctness (bug found + fixed)
- **Bug:** `chat_chunker.py:269` referenced `src.name` inside the transcript header block, but `src` is only defined in the file-path branch. Stdin mode crashed with `UnboundLocalError: cannot access local variable 'src' where it is not associated with a value`.
- **Fix:** replaced `f"**Source:** {src.name}"` with `f"**Source:** {src_name}"` (the branch-neutral variable set in both code paths).
- **Post-fix evidence (stdin mode):** exit 0, 4 artifacts produced — `chunk_00000.txt`, `*_transcript.md`, `*_sidecar.json`, `*.origin.json`; sidecar `source_path` = `<stdin>`.
- **Post-fix evidence (file-path mode):** exit 0, 3 chunks, origin `original_full_path` records real fixture path, `file_size_bytes` = 2431.

### T8 — CLAUDE.md Rule Compliance
- Canonical `carucci_r` user path — ✓
- `python` not `python3` — ✓
- AI Suffix Naming Convention intact (`{Topic_Description}_{AI_Name}` table) — ✓
- No forbidden-pattern strings — ✓

### T9 — Integration / Cross-Skill Safety
- Output folder is `{timestamp}_{basename}` — timestamp-keyed, so two runs can never collide with each other or with any other skill that also writes under `KB_Shared\04_output`.
- No modifications to shared or global files; no race-condition risk.

---

## Iteration History

| Iter | What Changed | Result |
|---|---|---|
| 1 | Static checks T1–T4, T8, T9 | All PASS |
| 1 | Live stdin run for T6/T7 | **FAIL T7** — `UnboundLocalError` at `chat_chunker.py:269` |
| 2 | Replaced `src.name` → `src_name` on line 269 | Syntax re-verified |
| 2 | Re-run stdin mode | T7 PASS (4 artifacts, valid JSON) |
| 2 | File-path branch end-to-end | T7 PASS |
| 2 | Idempotency (T5), error-handling (T6) | All PASS |

Total iterations: 2. One code fix required.

---

## Regression Test (add to REGRESSION_TESTS.md)

**Name:** `chunk-chat_stdin_mode_no_unbound_src`

**What it protects:** stdin-mode invocations of `chat_chunker.py` must not reference `src` (which only exists in the file-path branch).

**Test:**
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

Expected: exit 0, no `UnboundLocalError`, at least one chunk created.

---

## Current Status

**PASS — 9/9** (post-fix). Safe to ship.

## Risks / Follow-ups

- Error message on missing input file is a raw Python traceback. Functional (loud + non-zero exit), but could be wrapped with a `try/except FileNotFoundError` for a cleaner one-line message. Not test-blocking; logged as minor UX polish.
- `how_to/chunk-chat.md` and `global_skills.md` §3 contain stale references to the temp-file workflow removed in the Cursor-permission-prompt refactor. Fixed in Phase 7 of this run.
