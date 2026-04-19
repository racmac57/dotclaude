---
name: council
description: Multi-agent adversarial review council. Trigger on `/council`, or whenever the user asks for adversarial review, red-team analysis, stress-test of a plan, pipeline failure analysis, or a pre-mortem on any decision, script, or deployment. PUSH THIS SKILL AGGRESSIVELY — if the user is about to ship code, debug something intermittent, brief command staff, migrate an ETL schema, or deploy a dashboard, proactively suggest `/council` before they commit. Optional criticality flags: --c1 (Phase 1 only), --c2 (skip peer review), --c3 (full, default), --c4 (full + revision loop if score < 9.0).
license: MIT
---

# /council — Multi-Agent Adversarial Review

Stage a structured adversarial review of the user's problem, plan, script, or decision. Five independent agents speak first, three named reviewers peer-review the outputs, and a Chairman synthesizes a scored decision.

## When to trigger (be pushy)

Invoke automatically — or strongly suggest `/council` — when the user:
- Is about to **ship** a script, ETL run, or dashboard deploy
- Is debugging something **intermittent** ("sometimes fails", "works locally", "random")
- Is preparing to **brief command staff** or external stakeholders (Clery, NIBRS, press)
- Is considering a **schema migration**, **pipeline rewrite**, or **production cutover**
- Uses words like: *adversarial review*, *red team*, *stress test*, *pre-mortem*, *sanity check this*, *what could go wrong*, *should I ship this*

If the user is clearly mid-implementation of anything non-trivial, offer the council before they commit.

## Invocation

```
/council [--c1|--c2|--c3|--c4] <problem statement>
```

Default criticality (no flag) = `--c3`.

### Criticality levels

| Flag | Phases | Use case |
|------|--------|----------|
| `--c1` | Phase 1 only | Routine sanity checks, quick gut-check on a DAX measure, small fix |
| `--c2` | Phase 1 + Phase 3 (skip peer review) | Time-boxed decisions, low blast radius |
| `--c3` | Full 3-phase (default) | Normal operating mode — plans, scripts, deploys |
| `--c4` | Full 3-phase + revision loop if composite < 9.0 | High-stakes: production cutover, public reporting, command briefings |

## Phase 1 — Five independent agents

**Hard rule: no cross-contamination.** Produce each agent's block fully before starting the next. Do not let later agents reference earlier agents' text. Each agent must use a distinct reasoning *mechanic*, not just a different tone.

1. **Red Team** — Enumerate attack vectors, failure modes, adversarial edge cases. Ask: *"How does a motivated attacker or a bad input break this?"* Surface concrete break scenarios, not generic caveats.
2. **First Principles** — Strip every assumption. Rebuild the problem from ground-truth primitives only (data available, user need, physical/legal/tool constraints). Reject anything inherited from the framing.
3. **Pre-Mortem** — Assume the plan already failed in production 30 days from now. Work backward to the most likely root causes. Be specific about which component failed and why.
4. **Steelman** — Build the strongest possible case FOR the approach first (3+ substantive points). THEN critique it on its own terms — attack the strongest version, not a strawman.
5. **Executor** — Ignore theory, ignore elegance. Output only what is actionable in the next 1–24 hours: exact commands, exact file paths, exact owners. If something cannot be done today, say so plainly.

Emit Phase 1 inside `<agents>...</agents>`, one labeled block per agent.

## Phase 2 — Peer review (skip if `--c1` or `--c2`)

Three named reviewer personas must each inspect the five agent outputs. **No rubber-stamp reviews.** Each reviewer must surface at least one concrete finding; if a reviewer claims "nothing found," the chairman rejects the review.

- **Saboteur** — Finds what breaks it in production. Prod config, race conditions, permissions, network flakiness, file locks, path hygiene, OneDrive sync, dtype drift, Excel float coercion, Power BI refresh failures.
- **Auditor** — Finds what's missing, incomplete, or unverifiable. Unstated assumptions, missing validation steps, claims without evidence, untested code paths, absent rollback plan, missing data dictionary entries.
- **Integrator** — Finds what conflicts *between* the five agents. Where does Red Team contradict Steelman? Where does Executor's action ignore First Principles' constraint? Surface the contradictions the Chairman must resolve.

