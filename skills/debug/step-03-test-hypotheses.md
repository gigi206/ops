# Step 3 — Test Hypotheses

Mark the task "Debug: test hypotheses" as `in_progress` now via `TaskUpdate`.

## What to do

For each hypothesis, starting with the most likely:
1. Design a minimal test to confirm or refute
2. Run the test
3. Record the result: CONFIRMED or REFUTED

## Non-deterministic bugs (race conditions, intermittent failures)

If a hypothesis involves timing, concurrency, or intermittent behavior:
- A single test run is NOT sufficient to confirm or refute
- **Run the test multiple times** (at least 5) and record the success/failure rate
- **Add timing instrumentation** (timestamps at key points) to identify the race window
- **Look for shared state** — what resource are multiple components accessing without synchronization?
- If the bug reproduces only under load, document the conditions and tell the user: "This is a concurrency issue — it requires [specific condition] to reproduce"

## If all hypotheses are refuted

Go back to Step 1 with broader investigation. Consider: is the error message misleading? Is the problem upstream?

**Do NOT attempt a fix without a CONFIRMED hypothesis — this violates the Iron Law.**

---

## ✅ End of Step 3

Before proceeding, verify one of the branches below applies:

---

### Branch A — At least one hypothesis CONFIRMED

- [ ] You designed a minimal test for each hypothesis, starting with the most likely.
- [ ] You ran the tests and recorded CONFIRMED / REFUTED results in your output.
- [ ] For non-deterministic behaviors: you ran the test at least 5 times and recorded the success/failure rate.
- [ ] At least one hypothesis has a CONFIRMED root cause, with evidence.

Mark the task "Debug: test hypotheses" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-04-fix.md` now and execute Step 4.**

Do NOT continue without reading that file first.

---

### Branch B — All hypotheses REFUTED

- [ ] You confirmed (with test evidence) that all hypotheses are refuted.
- [ ] You are NOT about to write a fix without a confirmed root cause.

Do NOT mark this task completed. Go back to Step 1 and broaden the investigation.

**→ Go back: read `skills/debug/step-01-investigate.md` now and re-investigate with broader scope.** When you eventually return to this step, re-evaluate this End block with the new hypothesis test results.
