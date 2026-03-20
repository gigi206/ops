---
name: ops:circuit-breaker
description: "Internal: diagnose repeated failures during implementation or debugging. Activated when 3+ consecutive task failures (implement) or 5+ failed fix attempts (debug)."
user-invocable: false
---

# Circuit Breaker

When repeated failures occur, do NOT just stop and report. Diagnose the root cause first.

## Trigger thresholds

- **Implementation**: 3+ consecutive task failures
- **Debugging**: 5+ failed fix attempts

## Diagnostic process

1. **Dispatch researcher-code and git-historian in parallel**:

   **researcher-code**:
   - All error outputs and attempted fixes/implementations
   - The code produced
   - The relevant plan tasks or debugging context
   - Ask: "Why are these failing? Is there a common root cause? Is the plan/approach wrong?"

   **git-historian** (Investigation Mode):
   - Scope: files that failed
   - Window: 30 days (implementation) or 60 days (debugging — broader for architectural issues)
   - Focus: regressions — were these files recently changed? Any reverts or hotfixes? Architectural milestones?
   - Look for suspect commits that might explain the failures

2. **Combine diagnostics and present to the user** with options:
   > "[Threshold] failures reached. Diagnosis by researcher-code + git-historian:
   > [root cause analysis]
   >
   > Options:
   > A) [Specific fix — e.g., add missing prerequisite, fix root cause]
   > B) [Alternative approach — e.g., switch implementation strategy]
   > C) Investigate further with `/ops:debug`
   > D) Replan with `/ops:plan` using these findings
   > E) Abandon
   > Work is stopped until you decide."

3. **Wait for user decision.** Then:
   - If A/B: amend the plan/approach, resume
   - If C: hand off to `/ops:debug`
   - If D: hand off to `/ops:plan` with the diagnostic as input
   - If E: stop
