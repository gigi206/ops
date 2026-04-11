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

**Simple-mode edge case**: a brainstorm classified as Simple mode transitions to `/ops-do`, not `/ops-plan` — step-07 should normally never see a Simple-mode context. If you arrived here anyway (user manually invoked `/ops-plan` from a Simple-mode brainstorm, or escalated mid-conversation because the feature turned out more complex than Simple allows), **upgrade the mode to `Normal`** when writing the plan header and state the upgrade in the plan's Approach section with a one-line rationale (e.g., "Brainstorm classified Simple but user escalated to `/ops-plan` — upgraded to Normal ceremony for the plan + implement pipeline"). Do NOT write `**Mode**: Simple` in a plan header — `/ops-implement` only recognizes Normal and Complex, so a Simple header would be treated as "no mode" and fall through to the Complex default, which is the wrong ceremony for what was originally a Simple feature.

**Brainstorm critic verdict propagation (if brainstorm Step 11 ran)**: read the Brainstorm Summary block that was handed off from `/ops-brainstorm` Step 12. If it contains a line matching `**Brainstorm critic verdict**: …` under "Other key decisions", copy that line verbatim into the plan header immediately below `**Mode**: …`. The line may be one of:

- `**Brainstorm critic verdict**: APPROVE (invariant-class check passed)`
- `**Brainstorm critic verdict**: SUGGESTIONS resolved (N accepted, M declined with reason)`
- `**Brainstorm critic verdict**: REJECT — OVERRIDDEN by user` (followed by `**Override reason**: …`)

This line is load-bearing evidence for the plan-stage critic (Step 8 consumes it — see `skills/plan/step-08-critic-review.md` "Required dispatch context"). If the line is missing but the brainstorm Step 11 ran per the Summary context, STOP and re-append it from the conversation history before writing the plan. If Step 11 was skipped (signal-gated skip in Simple/Normal mode), write `**Brainstorm critic verdict**: skipped — no invariant-class signal` instead. If no brainstorm was run at all, omit the line entirely.

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

## Duplication Scan (MANDATORY)

**When to run**: after the Task Decomposition section above is complete (every task has Description + Files + Change + Validation + risk tag) but BEFORE the End-of-Step checklist. Running earlier is pointless — there are no tasks to compare yet. Running later is too late — the checklist verifies the scan actually ran, and the plan is about to ship to the critic.

Run a self-check pass to detect duplicated logic **across the tasks you just wrote**. This is the forcing function that catches the "two interface surfaces with the same handler" pattern at plan-time, instead of letting the critic catch it post-hoc when refactoring is more expensive.

### Why this scan is necessary

The plan-stage critic (`step-08-critic-review.md`) has a "Why not extract" check in Lens 5 that flags single-task duplication ("would extracting a new module be cleaner?"). It does NOT compare two tasks to each other to detect that they add the **same** logic shape in two different files. That comparison is the planner's responsibility — and without an explicit forcing function in this step, planners write each task in isolation and miss inter-task duplication entirely.

### Scan algorithm

For each file your tasks modify or create, list the **new logic** the task adds (function, handler, class, configuration block, validation rule, transformation pipeline). Then compare these new-logic items pairwise across the task list. Mark a duplication when **at least one** of these criteria holds:

- **Same input/output AND same domain concept** — two functions taking the same shape of arguments and returning the same shape of result, modeling the same domain idea (not coincidental shape similarity).
- **Same decision rule applied at two boundaries** — the same authorization check, the same validation rule, the same transformation, applied at two different points in the system (controller + serializer, two interface surfaces, two service entry points).
- **Same reaction to the same event with the same payload shape** — two consumers wiring up the same event with structurally identical handler bodies (e.g., two UI controls, two CLI subcommands, or two service handlers that all update the same resource with a request payload of the same shape).
- **Same external call with the same serialization** — two services calling the same external API with the same request/response handling.
- **Same boilerplate across 3+ tasks** — three or more tasks repeating the same setup/teardown structure.

### What to do for each duplication detected

1. **Create a new task** typed `[high-risk]`: `"Extract <helper-name> to <file path>"`. The helper name should describe the **domain concept**, not the shape (e.g., `useRecordingDelegationManager`, not `useDoublePatchHook`).
2. **Order the extraction task BEFORE its consumers** in the task dependency order (existing rule from "Task Decomposition").
3. **Update each consuming task** so it imports/calls the extracted helper instead of inlining the logic. The Files/Change/Validation fields of the consuming tasks must be rewritten to reflect the new dependency.
4. **Document the extraction** in the plan's Design section (or add a one-liner in the Approach section if the design was minimal): "Helper `<name>` extracted to avoid duplication between `<consumer 1>` and `<consumer 2>`."

