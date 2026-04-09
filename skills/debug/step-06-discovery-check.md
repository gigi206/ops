# Step 6 — Discovery Check

Mark the task "Debug: discovery check" as `in_progress` now via `TaskUpdate`.

## What to do

After the fix and code review, check if anything unexpected was revealed — by the fix itself, by the code-reviewer, by the validation output, or by the git-historian results from Step 1. Categorize each discovery using the `ops-discovery-checks` process. The scope is "the current fix" and the pause target is "debugging".

---

## ✅ End of Step 6

Before proceeding, verify:
- [ ] You checked for discoveries (unexpected findings from the fix, code-reviewer, validation, or git-historian).
- [ ] For each discovery, you applied the `ops-discovery-checks` process with scope "the current fix" and pause target "debugging".
- [ ] If any MAJOR or SIGNIFICANT discovery was found: you paused and presented it to the user before proceeding.
- [ ] MINOR discoveries are noted but do not block progression.

Mark the task "Debug: discovery check" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-07-verify.md` now and execute Step 7.**

Do NOT continue without reading that file first.
