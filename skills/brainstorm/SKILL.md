---
name: ops-brainstorm
description: "Interactive brainstorming to clarify needs and explore intent before planning. Creates tasks for progress tracking."
---

# /ops-brainstorm — Interactive brainstorming

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Purpose

Clarify requirements and explore the user's intent through Socratic dialogue — before committing to a plan. Use this when the problem space is unclear, when the user wants to think through options, or as a standalone step before `/ops-plan`.

---

## Workflow

```
1. Create task checklist → 2. Clarity check → 3. Explore context → 4. Visual companion offer → 5. Assess scope → 6. Clarifying questions → 7. Propose approaches → 8. Present design by sections → 9. YAGNI filter → 10. Summary → 11. Transition
```

---

## Step 1: Create task checklist

Create a task for each step of the brainstorming process. This makes progress visible and prevents skipping steps.

Create these tasks (all at once, in a single message):

1. "Brainstorm: clarity check"
2. "Brainstorm: explore project context"
3. "Brainstorm: visual companion offer"
4. "Brainstorm: assess scope"
5. "Brainstorm: clarifying questions"
6. "Brainstorm: propose 2-3 approaches"
7. "Brainstorm: present design by sections"
8. "Brainstorm: YAGNI filter"
9. "Brainstorm: summary & transition"

Mark each task as `in_progress` when you start it and `completed` when done.

---

## Step 2: Clarity check

Before exploring code or asking detailed questions, verify you understand the user's intent:
1. **What** is being asked? (Can you restate it in one sentence?)
2. **Why** does the user want this? (What problem does it solve?)
3. **What does success look like?** (How will the user know it works?)

If you can't answer all 3 confidently, ask the user to clarify **before** exploring. One short question, not three.

> Example: "Before I dive in — I want to make sure I understand. You want [restatement]. The goal is [why]. Is that right, or am I missing something?"

---

## Step 3: Explore project context

- Check the current project state (files, docs, recent commits)
- Understand existing structure and conventions before asking questions
- This informs your questions — ask smart questions, not generic ones

---

## Step 4: Visual companion offer

If upcoming questions will involve visual content (mockups, layouts, diagrams, architecture), offer the visual companion once for consent:

> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own message.** Do not combine with clarifying questions.

If the user declines, proceed with text-only brainstorming. If they agree, read `skills/plan/visual-companion.md` before proceeding.

If the topic has no visual component, mark the task as completed with note "not applicable" and move on.

---

## Step 5: Assess scope

- If the request describes multiple independent subsystems, flag this immediately
- Do NOT spend questions refining details of something that needs decomposition first
- Help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built?

---

## Step 6: Clarifying questions

- **One question at a time** — do NOT overwhelm with multiple questions. ONE question per message.
- **Multiple choice preferred** — easier to answer than open-ended when possible
- Focus on understanding: purpose, constraints, success criteria
- If you catch yourself writing "Question 4:", "Question 5:" in the same message — STOP. Pick the most important one, send it alone, wait.
- The user's answer to question 1 may change what question 2 should be.

---

## Step 7: Propose 2-3 approaches

Once you understand the problem space, propose **2-3 different approaches** with trade-offs.

### For each approach:
- **Name**: Short label (e.g., "A: extend existing module" / "B: new standalone component")
- **How it works**: 2-3 sentences
- **Pros**: Why this approach is good
- **Cons**: What are the tradeoffs
- **Recommendation**: Lead with the recommended option and explain why

### Presentation rules:
- **Lead with your recommendation** — present the best option first, then alternatives
- **Be conversational** — a simple choice can be 3 sentences per option. A complex decision needs more depth.
- **Use the visual companion** if active — for choices with visual implications, show side-by-side comparisons
- **Always present at least one alternative** — the user needs to make an informed decision, not rubber-stamp yours

**Wait for the user to choose** before proceeding. Do NOT skip this step even if one approach seems obviously better.

---

## Step 8: Present design by sections

Present the chosen approach's design **section by section**, not as a single wall of text. Each section should be validated by the user before moving to the next.

### How to section the design:
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover across sections: architecture, components, data flow, error handling, testing strategy
- **Ask after each section**: "Does this look right so far?" or "Any changes to this part?"

### Example flow:
```
→ "Section 1 — Data model: [description]" → user approves
→ "Section 2 — Backend logic: [description]" → user wants a change → revise → user approves
→ "Section 3 — Frontend integration: [description]" → user approves
→ "Section 4 — Testing strategy: [description]" → user approves
```

### Design for isolation and clarity:
- Break the system into smaller units that each have one clear purpose
- Communicate through well-defined interfaces
- Can someone understand what a unit does without reading its internals?

### Working in existing codebases:
- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work, include targeted improvements as part of the design.
- Do NOT propose unrelated refactoring. Stay focused on what serves the current goal.

---

## Step 9: YAGNI filter

Challenge the scope:
- Is every part of the request actually needed right now?
- Can a simpler version achieve the same goal?
- Are there features that "might be useful later" but aren't required? Remove them.
- Say explicitly what you're excluding and why. Let the user push back if they disagree.

You MUST present a YAGNI assessment:

```
## YAGNI Check
- Kept: [features retained and why they're needed now]
- Removed/Deferred: [features excluded and why] (or "None — scope is already minimal")
```

---

## Step 10: Summary

When the objective is clear and the scope is agreed, present a concise summary:

```markdown
## Brainstorm Summary

### Objective
[One sentence]

### Chosen approach
[Name and one-line description]

### Scope
- [What's included]

### Out of scope
- [What was explicitly excluded and why]

### Key decisions
- [Decisions made during brainstorming, including approach selection]

### Design sections validated
- [List each section the user approved]

### Open questions
- [Anything still unresolved]
```

---

## Step 11: Transition

After the summary, offer a direct transition to planning:

> "Ready to plan this? I can launch `/ops-plan` directly — it will skip the brainstorming phase since we just completed it, and start from research + spec writing."

If the user accepts, invoke `/ops-plan` with a note that brainstorming is already done (the plan skill's Step 1 can be shortened to a recap rather than re-doing the full brainstorm).

If the user wants to explore further, continue the conversation.

---

## Constraints

- **Do NOT make changes.** This skill is discussion-only — no edits, no commits.
- **Do NOT write specs or plans.** If the user wants to plan, transition to `/ops-plan`.
- **Do NOT dispatch agents.** This is a direct conversation with the user. If research is needed, suggest `/ops-research`.
- **Every project goes through this.** "Simple" projects are where unexamined assumptions cause the most wasted work.
- **Track progress.** Mark each task as completed as you finish it. The user should be able to see where you are in the process.
