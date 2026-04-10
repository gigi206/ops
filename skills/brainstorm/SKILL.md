---
name: ops-brainstorm
description: "Interactive brainstorming to clarify needs and explore intent before planning. Creates tasks for progress tracking."
---

# /ops-brainstorm — Interactive brainstorming

**Read `data/common_instructions.md` before executing this skill.**

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Purpose

Clarify requirements and explore the user's intent through Socratic dialogue — before committing to a plan. Use this when the problem space is unclear, when the user wants to think through options, or as a standalone step before `/ops-plan`.

---

## Workflow — 11 sequential step files

This skill is split into 11 step files you execute one at a time. Each step file contains its own instructions and ends with an explicit hand-off telling you which file to read next. You never need to read more than one step file at a time.

```
Step 1  — Create task checklist           →  skills/brainstorm/step-01-task-checklist.md
Step 2  — Clarity check                   →  skills/brainstorm/step-02-clarity-check.md
Step 3  — Explore project context         →  skills/brainstorm/step-03-explore-context.md
Step 4  — Assess scope                    →  skills/brainstorm/step-04-assess-scope.md
Step 5  — Visual companion offer          →  skills/brainstorm/step-05-visual-companion.md
Step 6  — Clarifying questions            →  skills/brainstorm/step-06-clarifying-questions.md
Step 7  — Propose approaches [HARD GATE]  →  skills/brainstorm/step-07-architectural-decisions.md
Step 8  — Present design by sections      →  skills/brainstorm/step-08-design-sections.md
Step 9  — YAGNI filter                    →  skills/brainstorm/step-09-yagni-filter.md
Step 10 — Summary                         →  skills/brainstorm/step-10-summary.md
Step 11 — Transition                      →  skills/brainstorm/step-11-transition.md
```

---

## How to execute this skill

1. Read `skills/brainstorm/step-01-task-checklist.md` **now**.
2. Execute its instructions exactly as written.
3. At the end of each step file you will find a `## ✅ End of Step N` block containing: (a) a step-specific completion checklist to verify, (b) a `TaskUpdate` instruction to mark the step completed, and (c) a hand-off pointing to the next file. Follow that hand-off.
4. **Do NOT read all 11 files at once.** Read them one at a time, in order, as instructed by each file's hand-off.
5. **Do NOT skip any step.** The chain-of-custody between step files is what makes this skill work reliably across models with varying instruction-following strength.
6. **Do NOT improvise the order.** If you somehow land in a step file without having executed the previous one, STOP and go back to `step-01-task-checklist.md`.

---

## Global constraints (apply to every step)

- **Do NOT make changes.** This skill is discussion-only — no edits, no commits, no file writes other than progress tracking via `TaskUpdate`.
- **Do NOT write specs or plans.** If the user wants to plan, transition to `/ops-plan` (handled in Step 11).
- **Do NOT dispatch agents.** This is a direct conversation with the user. If research is needed, suggest `/ops-research`.
- **Three modes.** Step 3 classifies the feature as Simple, Normal, or Complex. Simple: skips steps 4-5, 1-2 questions, all dimensions batched, design as single block, YAGNI in summary, → `/ops-do`. Normal: skips steps 4-5, full questions, dimensions one by one, design section by section, → `/ops-plan`. Complex: full flow including scope decomposition and visual companion, extra dimensions, design with documented alternatives, → `/ops-plan`.
- **Track progress visibly.** Every step marks its task `in_progress` at the start and `completed` at the end via `TaskUpdate`. The user should always be able to see where you are in the process.
- **ONE question at a time.** Do NOT overwhelm with multiple questions. Wait for the user's answer before asking the next. If you catch yourself writing multiple question marks (?) or "Question 1:", "Question 2:" in the same message — STOP. Send ONE question alone, wait.

---

**→ Read `skills/brainstorm/step-01-task-checklist.md` now and begin Step 1.**
