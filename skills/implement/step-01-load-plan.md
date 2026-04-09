# Step 1 — Load Plan, Verify Task Decomposition, and Create Tasks

Read the plan from the conversation context or from the file the user specifies.

**Gate**: Verify the plan has a proper task breakdown:
- [ ] Plan contains an ordered list of discrete tasks
- [ ] Each task has: description, files, change details, and validation command
- [ ] Tasks are ordered by dependency

**If the plan has no task breakdown or tasks are incomplete**: STOP. Do NOT implement. Tell the user to run `/ops-plan` first or to decompose the plan into tasks before proceeding.

## Register tasks

After verifying the plan, create a task entry for each plan task, set to pending.

This ensures task progress survives context compaction and is visible throughout the session.

---

## ✅ End of Step 1

Before proceeding, verify:
- [ ] The plan has been read (from conversation context or the file the user specified).
- [ ] Every plan task has description + files + change details + validation command.
- [ ] Tasks are ordered by dependency.
- [ ] You created a `TaskCreate` entry for each plan task, set to pending.
- [ ] Task progress is visible in the task list.

**→ Next: read `skills/implement/step-02-execute-tasks.md` now and execute Step 2.**

Do NOT continue without reading that file first.
