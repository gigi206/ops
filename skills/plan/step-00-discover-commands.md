# Step 0 — Discover Project Commands (MANDATORY — runs FIRST)

This is the first step of `/ops-plan`. Before doing any work, you must (a) create the 10-task progress checklist and (b) discover the project's actual test/build/lint commands.

## Preamble — create the task checklist

Create a task for each step of the planning process (all at once, in a single `TaskCreate` call):

1. "Plan: discover commands"
2. "Plan: clarify intent"
3. "Plan: context detection"
4. "Plan: parallel research"
5. "Plan: research adequacy check"
6. "Plan: design approaches"
7. "Plan: write & review spec"
8. "Plan: write plan"
9. "Plan: critic review"
10. "Plan: user approval"

Each task will be marked as `in_progress` at the start of the corresponding step file, and as `completed` at its end.

Immediately after creating the checklist, mark the task "Plan: discover commands" as `in_progress` via `TaskUpdate`.

## Reminder — bootstrap hard gates

You should have already read the two top-level hard gates in `skills/plan/SKILL.md`:
- **HARD-GATE-0**: your VERY FIRST action must be this step (discover commands), not design questions.
- **HARD-GATE-1**: after this step completes, your NEXT message MUST be a clarity check WITH the user, not an agent dispatch. Dispatching ANY agent as your first action after Step 0 — regardless of type — is a FAILURE of this skill.

## What to do

Discover the project's actual test/build/lint commands by checking: `Makefile` targets, `bin/` scripts, `package.json` scripts, `docker-compose` services, `tox.ini`, `noxfile.py`, or similar. Use these discovered commands — not generic ones (`python -m pytest`, `npm test`) — in task validation commands throughout the plan.

You MUST output this block before proceeding to Step 1:

```
## Discovered Commands
- Test: `<command>` (source: Makefile / package.json / tox.ini / ...)
- Build: `<command>`
- Lint: `<command>`
- Not found: [list what was checked but not found]
```

If this block does not appear in your output before Step 1, you have skipped a required step.

## Environment Health Check

If during command discovery you notice signs of a misconfigured environment (e.g., no `node_modules` but `package.json` exists, broken `Makefile`, missing `.venv`), propose to the user:

> "Your environment may not be fully set up. Want to run `/ops-init` first to diagnose LSP, tools, and dependencies? Or should we continue as-is?"

Wait for the user's decision before proceeding to Step 1. If they want to run init, let them invoke `/ops-init` and resume planning afterward.

---

## ✅ End of Step 0

Before proceeding, verify:
- [ ] The 10 tasks above exist in the task list (created via a single `TaskCreate` call).
- [ ] You output the `## Discovered Commands` block with concrete commands (or explicit "Not found" entries).
- [ ] If environment issues were detected: you proposed `/ops-init` to the user and got their decision.
- [ ] Your next action (after reading the next file) will be a CONVERSATION with the user, NOT an agent dispatch (per HARD-GATE-1).

Mark the task "Plan: discover commands" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-01-clarify-intent.md` now and execute Step 1.**

Do NOT continue without reading that file first.
