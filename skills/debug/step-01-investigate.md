# Step 1 — Investigate

Mark the task "Debug: investigate" as `in_progress` now via `TaskUpdate`.

## What to do

1. **Read the error**: Full error message, stack trace, logs. Not just the last line.
2. **Reproduce**: Run the failing command. Confirm you see the same error. For browser bugs, also reproduce in the browser using chrome-devtools-mcp (navigate to the page, read console messages, inspect network requests).
3. **Gather context** — dispatch **git-historian** in Investigation Mode:
   - Scope: files mentioned in the error/stack trace
   - Window: 30 days
   - Focus: regressions — suspect commits, recent changes, blame analysis
   - While git-historian runs, also check: `git diff` for uncommitted changes, when it last worked
4. **Trace the data flow**: Follow the error backward through the code/config. Read each file in the chain.
5. **Combine**: Merge git-historian's findings with your own investigation. Suspect commits + data flow tracing = informed hypotheses.

**DO NOT attempt a fix during investigation.** Understand first. This is the Iron Law from SKILL.md — no fix without a confirmed root cause.

## Instrumentation (conditional — before hypothesizing)

If the error path crosses multiple components (e.g., request → middleware → service → database), add diagnostic instrumentation BEFORE forming hypotheses:

1. **Identify component boundaries** in the error path
2. **Add temporary logging/tracing** at each boundary:
   - Entry/exit of each component
   - Data shape at each boundary (what goes in, what comes out)
   - Timestamps if timing-related
3. **Reproduce the error** with instrumentation active
4. **Read the diagnostic output** — where does the data diverge from expectations?

This narrows the investigation from "somewhere in the stack" to "between component X and Y".

**Skip this sub-step if:**
- The error is clearly localized (one file, one function, obvious stack trace)
- The system has no component boundaries (single script, single config file)

**Remove all diagnostic instrumentation before committing the fix.**

---

## ✅ End of Step 1

Before proceeding, verify:
- [ ] You read the FULL error message, stack trace, and logs (not just the last line).
- [ ] You reproduced the bug.
- [ ] You dispatched git-historian in Investigation Mode (scope: files in error path, window 30 days).
- [ ] You traced the data flow backward through the code/config.
- [ ] You merged git-historian's findings with your own investigation.
- [ ] If the error path crosses component boundaries: you added instrumentation, reproduced with it active, and identified where data diverges.
- [ ] You did NOT write any fix during investigation (Iron Law).

Mark the task "Debug: investigate" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-02-hypothesize.md` now and execute Step 2.**

Do NOT continue without reading that file first.
