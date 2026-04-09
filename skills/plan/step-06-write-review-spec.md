# Step 6 — Write & Review Spec

Mark the task "Plan: write & review spec" as `in_progress` now via `TaskUpdate`.

After the user has chosen an approach, flesh it out into a full design and persist it. This step has four sub-steps (6a → 6b → 6c → 6d) that must be executed in order.

## 6a. Present the design by sections

Present the design **section by section** — not as a single wall of text. Each section should be validated by the user before moving to the next.

- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover across sections: architecture, components, data flow, error handling, testing strategy
- **Ask after each section**: "Does this look right so far?" — wait for the user to validate
- If the user requests changes to a section, revise it and re-present before moving on
- The spec-reviewer (Step 6c) will validate the full spec — but section-by-section validation catches misunderstandings early

**Design for isolation and clarity:**
- Break the system into smaller units that each have one clear purpose
- Communicate through well-defined interfaces
- Can someone understand what a unit does without reading its internals?
- Smaller, well-bounded units are easier to implement, test, and review

## 6b. Write spec document

Write the spec to `docs/specs/YYYY-MM-DD-<topic>-design.md`. Do NOT commit — the user decides when to commit.

The spec captures the **what** and **why** — the plan (Step 7) captures the **how** (task breakdown).

Set `**Status**: Draft` in the spec header.

User preferences for spec location override the default path.

## 6c. Spec review loop

Dispatch the **spec-reviewer** agent to verify the spec is complete and ready for planning.

1. If **Issues Found**:
   - If the reviewer found **security-related issues** (permissions too broad, missing access checks, data exposure), present them to the user and wait for direction before fixing — security decisions should be transparent, not silently resolved.
   - Fix the issues (for security issues, follow the user's direction).
   - **Re-dispatch the spec-reviewer** following the `ops-redispatch-optimization` process. This re-dispatch is MANDATORY — the reviewer must confirm the fixes are adequate.
2. Repeat until **Approved** (max 3 iterations).
3. If still not approved after 3 iterations, surface the remaining issues to the user for guidance.

## 6d. Present to user

After the spec review loop passes, ask the user to review:

> "Spec written to `<path>`. Please review it and let me know if you want to make any changes before we start writing the implementation plan."

Do NOT commit the spec. The user decides when to commit (via `/ops-ship` or manually).

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

Once the user approves, update the spec status to `**Status**: Approved`.

---

## ✅ End of Step 6

Before proceeding, verify ALL four sub-steps completed:

**Sub-step 6a — present by sections:**
- [ ] You presented the design section by section, not as a wall of text.
- [ ] You explicitly asked for validation after each section.
- [ ] The user approved each section (possibly after revisions).

**Sub-step 6b — write spec file:**
- [ ] You wrote the spec to `docs/specs/YYYY-MM-DD-<topic>-design.md` (or a user-specified path).
- [ ] The spec header has `**Status**: Draft`.
- [ ] You did NOT commit the file.

**Sub-step 6c — spec review loop:**
- [ ] You dispatched the `spec-reviewer` agent at least once.
- [ ] Any security-related issues were presented to the user before being fixed.
- [ ] If Issues Found: you fixed them and re-dispatched via the `ops-redispatch-optimization` process (max 3 iterations).
- [ ] The spec is now Approved by the reviewer, OR you surfaced unresolved issues to the user for guidance.

**Sub-step 6d — present to user:**
- [ ] You presented the spec path to the user and asked for their review.
- [ ] The user explicitly approved the spec (possibly after revisions that triggered another 6c review loop).
- [ ] You updated the spec header to `**Status**: Approved`.

Mark the task "Plan: write & review spec" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-07-write-plan.md` now and execute Step 7.**

Do NOT continue without reading that file first.
