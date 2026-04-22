---
name: session-handoff
description: Use when the user says 'handoff', 'continuity', 'next session', 'wrap up', 'summarize for next chat', or asks for a session primer. Also trigger at explicit end-of-session signals like 'I'm done for today' or 'closing out'.
agents: [main_agent, general_purpose]
---

# Session handoff generator

You are generating a **SESSION HANDOFF DOCUMENT** for **R. A. Carucci (#261)**, Principal Analyst, SSOCC — Hackensack Police Department.

## Task

Review the **entire current conversation** and produce **one** Markdown document with **exactly two parts**, in this order:

1. **OPENING PROMPT** — ready-to-paste context primer for the next chat session  
2. **HANDOFF BODY** — structured state: done, decided, pending, resume point  

The next session pastes the **whole document** as its first message.

---

## Pre-flight (run before drafting)

Collect inputs in this order:

1. **Prior handoff in this conversation?** Scan for an existing handoff (look for `## OPENING PROMPT — PASTE AS FIRST MESSAGE` or a `Handoff version: N` line). If one exists:
   - Bump `Handoff version` to N+1 and populate `Supersedes:` with the prior file name if known.
   - Cover **only the delta since the prior version** — new completions, new decisions, new artifacts, new blockers. Do **not** regenerate unchanged context; reference it in one line ("Prior context unchanged from v1").
2. **Repo state?** If this session touched a git repository (the user ran `git`, you used Edit/Write on tracked files, or the working directory is a repo), capture via Bash:
   - `git -C <repo-root> rev-parse --abbrev-ref HEAD` — current branch
   - `git -C <repo-root> log --oneline -5` — recent commits
   - `git -C <repo-root> status --short` — uncommitted / untracked
   Surface under **ENVIRONMENT SNAPSHOT → Git state**. If not a repo, skip silently.
3. **Date resolution.** Use today's date from CLAUDE.md context (or system date) to populate `Generated:` and the saved file name. Convert relative dates in the conversation ("yesterday", "Thursday") to absolute ISO dates before writing.

---

## Conflict resolution rule (after pre-flight)

Scan the conversation for **contradictory instructions** or **position changes**. When two versions exist, use the **latest** stated position. **Never** silently reconcile: flag lingering contradictions under **OPEN QUESTIONS** with ⚠️. Pay extra attention to **early constraints** that were **walked back later**.

---

## Part 1 — OPENING PROMPT

Format this section with **standard GitHub-flavored Markdown blockquotes**: every line of the quoted block starts with `>`.

Output this exact line as plain Markdown (not inside the blockquote):
## OPENING PROMPT — PASTE AS FIRST MESSAGE
Then immediately begin the blockquote block on the next line with `>`.

Inside the blockquote, include:

- **Role:** R. A. Carucci (#261), Principal Analyst, SSOCC, Hackensack PD, NJ  
- **Active domains:** only what appears **in this conversation** (e.g. CAD, RMS, Python ETL, GIS, Power BI, NIBRS, Clery, ALPR, CompStat). If none were discussed, write exactly: `Active domains: none mentioned this session.`  
- **Tech stack:** only languages, tools, libraries, paths, DB names, report names **explicitly mentioned in this conversation**. If none were mentioned, write exactly: `Tech stack: none mentioned this session.` Do **not** infer defaults from CLAUDE.md, the repo, or general knowledge unless the user pasted that material into **this** chat.  
- **Audience:** if the next session will write for **command staff**, say so (verbosity/formality). If unknown, say so in one short line.  
- **Session-specific deviations** — list **only** behavioral directives that **differed from CLAUDE.md defaults this session**. Examples: "user wanted longer prose for command-staff memo", "pseudocode-first for teaching context", "no git commits without explicit confirmation". If no deviations occurred, write exactly: `Session-specific deviations: none — follow CLAUDE.md defaults.`

  Do **not** restate CLAUDE.md defaults (output-first, mentor approach, no filler, no theory-first, etc.). The next session loads CLAUDE.md automatically; restating them is noise that dilutes the real signal.

---

## Part 2 — HANDOFF BODY

**Omit** any subsection that has nothing to report. **Do not** leave empty headers.

### PROJECT / TASK

One line: what this session was about.

### SESSION METADATA

- Generated: [ISO 8601 datetime — use today's date from context; write `not available` only if truly unknown]
- Handoff version: 1  ← start here; increment if a prior handoff appears earlier in this conversation (see Pre-flight step 1)
- Supersedes: `<filename of prior handoff if known>`  ← omit line entirely on v1

Include this section unconditionally — it is never omitted.

### STATUS

- ✅ **Completed:** …  
- 🔄 **In progress:** … (last known stopping point)  
- ⏳ **Pending:** …  

### KEY DECISIONS

- `Decision → Reason`  

**Rejected:**

- `~~Rejected: [option]~~ → Why it was ruled out`  
If no options were rejected this session, write exactly: "No rejected options this session."

### ARTIFACTS

List **only** files, scripts, queries, schemas, configs, reports, or layers explicitly created, modified, or referenced by name/path **in this conversation**. Do **not** infer artifacts from CLAUDE.md, repo structure, or general knowledge — match the same anti-inference rule used for tech stack. Per item:

- Name + extension  
- Path or destination if stated  
- One-line purpose  
- Persistence: `[saved]` | `[in-session only]` | `[modified]` — note rebuild needs if applicable  

If no artifacts were produced or touched this session, write a single line: 'No artifacts this session.' Do not omit the section header entirely — an explicit nil is more useful than a silent omission.

### CRITICAL CONTEXT

Facts the next session **must** know (sources, quirks, constraints, ordering, versions **only if confirmed this session**).

Format each entry as: Category: detail
Valid categories include: Data source, Dependency, Constraint, Version, Dead end, Deadline. Do not write freeform paragraphs.

### OPEN QUESTIONS / BLOCKERS

One line each. Conflicts ⚠️. Unresolved dependencies here.

### NEXT BEST ACTION

**Single** highest-value first step next session. Be specific: file, function, step, or line if known. If mid-task, state **exactly** where to resume.

One item only. No sub-bullets, no secondary suggestions. If multiple actions are critical, list the others under OPEN QUESTIONS / BLOCKERS.

### ENVIRONMENT SNAPSHOT

Include **only** if this session involved code, data, or config. Otherwise **omit the whole subsection**.

- Python + key libs (versions if stated)  
- Paths / conventions used  
- DB: redact secrets; keep host/DB name if safe  
- CAD/RMS / Power BI / ArcGIS identifiers **if stated**  

---

## PII / credential safety

Before finalizing, scan for:

- Passwords, API keys, connection strings → `[REDACTED]`  
- Case numbers, badge numbers, subject-identifying detail → `[REVIEW BEFORE SHARING]`  
- Internal hosts/IPs → `[REVIEW BEFORE SHARING]`  

Flag rather than silently delete when the next session must know something existed.

---

## Persistence

After drafting, **save the handoff to disk and display it in chat**. Both — the chat copy is for immediate paste; the saved copy is the archival chain.

1. **Path** — canonical OneDrive root, always under `carucci_r`:
   `C:\Users\carucci_r\OneDrive - City of Hackensack\00_dev\handoffs\`
   On the laptop, `carucci_r` is a junction to the real user profile; Windows resolves transparently. Always write to the `carucci_r` path on every host — never substitute the underlying profile name. Create the `handoffs/` subdirectory if missing. Do **not** save outside this directory without asking.
2. **Filename** — `YYYY_MM_DD_<short-topic>_handoff_v<N>.md` where `<N>` matches `Handoff version`. Example: `2026_04_22_cad_etl_resume_handoff_v2.md`. Topic is 1–4 words, lowercase, underscores.
3. **Content** — exact same Markdown shown in chat (both Part 1 and Part 2). No divergence between displayed and saved versions.
4. **After saving**, append a single line below the displayed document:
   `Saved: <full path>`
   so the user sees where it landed without scrolling or re-asking.

If write fails (path missing, permission denied), surface the error and fall back to chat-only with a `Save failed: <reason>` line — never silently drop the archival copy.

---

## Output rules

- Output **only** the Markdown document — no “here is your handoff,” no meta preamble  
- One `---` horizontal rule **between** Part 1 and Part 2  
- Use fenced code blocks for code, paths, queries  
- **≤900 words** for standard sessions. Artifact-heavy sessions may exceed this but must not exceed 1,400 words absolute. If over limit, compress CRITICAL CONTEXT and STATUS prose first; never truncate ARTIFACTS or NEXT BEST ACTION.  
- Write for a **fresh** model with **zero** prior context  
- If the conversation was trivial or empty, say so in **PROJECT / TASK** in one line and omit other sections  
