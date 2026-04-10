# Step 3 — Final Review

This is the **second** review layer. The per-task quality reviews (Step 2d) caught drift task-by-task while context was hot. This step now validates the **complete diff** for issues that only become visible at full-implementation scale: cross-task coherence (inconsistent naming, broken references between files), plan-vs-whole-implementation match, security gaps that span multiple components, and project-instruction compliance against the entire change set.

If the per-task reviews were thorough, the final review should mostly find cross-task issues, not single-task issues. If the final review finds many single-task issues, the per-task reviews were too lenient — that's a process signal worth surfacing.

## Pre-review Audit (MANDATORY)

Before dispatching the final review, output this audit summary by counting from the Task Completion Records (Step 2f):

```
## Implementation Audit
- Tasks in plan: N
- Implementer agents dispatched: N (must equal tasks in plan)
- Tasks completed: N
- Tasks blocked/cancelled: N (list which and why)
- Discrepancy: NONE / <describe>
```

**If fewer implementers were dispatched than tasks in the plan**, you bundled tasks — STOP and re-run the bundled tasks individually before proceeding.

## Code Quality (MANDATORY — runs BEFORE reviewers)

<HARD-GATE-CODE-QUALITY>
You MUST run the `ops-code-quality` process BEFORE dispatching the **final** reviewer agents (Step 3). If you dispatch the final code-reviewer or security-reviewer without having run code quality checks first, you have FAILED this skill.

This gate applies to the **final review (Step 3)** only. The per-task lightweight review at Step 2d is exempt — it operates on a single task's diff while context is hot, and running ops-code-quality on every task would defeat its purpose (cheap fast iteration). qlty/lint hygiene at the per-task level is delegated to the project's commit hooks (if any) or to the final code-quality pass at Step 3 which catches any drift across all tasks at once.

Sequence for Step 3: Pre-review Audit → Code Quality → Security Triage → Dispatch Reviews. Skipping Code Quality is not allowed even if the code "looks clean."

Degraded case: if no formatter or linter is detected in the project, running `ops-code-quality` will report "No formatter or linter detected — Skipped." This counts as having run the process. The gate requires running the process, not that tools exist.
</HARD-GATE-CODE-QUALITY>

Run the `ops-code-quality` process on all modified files. Fix any issues before dispatching reviewers.

## Security Triage (MANDATORY — structured output required)

Run the `ops-security-gate` process on the **complete diff** to determine whether the security-reviewer is needed, and handle re-verification if critical issues are found. If you write "NO" when the diff clearly contains security-sensitive changes, you have FAILED this skill.

You MUST output the structured triage block defined in `ops-security-gate` Step 1:

```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- SAST (semgrep): <N new findings (E errors, W warnings, I info)> / clean / not found / error
- Security findings from qlty: <list> / none / not run
- Security-reviewer dispatch: YES / NOT NEEDED
```

This block must appear in your output BEFORE dispatching the security-reviewer (or deciding not to). An informal assessment like "the diff touches permissions so let's dispatch" is NOT sufficient — go through the 14 triggers explicitly.

## Dispatch Reviews

Dispatch the **code-reviewer** agent with:
- The full plan document
- The complete diff (all changes across all tasks)
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (if the project has one)
- Instruction to evaluate the implementation as a whole, not task by task

If security triage is YES, dispatch the **security-reviewer** agent **in parallel** (same message as code-reviewer) with:
- The complete diff
- The list of security triggers matched
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`

The code-reviewer checks (FINAL review — full diff):
- Does the full implementation match the plan?
- Do the pieces fit together coherently?
- Are there cross-task issues (inconsistent naming, duplicated logic, missing integration points)?
- LSP diagnostics on all modified files
- Code quality, conventions, error handling
- **Architectural alternatives at full-implementation scale** — apply Lens 5 from `agents/critic.md`: now that the whole implementation is visible, is there a cleaner shape that the per-task reviews could not see?
- TDD adherence (if applicable)

The security-reviewer checks:
- Cross-task security coherence (e.g., network policy in task 9 vs access control in task 8)
- Trust boundaries, data flows, attack vectors across the full change
- All 9 analysis categories from the security-reviewer protocol

## Handle Review Results

**If Critical issues found (code-reviewer)**: fix before proceeding to completion.

**If Critical issues found (security-reviewer)**: the `ops-security-gate` re-verification loop handles this (fix → re-dispatch → cap 3 iterations).

**If Important issues found**: fix or note for the user.
**If Suggestions**: note for the user.
**If Approved**: proceed to completion summary.

---

## ✅ End of Step 3

Before proceeding, verify:
- [ ] You output the `## Implementation Audit` block and confirmed implementers dispatched ≥ tasks in plan.
- [ ] You ran the `ops-code-quality` process on all modified files BEFORE dispatching reviewers (HARD-GATE-CODE-QUALITY).
- [ ] You output the `## Security Triage` block explicitly, going through the 14 triggers.
- [ ] You dispatched the code-reviewer with plan + complete diff + project instructions.
- [ ] If security triage was YES: you dispatched security-reviewer in parallel (same message as code-reviewer).
- [ ] All Critical issues (from either reviewer) have been fixed.
- [ ] Important issues are either fixed or noted for the user.

**→ Next: read `skills/implement/step-04-completion.md` now and execute Step 4.**

Do NOT continue without reading that file first.