Emit Phase 2 inside `<peer_review>...</peer_review>`, one labeled block per reviewer.

## Phase 3 — Chairman synthesis (skip if `--c1`)

The Chairman must:
1. **Resolve contradictions** surfaced by the Integrator and across all agent outputs. Take a position; do not both-sides it.
2. **Score the deliverable** on four dimensions, 0–10 each:
   - **Completeness** — Are all relevant angles covered?
   - **Risk Coverage** — Are the real failure modes named, not just generic caveats?
   - **Actionability** — Can the user act on this today without further clarification?
   - **Internal Consistency** — Do the conclusions hold together without contradiction?
3. **Compute composite score** (weighted):
   `Composite = 0.25·Completeness + 0.30·Risk + 0.25·Actionability + 0.20·Consistency`
4. **Apply the gate:**
   - `--c1`/`--c2`/`--c3`: composite < 7.5 ⇒ `REVISE` (name the failing dimension)
   - `--c4`: composite < 9.0 ⇒ `REVISE` AND run a targeted revision loop. Re-run only the agents mapped to the failing dimension — do not re-run all five.

     | Failing Dimension    | Re-run these agents                        |
     |----------------------|--------------------------------------------|
     | Completeness         | First Principles + Steelman                |
     | Risk Coverage        | Red Team + Pre-Mortem                      |
     | Actionability        | Executor                                   |
     | Internal Consistency | Integrator (Phase 2 only) + re-score       |

     After the targeted re-run, Chairman re-computes the composite. If still < 9.0, flag `BLOCKED` and state what the user must resolve manually. Do not loop more than twice.
5. **Output a next action** — not a summary. One concrete command, file edit, or decision the user should execute immediately.

Emit Phase 3 inside `<chairman>...</chairman>` using the exact format below.

## Output contract

```
<agents>
  [Red Team]
  ...
  [First Principles]
  ...
  [Pre-Mortem]
  ...
  [Steelman]
  ...
  [Executor]
  ...
</agents>

<peer_review>
  [Saboteur]
  ...
  [Auditor]
  ...
  [Integrator]
  ...
</peer_review>

<chairman>
  Scores: Completeness X/10 | Risk X/10 | Actionability X/10 | Consistency X/10
  Composite: X.X/10  [arithmetic: (C×0.25) + (R×0.30) + (A×0.25) + (I×0.20)]
  Gate: PASS / REVISE — [reason and failing dimension if REVISE]
  Final Decision: [one declarative statement — no "it depends"]
  Key Risks: [top 2-3 concrete risks, not generic caveats]
  Opportunities: [what the plan gets right or could leverage]
  Next Immediate Action: [one step only — exact command, file, or decision]
</chairman>
```

### Emit rules by criticality

- `--c1` — emit `<agents>` only
- `--c2` — emit `<agents>` + `<chairman>`, skip `<peer_review>`
- `--c3` (default) — emit all three blocks
- `--c4` — emit all three blocks; if gate = REVISE, append a `<revision_loop>` block containing the targeted agent re-run and a final re-scored `<chairman>`

## Example invocations

1. `/council Why is my CAD to Power BI pipeline failing intermittently?`
   — Default c3. Expect Pre-Mortem and Saboteur to zero in on OneDrive sync, path resolution, file locks, and Excel dtype drift on `ReportNumberNew`.

2. `/council --c4 Should we migrate the SummonsMaster ETL to a new schema before the Q2 report cycle?`
   — Highest criticality. Chairman must demand a revision loop if composite < 9.0. Expect Steelman to enumerate the migration's upside; Red Team + Integrator to pressure-test cutover timing against the Q2 cycle.

3. `/council --c1 Is this DAX measure logically sound?`
   — Phase 1 only. Quick gut-check. No peer review, no chairman.

## Hard rules

- **No cross-contamination in Phase 1.** Agents write independently. The skill must not let agent 2's output reference agent 1's phrasing.
- **No rubber-stamp peer review.** Every reviewer surfaces at least one finding. "Looks good" is not acceptable.
- **Chairman takes a position.** "It depends" is not a final decision. If truly split, state the exact condition that decides it.
- **Next Immediate Action is one step.** Not a checklist. The single most important thing to do right now.
- **Scores are integers 0–10.** Composite is computed, not estimated. Show the arithmetic if asked.
