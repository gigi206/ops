---
name: ops:implement
description: "Execute a validated plan task by task."
---

# /ops:implement — Execute a validated plan

<HARD-GATE>
STOP. Every task in the plan MUST go through the per-task pipeline:

  implementer → validation gate → conformity check → discovery check → task completion record

Do NOT combine multiple plan tasks into a single implementer dispatch. One task = one implementer agent. If you catch yourself writing "Implement Tasks 4+5" in a single agent prompt, STOP — split them.

Post-hoc verification: after all tasks complete, check that count(implementer agents dispatched) >= count(tasks in plan). If fewer implementers were dispatched than tasks exist, you bundled tasks — this is a FAILURE. Fix it by re-running the bundled tasks individually.

Code review and security review happen ONCE at the end (Step 4), on the complete diff — NOT per task. Do NOT dispatch code-reviewer or security-reviewer during the per-task pipeline.
</HARD-GATE>

## Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority.
2. **CLAUDE.md project rules** — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

## Subagent Context Rules

When dispatching any subagent (implementer, code-reviewer, security-reviewer, researcher-code, git-historian — code-reviewer and security-reviewer are dispatched only at final review, Step 4):

- **Provide content inline.** If you already read a file, paste the relevant content into the agent prompt. Do NOT ask the agent to re-read the same file.
- **Scope the context.** Give the implementer only the current task + relevant context — not the entire plan. Give the code-reviewer only the diff + task description — not every file in the project.
- **Name what you provide.** Always label pasted content with its source: `[From file.yaml:15-42]`. The agent needs to know where the content comes from.
- **Let the agent explore beyond.** The agent can and should read additional files it discovers — the goal is to avoid redundant reads, not to limit scope.

## Prerequisite

A plan must exist (from `/ops:plan` or user-provided). Do NOT implement without a plan.

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

**If the plan has no task breakdown or tasks are incomplete**: STOP. Do NOT implement. Tell the user to run `/ops:plan` first or to decompose the plan into tasks before proceeding.

### Register tasks

After verifying the plan, create a Claude Code task for each plan task using `TaskCreate`:

```
For each task in the plan:
  TaskCreate(description: "Task N: <description>", status: "pending")
```

This ensures task progress survives context compaction and is visible throughout the session.

---

## Step 2: Execute Tasks

For each task in the plan, in order:

**Before starting a task**, set its status to `in_progress`:
```
TaskUpdate(id: <task_id>, status: "in_progress")
```

### 2a. Dispatch Implementer Agent

**One task per agent.** Each implementer agent receives exactly ONE task from the plan. Do NOT bundle multiple tasks into a single agent prompt — even if they seem related or touch similar files.

**Parallelization rules:**
- Tasks with no dependency between them MAY be dispatched in parallel (multiple implementer agents at once).
- But each parallel task MUST independently complete steps 2b–2d before being marked completed.
- If Task B depends on files created/modified by Task A, Task B MUST wait until Task A's full pipeline is complete.
- Maximum 3 implementer agents running in parallel — more than this makes conformity checks unmanageable.

Spawn the **implementer** agent with:
- The specific task to implement (not the whole plan)
- The relevant context: overall approach + this task's details
- The files to read/modify
- The validation command for this task

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

After the implementer reports DONE, **verify with evidence**.

Run the appropriate validation commands depending on file types:

| Type | Example Commands |
|------|-----------------|
| Syntax check | Linter for the file type (e.g., `eslint`, `pylint`, `rubocop`) |
| Build/compile | Build tool for the project (e.g., `make`, `npm run build`, `cargo check`) |
| Dry-run | Validate without applying (e.g., `--dry-run`, `--check`, `--validate`) |
| Tests | Run relevant test suite (e.g., `npm test`, `pytest`, `go test`) |
| Shell scripts | `bash -n <file>`, `shellcheck <file>` |
| Custom | Whatever the task's validation command specifies |

**CRITICAL**: Do NOT mark a task as complete without running validation. No "it should work" — show the output.

### 2c. Conformity Check (MANDATORY)

**Do NOT skip this step.** After validation passes, verify each of these explicitly — not as a mental note, but by checking the actual diff:

- [ ] The change matches what the plan specified (compare plan task description against the diff)
- [ ] No unrelated changes were introduced (no drift — files touched should match the plan's "Files" list)
- [ ] No security anti-patterns: hardcoded secrets, `--insecure`, `skip_tls_verify`, disabled TLS
- [ ] Existing code conventions are preserved (indentation, naming, structure)

If conformity fails, have the implementer correct the specific issue before proceeding.

If you mark a task as completed without checking the diff against the plan, you have skipped this step.

**If conformity passes**, mark the task as complete:
```
TaskUpdate(id: <task_id>, status: "completed")
```

### 2d. Discovery Check

After each task completes, check if the implementer reported discoveries — things that were unexpected, different from what the plan assumed, or newly learned.

Categorize each discovery:

#### Minor discovery
*Something unexpected but doesn't affect the plan (e.g., "this file uses tabs instead of spaces").*

→ Note it in the discovery log. Continue to next task.

#### Significant discovery
*Something that affects upcoming tasks but doesn't invalidate the approach (e.g., "the API returns XML, not JSON — tasks 5-6 need to parse XML instead").*

→ **PAUSE implementation.** Present the discovery to the user with 2-3 options:

> "During task N, I discovered that [description]. This affects [which tasks].
> Options:
> A) [Concrete adaptation — e.g., add XML parser to tasks 5-6]
> B) [Alternative approach — e.g., use a different endpoint that returns JSON]
> C) Something else?
> Implementation is paused until you decide."

Wait for user decision. Amend the remaining tasks accordingly, then resume.

