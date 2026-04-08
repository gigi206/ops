# Step 11 — Transition

Mark the task "Brainstorm: transition" as `in_progress` now via `TaskUpdate`.

After the summary, offer a direct transition to planning:

> "Ready to plan this? I can launch `/ops-plan` directly — it will skip the brainstorming phase since we just completed it, and start from research + spec writing."

If the user accepts, invoke `/ops-plan` with a note that brainstorming is already done (the plan skill's Step 1 can be shortened to a recap rather than re-doing the full brainstorm). **Ensure the Brainstorm Summary block (Step 10) remains visible in conversation context so `/ops-plan` Step 8 can attach it verbatim to the critic dispatch** — without this, the critic's Lens 5 brainstorm trace check cannot run and architectural decisions invented post-brainstorm will not be flagged.

If the user wants to explore further, continue the conversation.

---

## ✅ End of Step 11

Before marking complete, verify:
- [ ] You offered the user a direct transition to `/ops-plan` as its own message.
- [ ] If the user accepted: the Step 10 Brainstorm Summary is still visible in conversation context, and you invoked `/ops-plan` with a note that brainstorming is already done.
- [ ] If the user declined: you continued the conversation without forcing the transition.

Mark the task "Brainstorm: transition" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 11 steps of `/ops-brainstorm` have been executed. There is no next file to read.
