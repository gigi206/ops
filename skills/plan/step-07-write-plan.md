# Step 7 — Write Plan

Mark the task "Plan: write plan" as `in_progress` now via `TaskUpdate`.

Based on the chosen approach and research results, write a detailed plan with:

1. **Summary**: What we're doing and why (2-3 sentences)
2. **Research findings**: Key insights from the research agents (including researcher-repo if dispatched)
3. **Approach**: The chosen approach and why
4. **Task breakdown**: See task decomposition rules below
5. **Risks**: What could go wrong

## Task Decomposition (MANDATORY)

The plan MUST be decomposed into discrete, ordered tasks. A plan without tasks is NOT a plan — it's a wish.

Each task MUST have ALL of:
- [ ] **Description**: One clear action (not "set up everything")
- **Files**: Exact paths to create or modify
- **Change**: What specifically changes in each file
- **Validation**: The command to verify this task is done

**Rules**:
- **Sizing guide**: Code-level changes: 2-5 minutes. Setup/integration tasks (test framework, CI config, complex resources): up to 30 minutes. No fixed upper limit for complex features — size by coherence, not by clock.
- Each task MUST be independently verifiable via its validation command.
- Tasks MUST be ordered by dependency (prerequisites before dependents, config before consumers, schemas before data).
- A task that touches more than 3 files is probably too big. Consider splitting it.
- **TDD granularity**: When the project has a test framework, each task should follow the TDD micro-cycle: write failing test → run to verify failure → implement minimal code → run to verify pass → commit. The plan should make this explicit in each task's steps when applicable.

## No Placeholders (MANDATORY)

Every task must contain the actual content an implementer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without specifying what to test)
- "Similar to Task N" (repeat the details — the implementer may read tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps when the approach is non-obvious)
- References to types, functions, or methods not defined in any task

If you find yourself writing any of these, stop and fill in the actual content. A plan with placeholders is not a plan — it's a sketch.

## Project Instruction-Driven Tasks (when project instructions exist)

Read the project instruction files (`CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` — whichever exist at the project root) and their subdirectory variants. If none exists, skip this section — there are no project-specific rules to generate tasks from.

If project instructions exist, scan the rules for any action that is required for the type of change being made. If a rule applies, **generate an explicit task for it in the plan**.

Project instruction rules are not just conventions to follow — they are **task generators**. Any rule that says "when doing X, also do Y" means Y must be a task in the plan, not a mental note.

How to apply:
1. Read all project instruction rules
2. For each rule, ask: "does this apply to the current change?"
3. If yes, add a dedicated task with files, change description, and validation command
4. If unsure whether a rule applies, include it — the critic or the user can remove it

**Do NOT treat project instruction rules as "nice to have".** If a rule applies to this change, it MUST have a corresponding task in the plan.

**Gate**: Do NOT proceed to critic review if the plan has no task breakdown or if any task is missing files/change/validation. If project instructions exist and applicable rules have no corresponding tasks, do not proceed either.

**Present the plan in sections** short enough to read and digest — not a wall of text. Let the user absorb each section before the next.

---

## ✅ End of Step 7

Before proceeding, verify:
- [ ] The plan contains all 5 sections: Summary, Research findings, Approach, Task breakdown, Risks.
- [ ] Every task has Description + Files + Change + Validation.
- [ ] Tasks are ordered by dependency (prerequisites before dependents).
- [ ] No placeholders ("TBD", "TODO", "add appropriate X", "similar to Task N", etc.) appear in the plan.
- [ ] If project instructions exist: every applicable rule has a dedicated task in the plan.
- [ ] You presented the plan in digestible sections, not a single wall of text.

Mark the task "Plan: write plan" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-08-critic-review.md` now and execute Step 8.**

Do NOT continue without reading that file first.
