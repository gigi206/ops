---
name: ops-plan
description: "Use when a task needs design, research, or decomposition before coding."
---

# /ops-plan — Clarify intent, research, and plan

**Read `data/common_instructions.md` before executing this skill.**

<HARD-GATE-0>
STOP. Your VERY FIRST action must be Step 0: Discover project test/build commands. Do NOT ask design questions yet.
</HARD-GATE-0>

<HARD-GATE-1>
After Step 0 is complete, your NEXT message must be a clarity check with the user. NOT a research result. NOT a plan. NOT an agent dispatch.

If your first action after Step 0 is spawning ANY agent (Agent tool) — regardless of type (Explore, researcher-code, researcher-doc, general-purpose, or any other) — you have FAILED this skill. Step 1 is a conversation with the user, not a delegation.

The steps are: 0. Discover commands → 1. Clarify intent WITH the user → 2. Context → 3. Research → ... You cannot skip steps 0 or 1.
</HARD-GATE-1>

## When to use which skill

| Situation                          | Skill            | Why                                       |
|------------------------------------|------------------|-------------------------------------------|
| New feature, change, or task       | `/ops-plan`      | Design before coding                      |
| Plan approved, ready to build      | `/ops-implement` | Execute with validation gates             |
| Bug, error, or unexpected behavior | `/ops-debug`     | Investigate before fixing                 |
| Work is done, ready to commit      | `/ops-ship`      | Commit, PR, capture learnings             |
| Claiming something works           | `/ops-verify`    | Evidence before claims (always active)    |
| Received code review feedback      | `/ops-review`    | Evaluate technically, don't agree blindly |
| Small task, already understood     | `/ops-do`        | Research + execute + verify + review      |
| Trivial fix (typo, rename)         | No skill needed  | Just do it                                |

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Overview

This skill runs before any implementation. It clarifies the user's intent, gathers intelligence via parallel research agents, writes a detailed plan decomposed into tasks, and validates it through an adversarial critic.

---

## Workflow — 10 sequential step files

This skill is split into 10 step files you execute one at a time. Each step file contains its own instructions and ends with an explicit hand-off telling you which file to read next. You never need to read more than one step file at a time.

```
Step 0 — Discover Project Commands [HARD-GATE-0, HARD-GATE-1]  →  skills/plan/step-00-discover-commands.md
Step 1 — Clarify Intent                                        →  skills/plan/step-01-clarify-intent.md
Step 2 — Context Detection                                     →  skills/plan/step-02-context-detection.md
Step 3 — Parallel Research [HARD-GATE-RESEARCH]                →  skills/plan/step-03-parallel-research.md
Step 4 — Research Adequacy Check                               →  skills/plan/step-04-research-adequacy.md
Step 5 — Design Approaches                                     →  skills/plan/step-05-design-approaches.md
Step 6 — Validate Design                                       →  skills/plan/step-06-validate-design.md
Step 7 — Write Plan                                            →  skills/plan/step-07-write-plan.md
Step 8 — Critic Review                                         →  skills/plan/step-08-critic-review.md
Step 9 — User Approval [HARD-GATE-HANDOFF]                     →  skills/plan/step-09-user-approval.md
```

---

## How to execute this skill

1. Read `skills/plan/step-00-discover-commands.md` **now**.
2. Execute its instructions exactly as written.
3. At the end of each step file you will find a `## ✅ End of Step N` block containing: (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) a hand-off pointing to the next file. Follow that hand-off.
4. **Do NOT read all 10 files at once.** Read them one at a time, in order, as instructed by each file's hand-off.
5. **Do NOT skip any step.** The chain-of-custody between step files is what makes this skill work reliably across models with varying instruction-following strength.
6. **Do NOT improvise the order.** If you somehow land in a step file without having executed the previous one, STOP and go back to `step-00-discover-commands.md`.
7. Some steps (4, 8) have **branching hand-offs** — their End block explicitly describes the APPROVE vs REJECT / OK vs GAP branches. Follow the branch that matches your current state.

---

## Red Flags — you are about to skip a step

If any of these thoughts cross your mind, STOP — you are about to bypass a gate:

| Thought | Reality |
|---------|---------|
| "The intent is clear, no need to clarify with the user" | Step 1 is mandatory. Clarify. |
| "I already know this codebase, research is unnecessary" | The research agents find what you don't know to look for. |
| "One research agent is enough for this simple case" | At least 2 agents (researcher-code + researcher-doc), one message. No substitutions. |
| "The critic approved, but I improved the plan after" | Re-dispatch the critic. It must validate the changes. |
| "The user said 'go ahead', that means implement now" | That means approve the plan. Invoke /ops-implement. |
| "The design is obvious, no need to validate section by section" | Section-by-section validation catches misunderstandings early. Do it. |
| "I'll skip the research adequacy table, it's clearly fine" | The table must appear in your output. It's not a mental check. |

---

**→ Read `skills/plan/step-00-discover-commands.md` now and begin Step 0.**
