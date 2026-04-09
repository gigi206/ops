# Step 1 — Clarify

This is the first step of `/ops-research`. Before dispatching any agents, you must (a) create the 6-task progress checklist and (b) clarify the user's question or topic.

## Preamble — create the task checklist

Create a task for each step of the research process (all at once, in a single `TaskCreate` call):

1. "Research: clarify"
2. "Research: parallel research"
3. "Research: synthesize"
4. "Research: conditional repo analysis"
5. "Research: final synthesis"
6. "Research: present"

Note: tasks 4 and 5 are **conditional** (see Step 3 for the branching logic). If Branch A is taken in Step 3 (no high-severity source verification gaps), mark tasks 4 and 5 as `completed` with note "not applicable — no high-severity source verification gaps" rather than leaving them pending.

Immediately after creating the checklist, mark the task "Research: clarify" as `in_progress` via `TaskUpdate`.

## What to do

Restate the user's question or topic in one sentence to confirm understanding. If the scope is too broad, ask ONE clarifying question before dispatching agents.

---

## ✅ End of Step 1

Before proceeding, verify:
- [ ] The 6 tasks exist in the task list (created via a single `TaskCreate` call).
- [ ] You restated the user's question/topic in one sentence.
- [ ] If the scope was ambiguous: you asked ONE clarifying question and got the answer from the user.
- [ ] You have a clear, scoped topic to dispatch the 3 research agents on.

Mark the task "Research: clarify" as `completed` via `TaskUpdate`.

**→ Next: read `skills/research/step-02-parallel-research.md` now and execute Step 2.**

Do NOT continue without reading that file first.
