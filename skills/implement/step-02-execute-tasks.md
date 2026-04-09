# Step 2 — Execute Tasks

<HARD-GATE-NO-BUNDLING>
Every task in the plan MUST go through the per-task pipeline (2a → 2f) INDIVIDUALLY. One task = one implementer agent. No exceptions.

If you find yourself writing, proposing, or asking the user ANY of the following, you have FAILED this skill:

- "Implement Tasks N+M in a single dispatch" (bundling)
- "Execute tasks directly using the edit tools instead of dispatching implementer agents" (bypass)
- "Batch simpler tasks into direct edits, use subagents for complex ones" (bundling + bypass)
- Asking the user to choose between "execute the full pipeline rigorously" and "faster alternatives" — THE RIGOROUS PIPELINE IS THE ONLY OPTION. Do not negotiate, do not offer shortcuts, do not propose to batch based on task size or complexity.

If the plan has 18 tasks, you dispatch 18 implementer agents. If it has 50 tasks, you dispatch 50. Token cost is NOT a valid reason to bundle — the user can interrupt the skill at any time if they want to stop. Offering the user a "lighter" alternative is the same thing as silently bundling — both defeat the purpose of the per-task pipeline (per-task review catches drift task-by-task while context is hot).

The post-hoc count audit in the `## ✅ End of Step 2` completion checklist verifies that `count(implementer agents dispatched) ≥ count(plan tasks)`. If you bundle or bypass, the audit WILL catch it and you will have to redo the bundled tasks individually.

This gate is a specific reinforcement of the top-level `<HARD-GATE>` in `skills/implement/SKILL.md` — it is repeated here because this file is the per-task loop, and the top-level gate is "far" from the point of enforcement. Read this gate every time you re-enter the loop for a new task.
</HARD-GATE-NO-BUNDLING>

For each task in the plan, in order, run the per-task pipeline below (2a → 2b → 2c → 2d → 2e → 2f). When the current task's pipeline is complete, move to the next plan task and restart the pipeline from 2a. When ALL plan tasks have been processed, proceed to the End of Step 2 block and hand off to Step 3.

**Before starting a task**, mark it as `in_progress` via `TaskUpdate`.

## 2a. Dispatch Implementer Agent

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
- Do NOT ignore concerns silently — acknowledge them in the task completion record (Step 2f) and again in the final completion summary (Step 4).

## 2b. Validation Gate

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

**If validation fails, apply the Failure Handling rules at the bottom of this file before proceeding.**

## 2c. Conformity Check

After validation passes, verify by checking the actual diff — not as a mental note:

- [ ] Change matches the plan's task description
- [ ] No unrelated changes (files touched match the plan's "Files" list)
- [ ] No security anti-patterns: hardcoded secrets, `--insecure`, `skip_tls_verify`, disabled TLS
- [ ] Existing code conventions preserved (indentation, naming, structure)

If conformity fails, have the implementer correct the issue before proceeding.

## 2d. Per-task Quality Review (MANDATORY — lightweight, fast iteration)

<HARD-GATE-PER-TASK-REVIEW>
After conformity passes and BEFORE the discovery check, you MUST dispatch a **focused** code-reviewer agent. This is the per-task quality gate. Skipping it means architectural drift compounds across tasks and only gets caught in Step 3, when the context is cold and fixes are expensive.

This review is intentionally lightweight and scoped to ONE task. It is NOT the final review (which happens in Step 3 on the full diff with security-reviewer).
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
  - Skip: full security audit (security-reviewer in Step 3 handles that), full architecture review (final review handles that), style nits (qlty handles that), findings about prior tasks' files (those were already reviewed by their own per-task review)"

Use a fast model (`model: "sonnet"`) for this review — it is meant to be cheap and quick.

**Handle results**:

- **Approved**: proceed to Step 2e (Discovery check).
- **Critical/Important issues found**: dispatch a **fresh implementer agent** with the original task context plus the per-task code-reviewer's findings (subagents are stateless — there is no "still running" agent to message). Reuse the same `model:` setting as the original dispatch to keep cost predictable. After the fix, **re-dispatch the per-task code-reviewer** with the fixed diff. Repeat until approved. Maximum 3 fix iterations per task — if still not approved, escalate to the user. **Repeated-finding circuit breaker**: if the SAME Lens 5 finding (or any same Critical/Important finding) appears in 2 consecutive iterations, escalate to the user immediately rather than continuing to iteration 3 — it's a sign the implementer cannot fix it without architectural guidance from you or the user.
- **Suggestions only**: note them in the task completion record (Step 2f) but proceed without fixing — suggestions are advisory.

**Why a separate review here instead of waiting for Step 3**:
1. Hot context — the implementer is still in scope and can fix issues with full context, no re-loading
2. Compounding prevention — drift caught at task N is fixed before tasks N+1, N+2 build on it
3. Lens 5 visibility — architectural drift introduced by extending an existing file is most visible just after that extension, not after 18 more commits have buried it
4. Cost — fast model + small diff = cheap review. Final review (Step 3) is the expensive one.

**Gate**: do NOT proceed to Step 2e until the per-task review reports Approved (or all Critical/Important findings have been fixed and re-reviewed).

## 2e. Discovery Check

If the implementer reported discoveries, categorize each using the `ops-discovery-checks` process (scope: "the current plan", pause target: "implementation").

## 2f. Task Completion Record

Output this record for every task before moving to the next. It feeds the final validation in Step 4 — omitting a command here means it gets silently skipped at the end.

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

After outputting the Task Completion Record, mark this plan task as `completed` via `TaskUpdate`.

---

## Failure Handling (applies during the per-task pipeline)

**If a task fails validation (Step 2b):**
1. Send the error output back to the implementer for a retry
2. If it fails a second time, try a different approach
3. If it fails a third time, mark the task as cancelled (BLOCKED: reason).

**If 3+ consecutive tasks fail (circuit breaker):**

Trigger the `ops-circuit-breaker` process (threshold: 3+, window: 30 days for git-historian).

---

## ✅ End of Step 2

This step is a LOOP — you stay in this file and iterate through the plan tasks. Do NOT leave this file until ALL plan tasks have been processed.

**While plan tasks remain unprocessed**, go back to the top of this file and run the per-task pipeline (2a → 2f) for the next task.

**Once ALL plan tasks have been processed**, verify:
- [ ] Every plan task has been either completed (full pipeline 2a-2f, per-task review Approved) or cancelled (BLOCKED with reason).
- [ ] Every completed task has a Task Completion Record (2f) output in the conversation.
- [ ] No plan task was bundled with another in a single implementer dispatch — count of implementer agents dispatched ≥ count of plan tasks (post-hoc check from the top-level `<HARD-GATE>` in SKILL.md).
- [ ] For every task marked BLOCKED, the reason is recorded.
- [ ] All plan tasks are marked `completed` or `cancelled` via `TaskUpdate` (none left `in_progress` or `pending`).

**→ Next: read `skills/implement/step-03-final-review.md` now and execute Step 3.**

Do NOT continue without reading that file first.
