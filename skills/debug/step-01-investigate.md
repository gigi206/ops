# Step 1 — Investigate

Mark the task "Debug: investigate" as `in_progress` now via `TaskUpdate`.

## What to do

1. **Read the error**: Full error message, stack trace, logs. Not just the last line.
2. **Reproduce**: Run the failing command. Confirm you see the same error. For browser bugs, also reproduce in the browser using chrome-devtools-mcp (navigate to the page, read console messages, inspect network requests).
3. **LSP-first symbol resolution on the stack trace** (when LSP is available for the target language). Before dispatching git-historian or grepping for the error site, resolve the stack-trace symbols through LSP:
   - For each frame in the stack trace, run `goToDefinition` on the symbol at that frame. LSP returns the definition location in milliseconds, follows imports/aliases/re-exports correctly, and gives you the actual file and line that will run — grep may point at a shadowed name in a different module.
   - For the symbol where the error is thrown, run `findReferences` to see who calls it. The caller set is the hypothesis surface for the bug: the bug is typically between "what the callee expects" and "what one of the callers actually passes".
   - For unfamiliar types in the error message, run `hover` to get the type/signature/docstring without opening the file in full.
   - If LSP is not available for the language (no server, or `/ops-init` Step 6 flagged it as missing), note it once and fall back to Read + Grep — do NOT retry LSP repeatedly. See `ops-subagent-rules` HARD-GATE-LSP.
4. **Gather context** — dispatch **git-historian** in Investigation Mode:
   - Scope: files mentioned in the error/stack trace (and any additional files surfaced by LSP `goToDefinition` in step 3)
   - Window: 30 days
   - Focus: regressions — suspect commits, recent changes, blame analysis
   - While git-historian runs, also check: `git diff` for uncommitted changes, when it last worked
5. **Trace the data flow**: Follow the error backward through the code/config. Read each file in the chain.
6. **Combine**: Merge git-historian's findings with your own investigation (including the LSP-resolved caller/definition graph from step 3). Suspect commits + data flow tracing + LSP reference graph = informed hypotheses.

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
- [ ] You resolved the stack-trace symbols via LSP `goToDefinition` first (or noted LSP unavailability and fell back to Read + Grep). `findReferences` ran on the error-site symbol to inventory callers.
- [ ] You dispatched git-historian in Investigation Mode (scope: files in error path AND files surfaced by LSP resolution, window 30 days).
- [ ] You traced the data flow backward through the code/config.
- [ ] You merged git-historian's findings with your own investigation (including the LSP reference graph).
- [ ] If the error path crosses component boundaries: you added instrumentation, reproduced with it active, and identified where data diverges.
- [ ] You did NOT write any fix during investigation (Iron Law).

Mark the task "Debug: investigate" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-02-hypothesize.md` now and execute Step 2.**

Do NOT continue without reading that file first.
