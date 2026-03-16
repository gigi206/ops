---
name: ops:debug
description: "Systematic debugging: investigate, hypothesize, fix."
---

# /ops:debug — Systematic debugging

## Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority.
2. **CLAUDE.md project rules** — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

## Subagent Context Rules

When dispatching any subagent (git-historian, code-reviewer, security-reviewer, researcher-code):

- **Provide content inline.** If you already read a file or error output, paste it into the agent prompt. Do NOT ask the agent to re-read the same file or re-run the same command.
- **Scope the context.** Give the git-historian only the relevant file paths and error context. Give the code-reviewer only the diff of the fix. Do NOT dump the entire investigation.
- **Name what you provide.** Always label pasted content: `[Error output from kubectl apply]`, `[From config.yaml:10-25]`.
- **Let the agent explore beyond.** The agent can and should read additional files — the goal is to avoid redundant reads, not to limit scope.

## Philosophy

Do NOT guess. Investigate systematically. Understand the root cause before writing a fix.

## Workflow

```
1. Investigate → 1.5. Instrument (if multi-component) → 2. Hypothesize (max 3) → 3. Test hypotheses → 4. Fix → 5. Code Review → 6. Discovery Check → 7. Verify
```

---

## Step 1: Investigate

1. **Read the error**: Full error message, stack trace, logs. Not just the last line.
2. **Reproduce**: Run the failing command. Confirm you see the same error.
3. **Gather context** — dispatch **git-historian** in Investigation Mode:
   - Scope: files mentioned in the error/stack trace
   - Window: 30 days
   - Focus: regressions — suspect commits, recent changes, blame analysis
   - While git-historian runs, also check: `git diff` for uncommitted changes, when it last worked
4. **Trace the data flow**: Follow the error backward through the code/config. Read each file in the chain.
5. **Combine**: Merge git-historian's findings with your own investigation. Suspect commits + data flow tracing = informed hypotheses.

**DO NOT attempt a fix during investigation.** Understand first.

---

## Step 1.5: Instrument (before hypothesizing)

If the error path crosses multiple components (e.g., request → middleware → service → database), add diagnostic instrumentation BEFORE forming hypotheses:

1. **Identify component boundaries** in the error path
2. **Add temporary logging/tracing** at each boundary:
   - Entry/exit of each component
   - Data shape at each boundary (what goes in, what comes out)
   - Timestamps if timing-related
3. **Reproduce the error** with instrumentation active
4. **Read the diagnostic output** — where does the data diverge from expectations?

This narrows the investigation from "somewhere in the stack" to "between component X and Y".

**Skip this step if:**
- The error is clearly localized (one file, one function, obvious stack trace)
- The system has no component boundaries (single script, single config file)

**Remove all diagnostic instrumentation before committing the fix.**

---

## Step 2: Hypothesize

Form **maximum 3 hypotheses** for the root cause. For each:

| # | Hypothesis | Supporting evidence | Would disprove it |
|---|-----------|-------------------|-------------------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |
| 3 | ... | ... | ... |

Rank by likelihood. Present to the user before proceeding.

---

## Step 3: Test Hypotheses

For each hypothesis, starting with most likely:
1. Design a minimal test to confirm or refute
2. Run the test
3. Record the result: CONFIRMED or REFUTED

### Non-deterministic bugs (race conditions, intermittent failures)

If a hypothesis involves timing, concurrency, or intermittent behavior:
- A single test run is NOT sufficient to confirm or refute
- **Run the test multiple times** (at least 5) and record the success/failure rate
- **Add timing instrumentation** (timestamps at key points) to identify the race window
- **Look for shared state** — what resource are multiple components accessing without synchronization?
- If the bug reproduces only under load, document the conditions and tell the user: "This is a concurrency issue — it requires [specific condition] to reproduce"

If all 3 hypotheses are refuted:
- Go back to Step 1 with broader investigation
- Consider: is the error message misleading? Is the problem upstream?

---

## Step 4: Fix

