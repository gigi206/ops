# Step 5 — Code Quality + Code Review

Mark the task "Debug: code review" as `in_progress` now via `TaskUpdate`.

## Code Quality

Run the `ops-code-quality` process on all modified files. Fix any issues before dispatching reviewers.

## Security Gate

Run the `ops-security-gate` process on the diff of the fix. If triggers match, dispatch the security-reviewer in the **same message** as the code-reviewer (see `ops-subagent-rules`).

## Code Review

Dispatch the **code-reviewer** agent with:
- The root cause hypothesis that was confirmed
- The diff of the fix
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (if the project has one)

The code-reviewer checks: LSP diagnostics, code quality, conventions.

**If Critical issues found**: fix before proceeding to verification.
**If Important issues found**: fix before proceeding to verification.
**If Suggestions**: note, proceed.
**If Approved**: proceed to Step 6.

## Trivial fix exception

You may skip code quality and code review ONLY if the fix modifies ≤1 file AND is a pure typo, comment edit, or single config value change with no logic involved. Any logic change — however small — does NOT qualify.

---

## ✅ End of Step 5

Before proceeding, verify ONE of these branches applies:

**Standard path:**
- [ ] You ran the `ops-code-quality` process on all modified files.
- [ ] You ran the `ops-security-gate` process on the diff.
- [ ] If security triggers matched: you dispatched security-reviewer in the same message as code-reviewer.
- [ ] You dispatched code-reviewer with the confirmed root cause + diff + project instructions.
- [ ] All Critical and Important issues are fixed.
- [ ] Suggestions are noted (not necessarily fixed).

**Trivial exception path:**
- [ ] The fix modifies ≤1 file AND is a pure typo / comment / config value change with no logic involved.
- [ ] You explicitly noted "trivial fix exception — skipping code review" in your output.

Mark the task "Debug: code review" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-06-discovery-check.md` now and execute Step 6.**

Do NOT continue without reading that file first.
