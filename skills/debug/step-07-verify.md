# Step 7 — Verify

Mark the task "Debug: verify" as `in_progress` now via `TaskUpdate`.

## What to do

1. Run the original failing command — must pass now
2. Run related commands/tests — no regressions introduced
3. Show the evidence (command output, not just "it works")

Only declare the bug fixed after showing proof.

---

## ✅ End of Step 7

Before marking complete, verify:
- [ ] You ran the ORIGINAL failing command and it passes.
- [ ] You ran related commands/tests to check for regressions (no new failures introduced by the fix).
- [ ] You showed the command output as evidence in your response (not just "it works").
- [ ] You explicitly declared the bug fixed based on the shown evidence.

Mark the task "Debug: verify" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 8 steps of `/ops-debug` have been executed. The bug has been investigated, a root cause was confirmed, fixed, reviewed, and verified with evidence. There is no next file to read.