Once root cause is confirmed:
1. Write the minimal fix that addresses the root cause
2. Run validation (same commands as `/ops:implement` validation gate)
3. Confirm the original error is gone

Do NOT fix symptoms. Fix the root cause.

---

## Step 5: Code Review

Dispatch the **code-reviewer** agent with:
- The root cause hypothesis that was confirmed
- The diff of the fix
- The project's CLAUDE.md rules (if the project has one)

The code-reviewer checks: LSP diagnostics, code quality, security scan.

**If Critical issues found**: fix before proceeding to verification.
**If Important issues found**: fix before proceeding to verification.
**If Suggestions**: note, proceed.
**If Approved**: proceed to Step 6.

**Security escalation — MANDATORY when applicable**: If the fix touches any security-sensitive area (auth, APIs, secrets, encryption, user input, access control, network exposure, IaC, CI/CD, runtime privileges, dependencies, policy enforcement, data storage, or logging/audit), you MUST dispatch the **security-reviewer** in parallel (same rules as `/ops:implement` Step 2d).

**Trivial fix exception:** You may skip the code review ONLY if the fix modifies ≤1 file AND is a pure typo, comment edit, or single config value change with no logic involved.

---

## Step 6: Discovery Check

After the fix and code review, check if anything unexpected was revealed — by the fix itself, by the code-reviewer, or by the validation output.

#### Minor discovery
*Something unexpected but doesn't affect the fix (e.g., "the config file has inconsistent formatting").*

→ Note it. Proceed to Step 7.

#### Significant discovery
*The bug is broader than initially diagnosed — other components are affected (e.g., "the same misconfiguration exists in 3 other services").*

→ **PAUSE.** Present the discovery to the user with options:

> "While fixing [original bug], I discovered that [description]. This affects [what else].
> Options:
> A) [Fix the original bug only — address the broader issue separately]
> B) [Expand the fix to cover all affected components]
> C) Plan a comprehensive fix with `/ops:plan`
> D) Something else?
> Debugging is paused until you decide."

Wait for user decision, then proceed accordingly.

#### Major discovery
*The fix is a band-aid — the root cause is architectural (e.g., "this breaks because the module assumes synchronous calls, but the dependency switched to async in v3").*

→ **STOP.** Present the discovery to the user with options:

> "While fixing [original bug], I discovered that [description]. The real problem is architectural.
> Options:
> A) [Apply the band-aid fix now, plan the architectural fix separately]
> B) [Skip the band-aid, plan the architectural fix with `/ops:plan`]
> C) Something else?
> Debugging is stopped until you decide."

Wait for user decision.

**The goal**: catch structural problems at the first fix attempt instead of looping 5 times until the circuit breaker triggers.

---

## Step 7: Verify

1. Run the original failing command — must pass now
2. Run related commands/tests — no regressions introduced
3. Show the evidence (command output)

Only declare fixed after showing proof.

---

## Circuit Breaker

**5+ failed fix attempts** = this is likely an architectural problem, not a simple bug.

Do NOT just stop and report. Diagnose the root cause first:

1. **Dispatch researcher-code and git-historian in parallel**:

   **researcher-code**:
   - The 5+ error outputs and attempted fixes
   - The code/config being debugged
   - Ask: "Why do all fix attempts fail? Is this a symptom of a deeper problem?"

   **git-historian** (Investigation Mode):
   - Scope: all files touched during debugging
   - Window: 60 days (broader for architectural issues)
   - Focus: regressions, architectural milestones — has this area been structurally changed recently?

2. **Present the diagnostic to the user** with options:
   > "5+ fix attempts failed. Diagnosis by researcher-code + git-historian:
   > [root cause analysis]
   >
   > Options:
   > A) [Specific fix — e.g., the real root cause is X, fix that instead]
   > B) [Architectural change — e.g., this component needs restructuring]
   > C) Plan a proper fix with `/ops:plan` using these findings
   > D) Abandon
   > Debugging is stopped until you decide."

3. **Wait for user decision.** Then:
   - If A: attempt the targeted fix
   - If B/C: hand off to `/ops:plan` with the diagnostic as input
   - If D: stop
