# Step 2 — Context Detection

Mark the task "Plan: context detection" as `in_progress` now via `TaskUpdate`.

**Do NOT skip this step.** It takes seconds and informs every agent downstream. If you jump straight to Step 3 (Research) without doing context detection, you have skipped a required step.

## If `/ops-brainstorm` was already run

Brainstorm Step 3 already explored project context (files, docs, recent commits). Skip directory structure exploration and proceed to the End block.

## Explore project structure (when brainstorm was NOT already run)

Read directory structure and key config files to understand conventions. The project instruction file (`CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`) is already loaded by the harness — do not re-read it. If no project instruction file exists, infer conventions from the codebase.

---

## ✅ End of Step 2

Before proceeding, verify:
- [ ] You have a mental model of the directory structure and key config files.
- [ ] You understand the conventions you will need to follow in downstream research and design.

Mark the task "Plan: context detection" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-03-parallel-research.md` now and execute Step 3.**

Do NOT continue without reading that file first.
