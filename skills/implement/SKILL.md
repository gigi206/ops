---
name: ops-implement
description: "Execute a validated plan task by task."
---

# /ops-implement — Execute a validated plan

<HARD-GATE>
STOP. Every task in the plan MUST go through the per-task pipeline:

  implementer → validation gate → conformity check → discovery check → task completion record

Do NOT combine multiple plan tasks into a single implementer dispatch. One task = one implementer agent. If you catch yourself writing "Implement Tasks 4+5" in a single agent prompt, STOP — split them.

Post-hoc verification: after all tasks complete, check that count(implementer agents dispatched) >= count(tasks in plan). If fewer implementers were dispatched than tasks exist, you bundled tasks — this is a FAILURE. Fix it by re-running the bundled tasks individually.

Code review and security review happen ONCE at the end (Step 4), on the complete diff — NOT per task. Do NOT dispatch code-reviewer or security-reviewer during the per-task pipeline.
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
  1. Implementer agent → 2. Validation gate → 3. Conformity check → 4. Discovery check → 5. Task completion record
  If discovery → Pause, present options to user
  If 3+ consecutive failures → Diagnose with researcher-code, present options to user
After all tasks:
  6. Pre-review audit → 7. Final review (code-reviewer + security-reviewer on complete diff)
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
- But each parallel task MUST independently complete steps 2b–2e before being marked completed.
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
- Do NOT ignore concerns silently — acknowledge them in the completion summary (Step 4).

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

**If conformity passes**: mark the task as completed.

### 2d. Discovery Check

If the implementer reported discoveries, categorize each using the `ops-discovery-checks` process (scope: "the current plan", pause target: "implementation").

### 2e. Task Completion Record

Output this record for every task before moving to the next. It feeds the final validation in Step 5 — omitting a command here means it gets silently skipped at the end.

```
### Task N: <name> — COMPLETED / BLOCKED
- Implementer: dispatched (agent), status: DONE/DONE_WITH_CONCERNS/BLOCKED/FAILED
- Validation commands:
  - `<command 1>` → exit code: N
  - `<command 2>` → exit code: N
- Conformity: diff matches plan | no drift | no security anti-patterns | conventions
- Discovery: NONE / MINOR(<detail>) / SIGNIFICANT(<detail>) / MAJOR(<detail>)
```

**Gate**: Do NOT proceed to the next task until this record is output.

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

This is where code quality and security are validated — on the **complete diff**, not per task. Reviewing the full implementation gives better context for cross-task issues (inconsistent naming, broken references between files, security gaps across components).

### Pre-review Audit (MANDATORY)

Before dispatching the final review, output this audit summary by counting from the Task Completion Records (Step 2e):

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
You MUST run the `ops-code-quality` process BEFORE dispatching any reviewer agent. If you dispatch code-reviewer or security-reviewer without having run code quality checks first, you have FAILED this skill.

Sequence: Pre-review Audit → Code Quality → Security Triage → Dispatch Reviews. Skipping Code Quality is not allowed even if the code "looks clean."

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

The code-reviewer checks:
- Does the full implementation match the spec?
- Do the pieces fit together coherently?
- Are there cross-task issues (inconsistent naming, duplicated logic, missing integration points)?
- LSP diagnostics on modified files
- Code quality, conventions, error handling
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

1. **Run final validation**: Collect every validation command from all Task Completion Records (Step 2e), deduplicate (same command across tasks → list once, note which tasks), expand scope (same tool on different files → single broader invocation), and re-run all of them.

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