#### Major discovery
*Something that invalidates the chosen approach (e.g., "the library doesn't support streaming — the entire architecture is compromised").*

→ **STOP implementation.** Present the discovery to the user with options:

> "During task N, I discovered that [description]. This fundamentally affects the approach.
> Options:
> A) [Alternative approach — e.g., switch to library Y which supports streaming]
> B) [Reduced scope — e.g., implement without streaming, add later]
> C) Replanify from scratch with `/ops:plan` using this new information
> D) Something else?
> Implementation is stopped until you decide."

Wait for user decision. Depending on the choice, either amend and resume, or restart the planning cycle.

**The implementer MUST NOT silently work around significant or major discoveries.** If the reality doesn't match the plan, the user must be informed and must decide.

### 2e. Task Completion Record (MANDATORY)

**You MUST output this record for every task before moving to the next one.** This is not optional — it forces explicit verification of each pipeline step and prevents silent skipping.

```
### Task N: <name> — COMPLETED ✅ / BLOCKED ❌
- Implementer: dispatched (agent), status: DONE/DONE_WITH_CONCERNS/BLOCKED/FAILED
- Validation: `<command>` → exit code: N
- Conformity: diff matches plan ✅ | no drift ✅ | no security anti-patterns ✅ | conventions ✅
- Discovery: NONE / MINOR(<detail>) / SIGNIFICANT(<detail>) / MAJOR(<detail>)
```

If you skip this record for a task, you have skipped mandatory pipeline steps.

---

## Step 3: Failure Handling

**If a task fails validation:**
1. Send the error output back to the implementer for a retry
2. If it fails a second time, try a different approach
3. If it fails a third time, mark as BLOCKED:
   ```
   TaskUpdate(id: <task_id>, status: "cancelled", note: "BLOCKED: <reason>")
   ```

**If 3+ consecutive tasks fail (circuit breaker):**

Do NOT just stop and report. Diagnose the root cause first:

1. **Dispatch researcher-code and git-historian in parallel**:

   **researcher-code**:
   - The 3+ error outputs
   - The code produced by the implementer
   - The relevant plan tasks
   - Ask: "Why are these tasks failing? Is there a common root cause? Is the plan wrong?"

   **git-historian** (Investigation Mode):
   - Scope: files that failed
   - Window: 30 days
   - Focus: regressions — were these files recently changed? Any reverts or hotfixes?
   - Look for suspect commits that might explain the failures

2. **Combine diagnostics and present to the user** with options:
   > "3+ consecutive tasks failed. Diagnosis by researcher-code + git-historian:
   > [root cause analysis]
   >
   > Options:
   > A) [Specific fix — e.g., add missing task 4.5 to configure session store, then retry tasks 5-7]
   > B) [Alternative approach — e.g., switch to a different implementation strategy]
   > C) Investigate further with `/ops:debug`
   > D) Replanify with `/ops:plan` using these findings
   > E) Abandon
   > Implementation is stopped until you decide."

3. **Wait for user decision.** Then:
   - If A/B: amend the plan, resume implementation
   - If C: hand off to `/ops:debug`
   - If D: hand off to `/ops:plan` with the diagnostic as input
   - If E: stop

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

### Security Triage (MANDATORY)

Before dispatching reviewers, determine whether the security-reviewer is needed by evaluating the **complete diff** against these triggers:

- Authentication, authorization, or identity federation
- APIs, endpoints, or interfaces exposed beyond the trust boundary
- Secrets, credentials, keys, or tokens (creation, storage, rotation, transmission)
- Encryption, TLS, or certificate configuration
- User input handling or data validation
- Access control rules or permission models
- Network exposure, firewall rules, or traffic policies
- Infrastructure definitions (IaC) that provision or modify security-relevant resources
- CI/CD pipeline configuration (build, deploy, release workflows)
- Container, VM, or runtime privilege configuration
- Dependency or supply chain changes (new packages, registries, image sources)
- Policy enforcement, admission control, or compliance rules
- Data storage, retention, or backup configuration handling sensitive data
- Logging, audit, or observability configuration (risk of leaking sensitive data)

**Output the triage result:**
```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- Security-reviewer dispatch: YES / NOT NEEDED
```

If ANY trigger matches, dispatch the security-reviewer. If in doubt, dispatch — false positives are cheap; missed vulnerabilities are not.

If you write "NO" when the diff clearly contains security-sensitive changes, you have FAILED this skill.

### Dispatch Reviews

Dispatch the **code-reviewer** agent with:
- The full spec document
- The complete diff (all changes across all tasks)
- The project's CLAUDE.md rules (if the project has one)
- Instruction to evaluate the implementation as a whole, not task by task

If security triage is YES, dispatch the **security-reviewer** agent **in parallel** with:
- The complete diff
- The list of security triggers matched
- The project's CLAUDE.md rules

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

**If Critical issues found** (code or security): fix before proceeding to completion. Re-dispatch the security-reviewer after security fixes to verify.
**If Important issues found**: fix or note for the user.
**If Suggestions**: note for the user.
**If Approved**: proceed to completion summary.

---

## Step 5: Completion

After the final review passes:
1. Run a final full validation (all validation commands from all tasks)
2. **Verify task tracking is consistent**: run `TaskList` and confirm all tasks are either `completed` or `cancelled` — no tasks left `in_progress` or `pending`. This is a MANDATORY call, not a mental check. You MUST call `TaskList` and show the result.
3. Present a summary:
   - Tasks completed: N/N (from `TaskList`)
   - Files created/modified: list
   - Any deviations from the plan
   - Any concerns raised by the implementer (including DONE_WITH_CONCERNS)
   - Code review findings
   - Security review findings (if dispatched)
3. **Capture learnings** — reflect on what happened during implementation:

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

4. Ask the user what to do next (commit, review, continue)