### Anti-anti-pattern (avoid over-extraction)

The scan exists to catch **real** duplication, not to manufacture abstractions. Do NOT extract when:

- **Single call site only.** One occurrence of a logic shape is fine. Pre-emptive abstraction "for future use" is YAGNI — leave it inline.
- **Coincidental shape similarity.** Two functions both taking a string and returning a boolean but modeling unrelated concepts (e.g., "is this email valid?" vs "is this user authenticated?") are NOT duplication. Domain matters.
- **Framework-mandated boilerplate.** Boilerplate that the framework requires to be in a specific file (route registration, model declaration, dependency injection wiring) cannot be extracted without fighting the framework.
- **Test fixtures that intentionally repeat.** Test setup that mirrors the production structure on purpose is not duplication.
- **Cross-domain similarity.** If two files share visual shape but model different concepts in different bounded contexts, leave them alone.

A useful sanity check: if you extract a helper and the resulting helper has **zero domain meaning** (you can't give it a name that says what it represents in the problem domain — only a name describing its mechanical shape), you are over-extracting. Revert the extraction and accept the duplication.

### Mode-aware ceremony

The scan is mode-gated, mirroring the brainstorm Step 11 pattern:

- **Simple mode** — **SKIP**. Express path. Plans in Simple mode are short (typically 1-3 tasks), and the duplication risk across so few tasks is low. The plan-stage critic's Lens 5 still runs and serves as the safety net.
- **Normal mode** — **RUN light pass**. Check for **exact-shape duplication only** (two handlers structurally identical, two services with the same wrapping). Skip the deeper "same decision rule at two boundaries" check unless one is obvious from the task descriptions.
- **Complex mode** — **RUN full pass**. All five criteria above. Cross-task comparison is mandatory.

The mode comes from the brainstorm Step 3 classification, propagated via the `**Mode**: …` line in the plan header (set in the "Persist the plan" section above). If no brainstorm was run and the plan defaulted to `**Mode**: Complex`, run the full pass.

### Examples

Concrete duplication patterns the scan should catch (presented as illustrative — adapt to the specific tech stack of the project, do not assume any particular framework):

| Pattern | Symptom in the planned tasks | Resolution |
|---|---|---|
| Two interface-surface handlers with the same mutation | Two UI components / two CLI subcommands / two API endpoints that all PATCH the same resource with payloads of the same shape | Single helper / hook / service consumed by both consumers |
| One authorization rule applied at two boundaries | Permission check in a controller AND in a serializer / authz logic in middleware AND in a view function | Single domain helper consumed by both |
| Two services calling the same external API | Serialization and error handling duplicated across two service classes | Single client wrapper |
| 3+ tasks writing the same setup boilerplate | Three tasks repeating the same init/wiring structure | Shared base module / mixin / factory |
| Two validation rules with the same domain meaning | Two validators checking "is this room name valid" with structurally identical logic | Single validation function consumed by both |

### Output of the scan

Either:
- **No duplication detected** — note "Duplication scan: clean (N tasks compared)" in the plan's Risks section as evidence the scan was actually run (auditable for the critic).
- **Duplication detected** — the new extraction task(s) are in the task list, the consuming tasks are updated, and the plan's Design / Approach section mentions the extraction with a one-line rationale.

A plan with no scan note in Risks is a plan where the scan was skipped (or forgotten). The end-of-step checklist below catches this.

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
- [ ] **Duplication Scan executed** (mode-aware): for each task, you compared its new logic to that of every other task in the plan. The plan's Risks section contains either "Duplication scan: clean (N tasks compared)" OR an extraction task ordered before its consumers with a one-line rationale in Design/Approach. If Simple mode, this checkbox is satisfied automatically (scan skipped — Lens 5 of the plan-stage critic remains the safety net).
- [ ] If project instructions exist: every applicable rule has a dedicated task in the plan.
- [ ] You presented the plan in digestible sections, not a single wall of text.

Mark the task "Plan: write plan" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-08-critic-review.md` now and execute Step 8.**

Do NOT continue without reading that file first.
