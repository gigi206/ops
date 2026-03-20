---
name: ops:full
description: "Full pipeline: plan, implement, and ship in a single session."
---

# /ops:full — Full pipeline

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Purpose

Run the complete ops pipeline in a single session: plan the work, implement it, and ship it. This is a meta-skill that chains `/ops:plan` → `/ops:implement` → `/ops:ship`.

---

## Workflow

```
1. Plan → 2. User approval → 3. Implement → 4. Ship
```

---

## Step 1: Plan

Execute `/ops:plan` (Steps 0-9) in full. This includes:
- Environment setup (language detection + LSP diagnostic)
- Brainstorming with the user
- Context detection and parallel research
- Design approaches and spec writing
- Plan writing and critic review
- User approval of the plan

**Do NOT skip any step of `/ops:plan`.** The full pipeline does not mean a shortcut — it means running everything in sequence.

---

## Step 2: User Approval Gate

After `/ops:plan` completes, the user must explicitly approve the plan before proceeding.

**This is a hard gate.** Do NOT proceed to implementation without explicit user approval. The user saying "looks good" or "go ahead" counts as approval.

---

## Step 3: Implement

Execute `/ops:implement` (Steps 1-5) in full. This includes:
- Loading the plan and verifying task decomposition
- Executing tasks with the per-task pipeline (implementer → validation → conformity → discovery)
- Failure handling and circuit breaker
- Final review (code-reviewer + security-reviewer)
- Completion summary with learnings

---

## Step 4: Ship

Execute `/ops:ship` (Steps 1-6) in full. This includes:
- Final verification
- Change summary
- Commit (with user approval)
- PR creation (if requested)
- Learnings capture
- Rule proposals

---

## Constraints

- **Each sub-skill runs in full.** Do not skip steps within `/ops:plan`, `/ops:implement`, or `/ops:ship`.
- **User approval gates are preserved.** The user must approve the plan (Step 2) and the commit (within `/ops:ship`).
- **If any sub-skill fails or is blocked**, stop and present the situation to the user — do not silently skip to the next sub-skill.
