# Step 7 — Write Plan

Mark the task "Plan: write plan" as `in_progress` now via `TaskUpdate`.

Based on the chosen approach, validated design (from Step 6), and research results, write a unified plan document with:

1. **Summary**: What we're doing and why (2-3 sentences)
2. **Design**: The validated design sections from Step 6 (architecture, components, data flow, error handling, testing strategy — whatever sections were validated)
3. **Research findings**: Key insights from the research agents (including researcher-repo if dispatched)
4. **Approach**: The chosen approach and why
5. **Task breakdown**: See task decomposition rules below
6. **Risks**: What could go wrong

## Persist the plan

Write the plan to `docs/plans/YYYY-MM-DD-<topic>.md`. Do NOT commit — the user decides when to commit. User preferences for file location override the default path.

Set `**Status**: Draft` in the plan header. This status is updated to `**Status**: Approved` after the critic review (Step 8) and user approval (Step 9).

**If brainstorm was run**: include `**Mode**: Normal` or `**Mode**: Complex` in the plan header (from the brainstorm Step 3 classification). This tells `/ops-implement` which ceremony level to apply. If no brainstorm was run, default to `**Mode**: Complex` (full ceremony).

## Task Decomposition (MANDATORY)

The plan MUST be decomposed into discrete, ordered tasks. A plan without tasks is NOT a plan — it's a wish.

Each task MUST have ALL of:
- [ ] **Description**: One clear action (not "set up everything")
- **Files**: Exact paths to create or modify
- **Change**: What specifically changes in each file
- **Validation**: The command to verify this task is done

**Rules**:
- **Risk tags** (MANDATORY): Tag each task with `[low-risk]` or `[high-risk]` in the task description. This determines per-task ceremony during `/ops-implement`:
  - **`[low-risk]`** — Mechanical changes with no design judgment: config values, i18n strings, type definitions, file renames, feature flag toggles. Implementation: dispatch + validation + completion record only (per-task code review and TDD skipped).
  - **`[high-risk]`** — Structural changes with design judgment: business logic, permissions, refactors, new modules, API changes. Implementation: full pipeline including per-task code review and TDD.
  - **Always `[high-risk]`** regardless of apparent simplicity: authentication/authorization logic, permission checks, data deletion or migration, schema changes, encryption/TLS configuration, CI/CD pipeline modifications, secret or credential handling. These categories carry outsized blast radius even when the diff is small.
  - Default if not tagged: `[high-risk]`.
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

**Conflict with brainstorm decisions**: If a brainstorm decision explicitly contradicts a project instruction rule (e.g., brainstorm decided "no e2e tests" but project instructions require e2e for all features), flag the conflict to the user: "Brainstorm decision [X] conflicts with project rule [Y]. Which takes priority?" Do NOT silently override either one. The user's explicit choice resolves the conflict.

**Gate**: Do NOT proceed to critic review if the plan has no task breakdown or if any task is missing files/change/validation. If project instructions exist and applicable rules have no corresponding tasks, do not proceed either.

**Present the plan in sections** short enough to read and digest — not a wall of text. Let the user absorb each section before the next.

---

## ✅ End of Step 7

Before proceeding, verify:
- [ ] The plan contains all 6 sections: Summary, Design, Research findings, Approach, Task breakdown, Risks.
- [ ] The plan is written to `docs/plans/YYYY-MM-DD-<topic>.md` (or a user-specified path) with `**Status**: Draft`.
- [ ] Every task has Description + Files + Change + Validation.
- [ ] Tasks are ordered by dependency (prerequisites before dependents).
- [ ] No placeholders ("TBD", "TODO", "add appropriate X", "similar to Task N", etc.) appear in the plan.
- [ ] If project instructions exist: every applicable rule has a dedicated task in the plan.
- [ ] You presented the plan in digestible sections, not a single wall of text.

Mark the task "Plan: write plan" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-08-critic-review.md` now and execute Step 8.**

Do NOT continue without reading that file first.
