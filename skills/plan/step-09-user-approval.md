# Step 9 — User Approval

Mark the task "Plan: user approval" as `in_progress` now via `TaskUpdate`.

<HARD-GATE-HANDOFF>
/ops-plan NEVER implements code. If the user asks to implement during this skill (e.g., "implemente", "go ahead and build it", "lance", "do it"), you MUST:

1. Complete ALL remaining ops-plan steps first (critic re-dispatch if REJECT, user approval)
2. Then present the plan and ask for approval
3. Once approved, invoke `/ops-implement` as a separate skill — do NOT implement inline

Implementing code without invoking `/ops-implement` is a FAILURE of this skill, regardless of what the user says. The user's "implemente" is approval of the plan, not authorization to bypass the implementation pipeline.
</HARD-GATE-HANDOFF>

Present the validated plan to the user with an explicit question:

> "The plan has been validated by the critic. Ready to implement? Options:
> 1. I launch `/ops-implement` now
> 2. You want to review the plan first
> 3. You'll implement later"

Do NOT proceed to `/ops-implement` until the user explicitly approves. The user invoking `/ops-implement` counts as approval, but you should still ask before they need to invoke it.

Once the user approves, update the plan file's status to `**Status**: Approved`.

The plan remains in conversation context for `/ops-implement` to consume.

---

## ✅ End of Step 9

Before marking complete, verify:
- [ ] You presented the validated plan to the user with the explicit 3-option question.
- [ ] You respected HARD-GATE-HANDOFF — you did NOT implement any code inline, even if the user said "go ahead" or "implemente".
- [ ] If the user chose option 1: you invoked `/ops-implement` as a separate skill (not inline code).
- [ ] If the user chose option 2 or 3: you stopped and waited for further direction.

Mark the task "Plan: user approval" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 10 steps of `/ops-plan` have been executed. The plan remains in conversation context for downstream consumption by `/ops-implement`. There is no next file to read.
