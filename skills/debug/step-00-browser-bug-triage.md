# Step 0 — Browser Bug Triage

This is the first step of `/ops-debug`. Before doing any investigation, you must (a) create the 8-task progress checklist and (b) determine if the bug involves browser/frontend behavior.

## Preamble — create the task checklist

Create a task for each step of the debugging process (all at once, in a single `TaskCreate` call):

1. "Debug: browser bug triage"
2. "Debug: investigate"
3. "Debug: hypothesize"
4. "Debug: test hypotheses"
5. "Debug: fix"
6. "Debug: code review"
7. "Debug: discovery check"
8. "Debug: verify"

Each task will be marked as `in_progress` at the start of the corresponding step file, and as `completed` at its end.

Immediately after creating the checklist, mark the task "Debug: browser bug triage" as `in_progress` via `TaskUpdate`.

## What to do

If the bug involves browser/frontend behavior (console errors, UI rendering, network from frontend, performance, accessibility): use `chrome-devtools-mcp` skills (`chrome-devtools`, `debug-optimize-lcp`, `a11y-debugging`, `troubleshooting`) for evidence gathering (Step 1), hypothesis testing (Step 3), and verification (Step 7).

If chrome-devtools-mcp is not installed, skip — investigate with standard tools.

If the bug is not browser-related (backend, CLI, infrastructure, build tooling, etc.), this step is not applicable — note it and proceed.

---

## ✅ End of Step 0

Before proceeding, verify:
- [ ] The 8 tasks exist in the task list (created via a single `TaskCreate` call).
- [ ] You determined whether the bug is browser-related.
- [ ] If browser-related AND chrome-devtools-mcp is installed: you noted which chrome-devtools-mcp skills you will use in Steps 1, 3, 7.
- [ ] If not browser-related OR chrome-devtools-mcp is not installed: you noted the step as not applicable.

Mark the task "Debug: browser bug triage" as `completed` via `TaskUpdate`.

**→ Next: read `skills/debug/step-01-investigate.md` now and execute Step 1.**

Do NOT continue without reading that file first.
