# Step 4 — Completion

After the final review passes, wrap up the implementation with final validation, summary, and learnings capture.

<HARD-GATE-FINAL-VALIDATION>
You MUST re-run ALL validation commands from ALL tasks. Not some — ALL. If a command cannot be run, you MUST:
1. State which command and why
2. Present as a gap: "Warning: Validation gap: `<command>` could not be run because <reason>. Must be verified manually before shipping."

Silently skipping a validation command is a FAILURE of this skill.
</HARD-GATE-FINAL-VALIDATION>

1. **Run final validation**: Collect every validation command from all Task Completion Records (Step 2f), deduplicate (same command across tasks → list once, note which tasks), expand scope (same tool on different files → single broader invocation), and re-run all of them.

```
## Final Validation Checklist
- [x] `<command A>` (Tasks 1, 3, 5) → pass
- [x] `<command B>` (Tasks 2, 4) → pass
- [ ] `<command C>` (Task 6) → FAIL (exit code 1) — investigating
```

2. **Verify task tracking**: run `TaskList` and confirm all tasks are `completed` or `cancelled` — none left `in_progress` or `pending`. This is a mandatory tool call, not a mental check. If `TaskList` returns unexpected results, flag the anomaly to the user.

3. Present a summary:
   - Tasks completed: N/N (from `TaskList`)
   - Files created/modified: list
   - Any deviations from the plan
   - Any concerns raised by the implementer (including DONE_WITH_CONCERNS)
   - Code review findings
   - Security review findings (if dispatched)
   - **Per-task review effectiveness**: count single-task issues found in the final review (Step 3) that should have been caught by Step 2d per-task reviews. A high count means per-task reviews were too lenient — surface this as a process signal so future runs can recalibrate.
4. **Capture learnings** — reflect on what happened during implementation:

```markdown
## Learnings

### Problems solved
- [What went wrong and how it was fixed — e.g., "YAML indentation caused silent merge failure, fixed by validating with yq"]

### Decisions made
- [Non-obvious choices — e.g., "Used environment variables instead of a config file because the values change per deployment"]

### Gotchas discovered
- [Things future agents should know — e.g., "The ORM silently truncates strings longer than the column width — validate length before insert"]

### Patterns that worked
- [Reusable approaches — e.g., "Wrapping third-party clients in an interface made testing straightforward"]
```

Include this section in the completion summary. If the user saves it (e.g., in a project doc or memory), it becomes searchable context for future tasks.

5. **Update plan status**: if a plan file exists for this work (`docs/plans/YYYY-MM-DD-<topic>.md`), update its status to `**Status**: Implemented`.
6. Ask the user what to do next (commit, review, continue)

---

## ✅ End of Step 4

Before marking complete, verify:
- [ ] You re-ran EVERY validation command from EVERY Task Completion Record (not some — all).
- [ ] You output the `## Final Validation Checklist` block showing pass/fail for each command.
- [ ] Any validation gap is flagged explicitly (command + reason + "must be verified manually before shipping").
- [ ] You called `TaskList` and confirmed all plan tasks are `completed` or `cancelled` (none left `in_progress` or `pending`).
- [ ] You presented the completion summary with tasks / files / deviations / concerns / code review / security review / per-task review effectiveness.
- [ ] You captured Learnings (Problems solved / Decisions made / Gotchas discovered / Patterns that worked).
- [ ] If a plan file exists: you updated its Status to `Implemented`.
- [ ] You asked the user what to do next (commit, review, continue).

**→ Skill complete.** All 4 steps of `/ops-implement` have been executed. The implementation is ready for the user's next action (typically `/ops-ship` to commit). There is no next file to read.
