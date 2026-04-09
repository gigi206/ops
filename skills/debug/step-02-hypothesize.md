# Step 2 — Hypothesize

Mark the task "Debug: hypothesize" as `in_progress` now via `TaskUpdate`.

## What to do

Form **maximum 3 hypotheses** for the root cause. For each:

| #   | Hypothesis | Supporting evidence | Would disprove it |
|-----|------------|---------------------|-------------------|
| 1   | ...        | ...                 | ...               |
| 2   | ...        | ...                 | ...               |
| 3   | ...        | ...                 | ...               |

Rank by likelihood. Present to the user before proceeding.

**Do NOT exceed 3 hypotheses.** If you find yourself listing 4+, you have not investigated enough — the data should narrow the possibilities. Go back to Step 1 and gather more evidence.

---

## ✅ End of Step 2

Before proceeding, verify:
- [ ] You produced AT MOST 3 hypotheses.
- [ ] Each hypothesis has: supporting evidence + what would disprove it.
- [ ] Hypotheses are ranked by likelihood (most likely first).
- [ ] You presented the table to the user in your output (not just a mental check).

Mark the task "Debug: hypothesize" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-03-test-hypotheses.md` now and execute Step 3.**

Do NOT continue without reading that file first.
