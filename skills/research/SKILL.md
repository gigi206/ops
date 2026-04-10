---
name: ops-research
description: "Autonomous codebase and documentation exploration. Dispatches 3 research agents in parallel, with conditional repository cloning when documentation is insufficient."
---

# /ops-research — Autonomous exploration

**Read `data/common_instructions.md` before executing this skill.**

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Purpose

Explore a topic autonomously without planning or implementation. Use this when you need to understand a codebase area, gather documentation, or investigate history — without committing to a plan or making changes.

---

## Workflow — 6 sequential step files

This skill is split into 6 step files you execute one at a time. Each step file contains its own instructions and ends with an explicit hand-off telling you which file to read next. Steps 4 and 5 are **conditional** — they run only if researcher-doc signals `Source Verification Needed: high` in Step 3.

```
Step 1 — Clarify                               →  skills/research/step-01-clarify.md
Step 2 — Parallel Research [HARD-GATE]         →  skills/research/step-02-parallel-research.md
Step 3 — Synthesize [branching hand-off]       →  skills/research/step-03-synthesize.md
Step 4 — Conditional Repository Analysis       →  skills/research/step-04-conditional-repo-analysis.md
Step 5 — Final Synthesis                       →  skills/research/step-05-final-synthesis.md
Step 6 — Present                               →  skills/research/step-06-present.md
```

---

## How to execute this skill

1. Read `skills/research/step-01-clarify.md` **now**.
2. Execute its instructions exactly as written.
3. At the end of each step file you will find a `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction, and (c) a hand-off pointing to the next file. Follow that hand-off.
4. **Do NOT read all 6 files at once.** Read them one at a time, in order.
5. **Do NOT skip any step.** The chain-of-custody between step files is what makes this skill work reliably across models with varying instruction-following strength.
6. **Step 3 has a branching hand-off** — Branch A (no high-severity source verification gaps → skip to step-06, mark steps 4 and 5 as N/A) or Branch B (high targets → step-04 → step-05 → step-06). Follow the branch that matches researcher-doc's `Source Verification Needed` list.

---

## Constraints

- **Do NOT make changes.** This skill is read-only — no edits, no commits.
- **Do NOT plan.** If the user wants to plan based on research, suggest `/ops-plan`.
- **Cite sources.** Every finding must reference its source (file:line, doc URL, commit hash, agent name).

---

**→ Read `skills/research/step-01-clarify.md` now and begin Step 1.**
