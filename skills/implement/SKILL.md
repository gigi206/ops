---
name: ops-implement
description: "Use when a plan has been approved and you're ready to build."
---

# /ops-implement — Execute a validated plan

**Read `data/common_instructions.md` before executing this skill.**

<HARD-GATE>
STOP. Every task in the plan MUST go through the per-task pipeline:

  implementer → validation gate → conformity check → per-task quality review → discovery check → task completion record

Do NOT combine multiple plan tasks into a single implementer dispatch. One task = one implementer agent. If you catch yourself writing "Implement Tasks 4+5" in a single agent prompt, STOP — split them.

Post-hoc verification: after all tasks complete, check that count(implementer agents dispatched) >= count(tasks in plan). If fewer implementers were dispatched than tasks exist, you bundled tasks — this is a FAILURE. Fix it by re-running the bundled tasks individually.

**Two review layers** — ceremony depends on mode:

1. **Per-task quality review** (Step 2d) — **Complex mode only**, `[high-risk]` tasks only. Lightweight, fast-iteration. Reviews the cumulative working tree diff right after each task's implementer returns. Catches duplication, naming inconsistencies, and missing extraction opportunities task by task. **Skipped in Normal mode** — the final review handles everything.

2. **Final review** (Step 3) — **Always runs**. Full-diff review: cross-task coherence, security, project-instruction compliance, and architecture. Dispatched ONCE after all tasks complete.

Check the plan header for `**Mode**: Normal` or `**Mode**: Complex` to determine which review layers apply. If no mode is specified, default to Complex (full ceremony).

Do NOT dispatch security-reviewer per task — security-reviewer is for the final pass only (it needs cross-task context to be useful).
</HARD-GATE>

<HARD-GATE-LANGUAGE>
User-facing output uses the user's conversation language. Technical terms (tool/command/skill/agent names, code identifiers, paths) stay in English. Step files are English tooling for YOU, not content for the user — reading English instructions does NOT license English replies. If you catch yourself drafting a reply in English when the user writes in another language, STOP and restart in the user's language. Drift to English mid-session is a FAILURE.
</HARD-GATE-LANGUAGE>

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Prerequisite

A plan must exist (from `/ops-plan` or user-provided). Do NOT implement without a plan.

---

## Workflow — 4 sequential step files

This skill is split into 4 step files you execute one at a time. Each step file contains its own instructions and ends with an explicit hand-off telling you which file to read next. Step 2 is the per-task execution loop — you stay in that file and iterate through all plan tasks before handing off.

```
Step 1 — Load Plan, Verify Task Decomposition, Create Tasks          →  skills/implement/step-01-load-plan.md
Step 2 — Execute Tasks [per-task LOOP, HARD-GATE-PER-TASK-REVIEW]    →  skills/implement/step-02-execute-tasks.md
Step 3 — Final Review [HARD-GATE-CODE-QUALITY]                       →  skills/implement/step-03-final-review.md
Step 4 — Completion [HARD-GATE-FINAL-VALIDATION]                     →  skills/implement/step-04-completion.md
```

---

## How to execute this skill

1. Read `skills/implement/step-01-load-plan.md` **now**.
2. Execute its instructions exactly as written.
3. At the end of each step file you will find a `## ✅ End of Step N` block containing (a) a step-specific completion checklist and (b) a hand-off pointing to the next file. Follow that hand-off.
4. **Do NOT read all 4 files at once.** Read them one at a time, in order, as instructed by each file's hand-off.
5. **Do NOT skip any step.** The chain-of-custody between step files is what makes this skill work reliably across models with varying instruction-following strength.
6. **Do NOT improvise the order.** If you somehow land in a step file without having executed the previous one, STOP and go back to `step-01-load-plan.md`.
7. **Step 2 is a per-task LOOP.** For each task in the plan, execute the per-task pipeline (2a → 2f) before moving to the next task. Do NOT leave `step-02-execute-tasks.md` until ALL plan tasks have been processed — the file's End block contains the LOOP-exit criteria and the hand-off to Step 3.

---

## Red Flags — you are about to break the pipeline

If any of these thoughts cross your mind, STOP — you are about to compromise the implementation pipeline:

| Thought | Reality |
|---------|---------|
| "These 2 tasks are small, I'll bundle them in one implementer" | 1 task = 1 agent. No bundling. The count audit will catch it. |
| "Code quality looks clean, no need to run it before the reviewer" | Hard gate. Quality BEFORE review. Always. |
| "The security-gate says NOT NEEDED but I have a doubt" | Dispatch the security-reviewer. False positives are cheap. |
| "Final validation is redundant, I validated each task" | Tasks interact. Re-validate ALL. Not some — ALL. |
| "The implementer reported DONE, no need to check" | Run the validation command yourself. Trust but verify. |
| "This Complex [high-risk] task doesn't need per-task review" | Per-task review catches drift while context is hot. It is mandatory for [high-risk] tasks in Complex mode. |
| "I'll run per-task review in Normal mode" | Normal mode skips per-task review by design. The final review handles everything. |

---

**→ Read `skills/implement/step-01-load-plan.md` now and begin Step 1.**
