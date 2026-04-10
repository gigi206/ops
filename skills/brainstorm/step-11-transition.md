# Step 11 — Transition


After the summary, offer a direct transition based on the complexity level chosen in Step 3:

**If Simple mode:**

> "This looks straightforward. Ready to implement? I can launch `/ops-do` directly with the scope we just defined."

If the user accepts, invoke `/ops-do` with the brainstorm summary as context. The user may also choose to escalate to `/ops-plan` if they changed their mind about complexity.

**If Normal or Complex mode:**

> "Ready to plan this? I can launch `/ops-plan` directly — it will skip the brainstorming phase since we just completed it, and start from research + design validation."

If the user accepts, invoke `/ops-plan` with a note that brainstorming is already done (the plan skill's Step 1 can be shortened to a recap rather than re-doing the full brainstorm). **Ensure the Brainstorm Summary block (Step 10) remains visible in conversation context so `/ops-plan` Step 8 can attach it verbatim to the critic dispatch** — without this, the critic's Lens 5 brainstorm trace check cannot run and architectural decisions invented post-brainstorm will not be flagged.

If the user wants to explore further, continue the conversation.

---

## ✅ End of Step 11

Before marking complete, verify:
- [ ] You offered the user a direct transition to `/ops-plan` as its own message.
- [ ] If the user accepted: the Step 10 Brainstorm Summary is still visible in conversation context, and you invoked `/ops-plan` with a note that brainstorming is already done.
- [ ] If the user declined: you continued the conversation without forcing the transition.

Mark the task "Brainstorm: finalize" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 11 steps of `/ops-brainstorm` have been executed. There is no next file to read.
