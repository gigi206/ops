---
name: ops-debug
description: "Use when something is broken, failing, or behaving unexpectedly."
---

# /ops-debug — Systematic debugging

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## The Iron Law

NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

Violating the letter of the rules is violating the spirit of the rules.

Do NOT guess. Investigate systematically. Understand the root cause before writing a fix.

## Workflow

```
0. Browser Bug Triage → 1. Investigate → 1.5. Instrument (if multi-component) → 2. Hypothesize (max 3) → 3. Test hypotheses → 4. Fix → 5. Code Review → 6. Discovery Check → 7. Verify
```

---

## Step 0: Browser Bug Triage

If the bug involves browser/frontend behavior (console errors, UI rendering, network from frontend, performance, accessibility): use `chrome-devtools-mcp` skills (`chrome-devtools`, `debug-optimize-lcp`, `a11y-debugging`, `troubleshooting`) for evidence gathering (Step 1), hypothesis testing (Step 3), and verification (Step 7).

If chrome-devtools-mcp is not installed, skip — investigate with standard tools.

---

## Step 1: Investigate

1. **Read the error**: Full error message, stack trace, logs. Not just the last line.
2. **Reproduce**: Run the failing command. Confirm you see the same error. For browser bugs, also reproduce in the browser using chrome-devtools-mcp (navigate to the page, read console messages, inspect network requests).
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

| #   | Hypothesis | Supporting evidence | Would disprove it |
|-----|------------|---------------------|-------------------|
| 1   | ...        | ...                 | ...               |
| 2   | ...        | ...                 | ...               |
| 3   | ...        | ...                 | ...               |

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
2. Run validation (same commands as `/ops-implement` validation gate)
3. Confirm the original error is gone

Do NOT fix symptoms. Fix the root cause.

---

## Step 5: Code Quality + Code Review

### Code Quality

Run the `ops-code-quality` process on all modified files. Fix any issues before dispatching reviewers.

### Security Gate

Run the `ops-security-gate` process on the diff of the fix. If triggers match, dispatch the security-reviewer in the **same message** as the code-reviewer (see `ops-subagent-rules`).

### Code Review

Dispatch the **code-reviewer** agent with:
- The root cause hypothesis that was confirmed
- The diff of the fix
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (if the project has one)

The code-reviewer checks: LSP diagnostics, code quality, conventions.

**If Critical issues found**: fix before proceeding to verification.
**If Important issues found**: fix before proceeding to verification.
**If Suggestions**: note, proceed.
**If Approved**: proceed to Step 6.

**Trivial fix exception:** You may skip code quality and code review ONLY if the fix modifies ≤1 file AND is a pure typo, comment edit, or single config value change with no logic involved.

---

## Step 6: Discovery Check

After the fix and code review, check if anything unexpected was revealed — by the fix itself, by the code-reviewer, or by the validation output. Categorize each discovery using the `ops-discovery-checks` process. The scope is "the current fix" and the pause target is "debugging".

---

## Step 7: Verify

1. Run the original failing command — must pass now
2. Run related commands/tests — no regressions introduced
3. Show the evidence (command output)

Only declare fixed after showing proof.

---

## Circuit Breaker

**5+ failed fix attempts** triggers the `ops-circuit-breaker` process (threshold: 5+, window: 60 days for git-historian). This is likely an architectural problem, not a simple bug.

---

## Red Flags — you are about to guess

If any of these thoughts cross your mind, STOP — you are about to skip root cause investigation:

| Thought | Reality |
|---------|---------|
| "The error is obvious, no need to investigate" | Obvious errors hide deep root causes. Investigate. |
| "I've seen this bug before, I know the fix" | Confirm with evidence. Your memory may be wrong. |
| "One test is enough to validate the hypothesis" | Unless it's intermittent. Test multiple times. |
| "The fix works, no need for code review" | Unless it modifies ≤1 file and is a pure typo/config change. Otherwise review is mandatory. |
| "All hypotheses are refuted, I'll try a fix anyway" | Go back to Step 1. No fix without a confirmed root cause. |
