# Step 1 — Clarify Intent (MANDATORY — cannot be skipped)

Mark the task "Plan: clarify intent" as `in_progress` now via `TaskUpdate`.

## If `/ops-brainstorm` was already run

If the user ran `/ops-brainstorm` before invoking `/ops-plan`, the brainstorming is already done. In this case:
1. Read the brainstorm summary from the conversation
2. Output a short recap: chosen approach, scope, key decisions
3. Skip the clarity/scope checks below — the user already validated the approach
4. Jump to the Gate section at the bottom of this step (you still must output the `## Intent Confirmed` block)

## The Process (when brainstorm was NOT already run)

**Clarity check:**
Verify you can restate what is asked, why, and what success looks like. If you can't answer all 3 confidently, ask the user to clarify.

> Example: "Before I dive in — I want to make sure I understand. You want [restatement]. The goal is [why]. Is that right, or am I missing something?"

**Scope check:**
- If the request describes multiple independent subsystems, flag this and help the user decompose into sub-projects.
- Each sub-project gets its own spec → plan → implementation cycle.

**Offer deeper brainstorming:**
If the problem space is ambiguous, has multiple viable approaches, or would benefit from deeper exploration, suggest the user invoke `/ops-brainstorm` before continuing. Do NOT run a full brainstorming process yourself — that is the role of `/ops-brainstorm`.

> Example: "This has several possible approaches and some open questions. Want me to run `/ops-brainstorm` first to explore the options in depth, or is the direction clear enough to plan directly?"

## Gate

**Do NOT proceed to context detection until:**
- The objective is clear and confirmed by the user.
- The scope is agreed (single project or decomposed into sub-projects).

You MUST output this block before proceeding to Step 2:

```
## Intent Confirmed
- Objective: [one sentence]
- Scope: [one sentence]
- Brainstorm: not needed / already done / suggested to user
```

If this block does not appear in your output before Step 2, you have skipped a required step.

---

## ✅ End of Step 1

Before proceeding, verify:
- [ ] The objective is clear and confirmed by the user (either freshly confirmed or via the brainstorm recap).
- [ ] The scope is agreed (single coherent project, not multiple subsystems).
- [ ] You output the `## Intent Confirmed` block with Objective, Scope, and Brainstorm status.
- [ ] Your message to the user was a CONVERSATION (not an agent dispatch) — HARD-GATE-1 respected.

Mark the task "Plan: clarify intent" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-02-context-detection.md` now and execute Step 2.**

Do NOT continue without reading that file first.
