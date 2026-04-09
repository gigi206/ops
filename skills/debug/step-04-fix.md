# Step 4 — Fix

Mark the task "Debug: fix" as `in_progress` now via `TaskUpdate`.

## What to do

Once the root cause is confirmed (Step 3 CONFIRMED a hypothesis):

1. Write the minimal fix that addresses the root cause
2. Run validation (same commands as `/ops-implement` validation gate)
3. Confirm the original error is gone

**Do NOT fix symptoms. Fix the root cause.**

## Failure handling (fix attempts)

If the fix fails validation:
1. Send the error output back, adjust the fix
2. If it fails a second time, try a different approach based on the same confirmed root cause
3. If it fails a third time on the same bug, pause and reconsider — maybe the confirmed hypothesis was wrong and you need to revisit Step 3

## Circuit Breaker

**5+ failed fix attempts** on this bug triggers the `ops-circuit-breaker` process (threshold: 5+, window: 60 days for git-historian). This is likely an architectural problem, not a simple bug — escalate to the user with the circuit-breaker output.

If the circuit breaker triggers: do NOT mark this step completed. Escalate and wait for user direction.

---

## ✅ End of Step 4

Before proceeding, verify:
- [ ] The fix addresses the CONFIRMED root cause from Step 3 (not a symptom).
- [ ] The fix is minimal (no unrelated changes).
- [ ] You ran validation commands and they pass — with evidence shown in the output.
- [ ] The original failing command no longer fails.
- [ ] If diagnostic instrumentation was added in Step 1's Instrumentation sub-section: it has been removed before moving on.
- [ ] If the fix failed 5+ times: you triggered the circuit breaker and escalated to the user (do NOT mark this task completed in that case — escalate instead).

Mark the task "Debug: fix" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-05-code-review.md` now and execute Step 5.**

Do NOT continue without reading that file first.
