---
name: ops-implement
description: "Use when a plan has been approved and you're ready to build."
---

# /ops-implement — Execute a validated plan

<HARD-GATE>
STOP. Every task in the plan MUST go through the per-task pipeline:

  implementer → validation gate → conformity check → per-task quality review → discovery check → task completion record

Do NOT combine multiple plan tasks into a single implementer dispatch. One task = one implementer agent. If you catch yourself writing "Implement Tasks 4+5" in a single agent prompt, STOP — split them.

Post-hoc verification: after all tasks complete, check that count(implementer agents dispatched) >= count(tasks in plan). If fewer implementers were dispatched than tasks exist, you bundled tasks — this is a FAILURE. Fix it by re-running the bundled tasks individually.

**Two distinct review layers** — both are mandatory and serve different purposes:

1. **Per-task quality review** (Step 2d, NEW) — Lightweight, fast-iteration. Reviews the cumulative working tree state captured by `scripts/ops-capture-task-state.sh` right after each task's implementer returns, with the dispatch prompt scoping findings to that task's contributions. Catches duplication, missing extraction opportunities, and Lens-5-style architectural drift task by task. Inspired by superpowers' subagent-driven-development pattern (adapted to ops's "no commit per task" convention — the reviewer sees the cumulative state and uses prior tasks as context).

2. **Final review** (Step 4) — Heavy, full-diff. Reviews cross-task coherence, security, project-instruction compliance, and architecture as a whole. Dispatched ONCE after all tasks complete.

Skipping the per-task review means quality issues compound across tasks and only get caught in the final review, when the context is colder and fixes are more expensive. Skipping the final review means cross-task issues (inconsistent naming, broken integration, security gaps) slip through. Both are needed.

The per-task review uses a **focused** code-reviewer dispatch (cumulative working tree diff captured by `scripts/ops-capture-task-state.sh`, with the dispatch prompt scoping findings to the task being reviewed). The final review uses a **full-context** code-reviewer dispatch (complete diff + spec, no scoping). Different prompts, but the underlying captured state is the same — the difference is what the reviewer is told to focus on.

Do NOT dispatch security-reviewer per task — security-reviewer is for the final pass only (it needs cross-task context to be useful).
</HARD-GATE>

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Prerequisite

A plan must exist (from `/ops-plan` or user-provided). Do NOT implement without a plan.

## Workflow

```
For each task in plan:
  1. Implementer agent → 2. Validation gate → 3. Conformity check → 4. Per-task quality review → 5. Discovery check → 6. Task completion record
  If per-task review finds Critical/Important → fix loop with fresh implementer (max 3 iterations, subagents are stateless)
  If discovery → Pause, present options to user
  If 3+ consecutive failures → Diagnose with researcher-code, present options to user
After all tasks:
  7. Pre-review audit → 8. Final review (code-reviewer + security-reviewer on complete diff)
```

---

## Step 1: Load Plan, Verify Task Decomposition, and Create Tasks

Read the plan from the conversation context or from the file the user specifies.

**Gate**: Verify the plan has a proper task breakdown:
- [ ] Plan contains an ordered list of discrete tasks
- [ ] Each task has: description, files, change details, and validation command
- [ ] Tasks are ordered by dependency

**If the plan has no task breakdown or tasks are incomplete**: STOP. Do NOT implement. Tell the user to run `/ops-plan` first or to decompose the plan into tasks before proceeding.

### Register tasks

After verifying the plan, create a task entry for each plan task, set to pending.

This ensures task progress survives context compaction and is visible throughout the session.

---

## Step 2: Execute Tasks

For each task in the plan, in order:

**Before starting a task**, mark it as in_progress.

### 2a. Dispatch Implementer Agent

**One task per agent.** Each implementer agent receives exactly ONE task from the plan. Do NOT bundle multiple tasks into a single agent prompt — even if they seem related or touch similar files.

**Parallelization rules:**
- Tasks with no dependency between them MAY be dispatched in parallel — all Agent tool_use blocks in a **single message** (see `ops-subagent-rules`).
- But each parallel task MUST independently complete steps 2b–2f before being marked completed.
- If Task B depends on files created/modified by Task A, Task B MUST wait until Task A's full pipeline is complete.
- Maximum 3 implementer agents running in parallel — more than this makes conformity checks unmanageable.

### Model Selection

Use the least powerful model that can handle each task to conserve cost and increase speed:

- **Mechanical tasks** (isolated functions, clear specs, 1-2 files, pure config): use `model: "sonnet"` or `model: "haiku"`
- **Integration tasks** (multi-file coordination, pattern matching, debugging): use `model: "sonnet"`
- **Architecture/judgment tasks** (design decisions, broad codebase understanding, complex refactoring): use the default model (most capable)

**Task complexity signals:**
- Touches 1-2 files with complete spec and code shown → fast model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

Spawn the **implementer** agent with:
- The specific task to implement (not the whole plan)
- The relevant context: overall approach + this task's details
- The files to read/modify
- The validation command for this task
- The appropriate `model` parameter based on task complexity

The implementer will automatically detect if the project has a test framework. If tests are relevant to the task, it enforces TDD (Red/Green/Refactor): write a failing test first, then minimal code to pass, then refactor. If the task is pure config/data with no applicable tests, it implements directly.

The implementer reports one of:
- **DONE**: Task completed, validation passed (includes output)
- **DONE_WITH_CONCERNS**: Completed but something seems off (explains what)
- **BLOCKED**: Cannot proceed (explains what's missing)
- **FAILED**: Attempted but validation failed (includes error output)

**Handling DONE_WITH_CONCERNS:**
- Read the concern carefully
- If the concern is about the current task: evaluate whether it's a real problem or an over-cautious warning. If real, have the implementer fix it before proceeding.
- If the concern is about the plan or a future task: note it for later, proceed with the current task.
- Do NOT ignore concerns silently — acknowledge them in the task completion record (Step 2f) and again in the final completion summary (Step 5).

### 2b. Validation Gate

After the implementer reports DONE, **verify with evidence**. YOU run validation commands fresh — do NOT trust the implementer's report that "tests pass."

| Type          | Example Commands                                                          |
|---------------|---------------------------------------------------------------------------|
| Syntax check  | Linter for the file type (e.g., `eslint`, `pylint`, `rubocop`)            |
| Build/compile | Build tool for the project (e.g., `make`, `npm run build`, `cargo check`) |
| Dry-run       | Validate without applying (e.g., `--dry-run`, `--check`, `--validate`)    |
| Tests         | Run relevant test suite (e.g., `npm test`, `pytest`, `go test`)           |
| Shell scripts | `bash -n <file>`, `shellcheck <file>`                                     |
| Custom        | Whatever the task's validation command specifies                          |

Do NOT mark a task as complete without running validation. No "it should work" — show the output. If a command cannot be run (e.g., requires Docker), state this as a validation gap explicitly.

### 2c. Conformity Check

After validation passes, verify by checking the actual diff — not as a mental note:

- [ ] Change matches the plan's task description
- [ ] No unrelated changes (files touched match the plan's "Files" list)
- [ ] No security anti-patterns: hardcoded secrets, `--insecure`, `skip_tls_verify`, disabled TLS
- [ ] Existing code conventions preserved (indentation, naming, structure)

If conformity fails, have the implementer correct the issue before proceeding.

### 2d. Per-task Quality Review (MANDATORY — lightweight, fast iteration)

<HARD-GATE-PER-TASK-REVIEW>
After conformity passes and BEFORE the discovery check, you MUST dispatch a **focused** code-reviewer agent. This is the per-task quality gate. Skipping it means architectural drift compounds across tasks and only gets caught in Step 4, when the context is cold and fixes are expensive.

This review is intentionally lightweight and scoped to ONE task. It is NOT the final review (which happens in Step 4 on the full diff with security-reviewer).
</HARD-GATE-PER-TASK-REVIEW>

**What to capture and pass to the reviewer**: the cumulative working tree state since the start of `/ops-implement`. This includes BOTH tracked file modifications AND untracked new files — capturing only `git diff HEAD` would silently hide new-file tasks from the reviewer (because `git diff HEAD` does not show untracked files), and most tasks create new files. The capture is encapsulated in a script so the logic is testable and reusable.

**Use the helper script**: `scripts/ops-capture-task-state.sh` (no arguments, must be run from inside a git repository). It outputs a single text blob:

1. The output of `git diff HEAD` (modifications to files that existed at the start of `/ops-implement`)
2. For each untracked new file (from `git ls-files --others --exclude-standard`): a `=== NEW FILE: <path> ===` marker followed by the file content. Binary files are noted but their content is omitted.

The script is read-only (no `git add`, no `git stash`, no temporary index, no `git reset` — no side effects on the working tree or the index). It has been tested empirically against clean trees, modified-only tasks, new-file-only tasks, mixed scenarios, and binary files. Run it and pass its stdout directly inline to the code-reviewer dispatch prompt.

Why a script and not inline commands: this logic was attempted as inline `git` recipes twice and got it wrong both times (`git diff HEAD~1 HEAD` doesn't work without per-task commits; `git stash create` returns empty on clean trees and drops untracked files). The script encapsulates the correct sequence in one place that can be tested deterministically, per the AGENTS.md convention "Logic with complex deterministic branching ... lives in `scripts/`".

The implementer does not commit per task (commits happen at `/ops-ship` time), so HEAD remains the baseline throughout the entire `/ops-implement` run, and the captured state is always the cumulative delta from that baseline.

The reviewer SEES prior tasks' changes, by design — that context is what lets it spot duplication ("Task N added permission logic that looks like what Task N-1 already added in another file"). The reviewer is told via the dispatch prompt which task is being reviewed, so it can scope its FINDINGS to that task while still using the surrounding context.

**Parallelization caveat**: when dispatching multiple implementers in parallel (max 3 per `subagent-rules`), run the per-task review for each parallel task **after** all parallel implementers have returned, not during. The dispatch prompt for each per-task review names the specific task and its file list, so the reviewer scopes its findings even though all 3 tasks' changes appear in the same captured state.

**What to dispatch**:

Spawn the **code-reviewer** agent with:
- The task's spec excerpt (just the task description from the plan, not the full plan)
- The captured state — the stdout of `scripts/ops-capture-task-state.sh` (tracked diff + untracked new file contents, see above)
- The list of files this specific task was supposed to touch (from the plan task entry)
- **Explicit instruction**: "This is a per-task lightweight review during implementation, not the final review. The captured state you see is cumulative since the start of /ops-implement (tracked changes via `git diff HEAD` plus the full content of any untracked new files) — prior tasks' changes are visible by design, use them as context. Untracked new files are introduced by a marker line of the form `=== NEW FILE: <path> ===` followed by the file content. Five placeholder variants exist for non-text content: `[binary file — content omitted]` (file contains NUL bytes), `[empty file]` (zero bytes), `[symbolic link → <target>]` (symlink, not dereferenced), `[unreadable file — content omitted]` (file exists but cannot be read — permission denied or transient read error), and `[not a regular file — skipped]` (FIFO/socket/device, defensive — git rarely lists these). **Scope your findings to Task N's contributions only** (the files listed above). Focus on:
  - **Spec compliance for this task** (did the implementer build what was asked, nothing more, nothing less)
  - **Drift catchers**: duplicated logic introduced by this task (could a helper from a prior task have been reused? could a helper be extracted now for future tasks to reuse?), naming inconsistencies with prior tasks, type mismatches with prior tasks
  - **Lens 5 architectural drift**: if this task added a 'temporary' fragility ('we accept this propagation may fail'), if this task duplicated a permission rule already encoded elsewhere, if this task extended a file that should have been a new module
  - **Critical-only LSP diagnostics** (errors, not warnings) on the files modified by this task
  - Skip: full security audit (security-reviewer in Step 4 handles that), full architecture review (final review handles that), style nits (qlty handles that), findings about prior tasks' files (those were already reviewed by their own per-task review)"

Use a fast model (`model: "sonnet"`) for this review — it is meant to be cheap and quick.

**Handle results**:

- **Approved**: proceed to Step 2e (Discovery check).
- **Critical/Important issues found**: dispatch a **fresh implementer agent** with the original task context plus the per-task code-reviewer's findings (subagents are stateless — there is no "still running" agent to message). Reuse the same `model:` setting as the original dispatch to keep cost predictable. After the fix, **re-dispatch the per-task code-reviewer** with the fixed diff. Repeat until approved. Maximum 3 fix iterations per task — if still not approved, escalate to the user. **Repeated-finding circuit breaker**: if the SAME Lens 5 finding (or any same Critical/Important finding) appears in 2 consecutive iterations, escalate to the user immediately rather than continuing to iteration 3 — it's a sign the implementer cannot fix it without architectural guidance from you or the user.
- **Suggestions only**: note them in the task completion record (Step 2f) but proceed without fixing — suggestions are advisory.

**Why a separate review here instead of waiting for Step 4**:
1. Hot context — the implementer is still in scope and can fix issues with full context, no re-loading
2. Compounding prevention — drift caught at task N is fixed before tasks N+1, N+2 build on it
3. Lens 5 visibility — architectural drift introduced by extending an existing file is most visible just after that extension, not after 18 more commits have buried it
4. Cost — fast model + small diff = cheap review. Final review (Step 4) is the expensive one.

**Gate**: do NOT proceed to Step 2e until the per-task review reports Approved (or all Critical/Important findings have been fixed and re-reviewed).

### 2e. Discovery Check

If the implementer reported discoveries, categorize each using the `ops-discovery-checks` process (scope: "the current plan", pause target: "implementation").

### 2f. Task Completion Record

Output this record for every task before moving to the next. It feeds the final validation in Step 5 — omitting a command here means it gets silently skipped at the end.

```
### Task N: <name> — COMPLETED / BLOCKED
- Implementer: dispatched (agent), status: DONE/DONE_WITH_CONCERNS/BLOCKED/FAILED
- Validation commands:
  - `<command 1>` → exit code: N
  - `<command 2>` → exit code: N
- Conformity: diff matches plan | no drift | no security anti-patterns | conventions
- Per-task quality review: Approved on iteration N/3 | suggestions: <list or none>
- Discovery: NONE / MINOR(<detail>) / SIGNIFICANT(<detail>) / MAJOR(<detail>)
```

**Gate**: Do NOT proceed to the next task until this record is output AND the per-task quality review reported Approved.

---

## Step 3: Failure Handling

**If a task fails validation:**
1. Send the error output back to the implementer for a retry
2. If it fails a second time, try a different approach
3. If it fails a third time, mark the task as cancelled (BLOCKED: reason).

**If 3+ consecutive tasks fail (circuit breaker):**

Trigger the `ops-circuit-breaker` process (threshold: 3+, window: 30 days for git-historian).

---

## Step 4: Final Review

This is the **second** review layer. The per-task quality reviews (Step 2d) caught drift task-by-task while context was hot. This step now validates the **complete diff** for issues that only become visible at full-implementation scale: cross-task coherence (inconsistent naming, broken references between files), spec-vs-whole-implementation match, security gaps that span multiple components, and project-instruction compliance against the entire change set.

If the per-task reviews were thorough, the final review should mostly find cross-task issues, not single-task issues. If the final review finds many single-task issues, the per-task reviews were too lenient — that's a process signal worth surfacing.

### Pre-review Audit (MANDATORY)

Before dispatching the final review, output this audit summary by counting from the Task Completion Records (Step 2f):

```
## Implementation Audit
- Tasks in plan: N
- Implementer agents dispatched: N (must equal tasks in plan)
- Tasks completed: N
- Tasks blocked/cancelled: N (list which and why)
- Discrepancy: NONE / <describe>
```

**If fewer implementers were dispatched than tasks in the plan**, you bundled tasks — STOP and re-run the bundled tasks individually before proceeding.

### Code Quality (MANDATORY — runs BEFORE reviewers)

<HARD-GATE-CODE-QUALITY>
You MUST run the `ops-code-quality` process BEFORE dispatching the **final** reviewer agents (Step 4). If you dispatch the final code-reviewer or security-reviewer without having run code quality checks first, you have FAILED this skill.

This gate applies to the **final review (Step 4)** only. The per-task lightweight review at Step 2d is exempt — it operates on a single task's diff while context is hot, and running ops-code-quality on every task would defeat its purpose (cheap fast iteration). qlty/lint hygiene at the per-task level is delegated to the project's commit hooks (if any) or to the final code-quality pass at Step 4 which catches any drift across all tasks at once.

Sequence for Step 4: Pre-review Audit → Code Quality → Security Triage → Dispatch Reviews. Skipping Code Quality is not allowed even if the code "looks clean."

Degraded case: if no formatter or linter is detected in the project, running `ops-code-quality` will report "No formatter or linter detected — Skipped." This counts as having run the process. The gate requires running the process, not that tools exist.
</HARD-GATE-CODE-QUALITY>

Run the `ops-code-quality` process on all modified files. Fix any issues before dispatching reviewers.

### Security Triage (MANDATORY — structured output required)

Run the `ops-security-gate` process on the **complete diff** to determine whether the security-reviewer is needed, and handle re-verification if critical issues are found. If you write "NO" when the diff clearly contains security-sensitive changes, you have FAILED this skill.

You MUST output the structured triage block defined in `ops-security-gate` Step 1:

```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- SAST (semgrep): <N new findings (E errors, W warnings, I info)> / clean / not found / error
- Security findings from qlty: <list> / none / not run
- Security-reviewer dispatch: YES / NOT NEEDED
```

This block must appear in your output BEFORE dispatching the security-reviewer (or deciding not to). An informal assessment like "the diff touches permissions so let's dispatch" is NOT sufficient — go through the 14 triggers explicitly.

### Dispatch Reviews

Dispatch the **code-reviewer** agent with:
- The full spec document
- The complete diff (all changes across all tasks)
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (if the project has one)
- Instruction to evaluate the implementation as a whole, not task by task

If security triage is YES, dispatch the **security-reviewer** agent **in parallel** (same message as code-reviewer) with:
- The complete diff
- The list of security triggers matched
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`

The code-reviewer checks (FINAL review — full diff):
- Does the full implementation match the spec?
- Do the pieces fit together coherently?
- Are there cross-task issues (inconsistent naming, duplicated logic, missing integration points)?
- LSP diagnostics on all modified files
- Code quality, conventions, error handling
- **Architectural alternatives at full-implementation scale** — apply Lens 5 from `agents/critic.md`: now that the whole implementation is visible, is there a cleaner shape that the per-task reviews could not see?
- TDD adherence (if applicable)

The security-reviewer checks:
- Cross-task security coherence (e.g., network policy in task 9 vs access control in task 8)
- Trust boundaries, data flows, attack vectors across the full change
- All 9 analysis categories from the security-reviewer protocol

### Handle Review Results

**If Critical issues found (code-reviewer)**: fix before proceeding to completion.

**If Critical issues found (security-reviewer)**: the `ops-security-gate` re-verification loop handles this (fix → re-dispatch → cap 3 iterations).

**If Important issues found**: fix or note for the user.
**If Suggestions**: note for the user.
**If Approved**: proceed to completion summary.

---

## Step 5: Completion

After the final review passes:

<HARD-GATE-FINAL-VALIDATION>
You MUST re-run ALL validation commands from ALL tasks. Not some — ALL. If a command cannot be run, you MUST:
1. State which command and why
2. Present as a gap: "Warning: Validation gap: `<command>` could not be run because <reason>. Must be verified manually before shipping."

Silently skipping a validation command is a FAILURE of this skill.
</HARD-GATE-FINAL-VALIDATION>

1. **Run final validation**: Collect every validation command from all Task Completion Records (Step 2f), deduplicate (same command across tasks → list once, note which tasks), expand scope (same tool on different files → single broader invocation), and re-run all of them.

```
## Final Validation Checklist
- [x] `<command A>` (Tasks 1, 3, 5) → pass
- [x] `<command B>` (Tasks 2, 4) → pass
- [ ] `<command C>` (Task 6) → FAIL (exit code 1) — investigating
```

2. **Verify task tracking**: run `TaskList` and confirm all tasks are `completed` or `cancelled` — none left `in_progress` or `pending`. This is a mandatory tool call, not a mental check. If `TaskList` returns unexpected results, flag the anomaly to the user.

3. Present a summary:
   - Tasks completed: N/N (from `TaskList`)
   - Files created/modified: list
   - Any deviations from the plan
   - Any concerns raised by the implementer (including DONE_WITH_CONCERNS)
   - Code review findings
   - Security review findings (if dispatched)
   - **Per-task review effectiveness**: count single-task issues found in the final review (Step 4) that should have been caught by Step 2d per-task reviews. A high count means per-task reviews were too lenient — surface this as a process signal so future runs can recalibrate.
4. **Capture learnings** — reflect on what happened during implementation:

```markdown
## Learnings

### Problems solved
- [What went wrong and how it was fixed — e.g., "YAML indentation caused silent merge failure, fixed by validating with yq"]

### Decisions made
- [Non-obvious choices — e.g., "Used environment variables instead of a config file because the values change per deployment"]

### Gotchas discovered
- [Things future agents should know — e.g., "The ORM silently truncates strings longer than the column width — validate length before insert"]

### Patterns that worked
- [Reusable approaches — e.g., "Wrapping third-party clients in an interface made testing straightforward"]
```

Include this section in the completion summary. If the user saves it (e.g., in a project doc or memory), it becomes searchable context for future tasks.

5. **Update spec status**: if a spec file exists for this work, update its status to `**Status**: Implemented`.
6. Ask the user what to do next (commit, review, continue)

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
| "I'll skip the per-task review, the final review will catch it" | Per-task review catches drift while context is hot. Final review catches cross-task issues. Both are needed. Skipping per-task means architectural drift compounds across tasks. |
| "The per-task review found Important issues, but I can fix them in the final pass" | No. Fix them now via a fresh implementer dispatch with the findings as context. The final pass is for cross-task issues, not for postponed per-task fixes. |
| "Per-task review on Task 1 was clean, no need to run it on Task 2" | Each task gets its own review. A clean Task 1 review tells you nothing about Task 2. |
