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

## Conflict resolution rule (run first)

Before writing anything, scan the conversation for **contradictory instructions** or **position changes**. When two versions exist, use the **latest** stated position. **Never** silently reconcile: flag lingering contradictions under **OPEN QUESTIONS** with ⚠️. Pay extra attention to **early constraints** that were **walked back later**.

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
- **Behavioral directives** (include **verbatim**):

  - Output-first. No preamble or summary before the main answer.  
  - If asked for code, give code first.  
  - Fix code first; add a short note only if necessary.  
  - No filler, no motivational language, no generic best practices.  
  - No theory-first responses. No pseudocode unless explicitly requested.  
  - Prefer complete scripts over fragments when enough context exists.  
  - Act as a rigorous, honest mentor. Challenge flawed assumptions. Do not default to agreement.

---

## Part 2 — HANDOFF BODY

**Omit** any subsection that has nothing to report. **Do not** leave empty headers.

### PROJECT / TASK

One line: what this session was about.

### SESSION METADATA

- Generated: [ISO 8601 datetime if known, otherwise write: not available]
- Handoff version: 1  ← start here; increment only if a prior handoff appears earlier in this conversation

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

Every file, script, query, schema, config, report, or layer **touched or produced**. Per item:

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

## Output rules

- Output **only** the Markdown document — no “here is your handoff,” no meta preamble  
- One `---` horizontal rule **between** Part 1 and Part 2  
- Use fenced code blocks for code, paths, queries  
- **≤900 words** for standard sessions. Artifact-heavy sessions may exceed this but must not exceed 1,400 words absolute. If over limit, compress CRITICAL CONTEXT and STATUS prose first; never truncate ARTIFACTS or NEXT BEST ACTION.  
- Write for a **fresh** model with **zero** prior context  
- If the conversation was trivial or empty, say so in **PROJECT / TASK** in one line and omit other sections  
