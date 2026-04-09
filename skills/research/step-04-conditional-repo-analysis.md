# Step 4 — Conditional Repository Analysis

Mark the task "Research: conditional repo analysis" as `in_progress` now via `TaskUpdate`.

**This step only runs when researcher-doc signaled `Needed: high` for one or more targets in Step 3.** If you are reading this file but no target has `Needed: high`, you have entered the wrong branch — go back to `step-03-synthesize.md` and follow Branch A.

## What to do

For each target in the high list, dispatch a **researcher-repo** agent with:
- The target name and ecosystem (from the `Source Verification Needed` entry)
- The original question/topic
- The synthesized findings from Step 3 (so it knows what was already found and where the gaps are)
- The rationale from researcher-doc explaining what is missing for this target
- Any repo name/URL mentioned in the question or in the agents' findings

**Dispatch all researcher-repo agents in parallel** — all Agent tool_use blocks in a **single message** (see `ops-subagent-rules`). If only one target has `high`, dispatch a single agent.

Each researcher-repo agent will:
1. Locate and clone the relevant external repository
2. Analyze the version matching the project's dependencies
3. Optionally analyze HEAD/main for fixes and new features
4. Return structured findings

**Wait for all agents to return before proceeding.**

---

## ✅ End of Step 4

Before proceeding, verify:
- [ ] You dispatched one `researcher-repo` agent per high-severity target from Step 3.
- [ ] All agents were dispatched in a SINGLE message (parallel).
- [ ] Each dispatch prompt included: target name, ecosystem, original topic, Step 3 synthesis, researcher-doc rationale, and any known repo URL.
- [ ] You waited for all agents to return.

Mark the task "Research: conditional repo analysis" as `completed` via `TaskUpdate`.

**→ Next: read `skills/research/step-05-final-synthesis.md` now and execute Step 5.**

Do NOT continue without reading that file first.
