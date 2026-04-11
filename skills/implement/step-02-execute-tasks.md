# Step 2 — Execute Tasks

<HARD-GATE-NO-BUNDLING>
One task = one implementer agent. No bundling, no bypass. See the full rule and post-hoc count audit in `skills/implement/SKILL.md` `<HARD-GATE>`.
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

- **`[low-risk]` tasks**: use `model: "sonnet"`
- **`[high-risk]` tasks**: use the default model (most capable)
- If a sonnet-dispatched task fails, retry with the default model before escalating.

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
- [ ] **LSP diagnostics (per-task, when available)**: run LSP diagnostics on every file the task modified. LSP is fast (milliseconds to seconds per file) — this is not the same thing as the final-review LSP diagnostics in Step 3, which runs on the cumulative diff once. Per-task diagnostics catch type errors, missing imports, and syntax-class issues **immediately** after the task, while the implementer context is still warm. If diagnostics report errors:
  - **Errors introduced by THIS task** → have the implementer fix before proceeding. Do NOT move to Step 2d or Step 2e with new diagnostic errors on the working tree.
  - **Pre-existing errors** (present on files before the task touched them) → note them in the task completion record but do not block the task on them. The plan is responsible for scoping pre-existing issues explicitly if they need fixing.
  - **If LSP is not available** for the language (no server configured, or `/ops-init` Step 6 flagged LSP as missing): skip this checkbox, note "LSP not available for per-task diagnostics" once in the task record, and rely on the final review (Step 3) to catch type errors. Do NOT block the task on missing LSP.

  Rationale: a type error introduced in Task 1 detected at Task N's final review means N-1 tasks were built on a broken assumption — the fix loop is expensive because context is cold. Per-task LSP diagnostics close that feedback loop to one task. See `ops-subagent-rules` HARD-GATE-LSP.

If conformity fails, have the implementer correct the issue before proceeding.

## 2d. Per-task Quality Review (Complex mode only, `[high-risk]` tasks)

**If the plan header says `Mode: Normal`**: skip this step entirely for ALL tasks and proceed to Step 2e. In Normal mode, the final review (Step 3) catches issues across all tasks at once. Per-task review is reserved for Complex mode where architectural drift between tasks is a real risk.

**If the plan header has no `Mode: …` line at all**: default to **Complex** (full ceremony — matches `skills/implement/SKILL.md:25` and `skills/plan/step-07-write-plan.md:20`). Do NOT default to Normal. A plan written by hand or by an unknown source is treated with the stricter ceremony by default — opting into Normal requires an explicit `**Mode**: Normal` header written by the planner.

**If the task is tagged `[low-risk]`**: skip this step entirely and proceed to Step 2e, regardless of mode.

<HARD-GATE-PER-TASK-REVIEW>
**Complex mode, `[high-risk]` tasks only**: after conformity passes and BEFORE the discovery check, you MUST dispatch a **focused** code-reviewer agent. This is the per-task quality gate. Skipping it means architectural drift compounds across tasks and only gets caught in Step 3, when the context is cold and fixes are expensive.

This review is intentionally lightweight and scoped to ONE task. It is NOT the final review (which happens in Step 3 on the full diff with security-reviewer).
</HARD-GATE-PER-TASK-REVIEW>

**What to capture and pass to the reviewer**: the cumulative working tree state since the start of `/ops-implement`. Run these two commands:

1. `git diff HEAD` — tracked file modifications
2. `git ls-files --others --exclude-standard` — list untracked new files, then `cat` each one

Pass the combined output inline to the code-reviewer dispatch prompt. The reviewer sees prior tasks' changes by design — that context lets it spot duplication across tasks. The reviewer is told which task is being reviewed, so it scopes findings to that task while using the surrounding context.

**Parallelization caveat**: when dispatching multiple implementers in parallel (max 3 per `subagent-rules`), run the per-task review for each parallel task **after** all parallel implementers have returned, not during.

**What to dispatch**:

Spawn the **code-reviewer** agent with:
- The task's plan excerpt (just the task description from the plan, not the full plan)
- The captured diff (output of the two commands above)
- The list of files this specific task was supposed to touch (from the plan task entry)
- **Explicit instruction**: "This is a per-task lightweight review during implementation, not the final review. The diff is cumulative since the start of /ops-implement — prior tasks' changes are visible by design, use them as context. **Scope your findings to Task N's contributions only** (the files listed above). Focus on:
  - **Plan compliance for this task** (did the implementer build what was asked, nothing more, nothing less)
  - **Drift catchers**: duplicated logic introduced by this task, naming inconsistencies with prior tasks, type mismatches with prior tasks
  - **Critical-only LSP diagnostics** (errors, not warnings) on the files modified by this task. Note: per-task LSP diagnostics already ran at 2c and gated on errors introduced by this task — any remaining error here is either (a) a diagnostic that the 2c pass missed due to LSP unavailability, or (b) a new error introduced by the fix-loop between 2c and this reviewer dispatch. Treat this as the last-line reviewer pass, not the authoritative check (2c is authoritative).
  - Skip: full security audit (security-reviewer in Step 3 handles that), full architecture review and Lens 5 (final review handles that at full-diff scale), style nits (qlty handles that), findings about prior tasks' files (those were already reviewed by their own per-task review)
  NOTE: Lens 5 (architectural drift) was intentionally moved from per-task to final review for cross-task visibility. If drift is observed slipping through final reviews in practice, re-add Lens 5 here for `[high-risk]` tasks only."

Use a fast model (`model: "sonnet"`) for this review — it is meant to be cheap and quick.

**Handle results**:

- **Approved**: proceed to Step 2e (Discovery check).
- **Critical/Important issues found**: dispatch a **fresh implementer agent** with the original task context plus the per-task code-reviewer's findings (subagents are stateless — there is no "still running" agent to message). Reuse the same `model:` setting as the original dispatch to keep cost predictable. After the fix, **re-dispatch the per-task code-reviewer** with the fixed diff. Repeat until approved. Maximum 3 fix iterations per task — if still not approved, escalate to the user. **Repeated-finding circuit breaker**: if the SAME Critical/Important finding appears in 2 consecutive iterations, escalate to the user immediately rather than continuing to iteration 3 — it's a sign the implementer cannot fix it without architectural guidance from you or the user.
- **Suggestions only**: note them in the task completion record (Step 2f) but proceed without fixing — suggestions are advisory.

**Why a separate review here instead of waiting for Step 3**:
1. Hot context — the implementer is still in scope and can fix issues with full context, no re-loading
2. Compounding prevention — drift caught at task N is fixed before tasks N+1, N+2 build on it
3. Cost — fast model + small diff = cheap review. Final review (Step 3) is the expensive one.

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
