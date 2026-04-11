# Step 12 — Transition


After the critic review (Step 11) is approved or overridden, offer a direct transition based on the complexity level chosen in Step 3:

**If Simple mode:**

> "This looks straightforward. Ready to implement? I can launch `/ops-do` directly with the scope we just defined."

If the user accepts, invoke `/ops-do` with the brainstorm summary as context. The user may also choose to escalate to `/ops-plan` if they changed their mind about complexity.

**If Normal or Complex mode:**

> "Ready to plan this? I can launch `/ops-plan` directly — it will skip the brainstorming phase since we just completed it, and start from research + design validation."

If the user accepts, invoke `/ops-plan` with a note that brainstorming is already done (the plan skill's Step 1 can be shortened to a recap rather than re-doing the full brainstorm). **Ensure the Brainstorm Summary block (Step 10) remains visible in conversation context so `/ops-plan` Step 8 can attach it verbatim to the critic dispatch** — without this, the critic's Lens 5 brainstorm trace check cannot run and architectural decisions invented post-brainstorm will not be flagged.

If the user wants to explore further, continue the conversation.

---

## ✅ End of Step 12

Before marking complete, verify:
- [ ] You offered the user a direct transition to `/ops-plan` as its own message.
- [ ] If the user accepted: the Step 10 Brainstorm Summary is still visible in conversation context, and you invoked `/ops-plan` with a note that brainstorming is already done.
- [ ] **If Step 11 produced a critic verdict** (APPROVE, SUGGESTIONS resolved, or REJECT overridden): the corresponding `**Brainstorm critic verdict**: …` line is present and visible inside the `## Brainstorm Summary` block handed off to `/ops-plan`. This line is load-bearing — `/ops-plan` Step 8 critic uses it as evidence the locked decisions were already reviewed. If the verdict line is missing (because the summary was edited, paraphrased, or regenerated after Step 11), STOP and re-append the verdict line before transitioning.
- [ ] **If Step 11 was skipped** (Simple or Normal mode, no invariant-class signal): no verdict line is required, but the Summary must still be intact and unmodified since Step 10.
- [ ] If the user declined: you continued the conversation without forcing the transition.

Mark the task "Brainstorm: finalize" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 12 steps of `/ops-brainstorm` have been executed. There is no next file to read.
