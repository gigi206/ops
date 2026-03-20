---
name: ops:brainstorm
description: "Interactive brainstorming to clarify needs and explore intent before planning."
---

# /ops:brainstorm — Interactive brainstorming

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Purpose

Clarify requirements and explore the user's intent through Socratic dialogue — before committing to a plan. Use this when the problem space is unclear, when the user wants to think through options, or as a standalone step before `/ops:plan`.

---

## Workflow

```
1. Clarity check → 2. Explore context → 3. Visual companion offer → 4. Assess scope → 5. Clarifying questions → 6. YAGNI filter → 7. Summary
```

---

## Step 1: Clarity check

Before exploring code or asking detailed questions, verify you understand the user's intent:
1. **What** is being asked? (Can you restate it in one sentence?)
2. **Why** does the user want this? (What problem does it solve?)
3. **What does success look like?** (How will the user know it works?)

If you can't answer all 3 confidently, ask the user to clarify **before** exploring. One short question, not three.

> Example: "Before I dive in — I want to make sure I understand. You want [restatement]. The goal is [why]. Is that right, or am I missing something?"

---

## Step 2: Explore project context

- Check the current project state (files, docs, recent commits)
- Understand existing structure and conventions before asking questions
- This informs your questions — ask smart questions, not generic ones

---

## Step 3: Visual companion offer

If upcoming questions will involve visual content (mockups, layouts, diagrams, architecture), offer the visual companion once for consent:

> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own message.** Do not combine with clarifying questions.

If the user declines, proceed with text-only brainstorming. If they agree, read `skills/plan/visual-companion.md` before proceeding.

---

## Step 4: Assess scope

- If the request describes multiple independent subsystems, flag this immediately
- Do NOT spend questions refining details of something that needs decomposition first
- Help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built?

---

## Step 5: Clarifying questions

- **One question at a time** — do NOT overwhelm with multiple questions. ONE question per message.
- **Multiple choice preferred** — easier to answer than open-ended when possible
- Focus on understanding: purpose, constraints, success criteria
- If you catch yourself writing "Question 4:", "Question 5:" in the same message — STOP. Pick the most important one, send it alone, wait.

---

## Step 6: YAGNI filter

Challenge the scope:
- Is every part of the request actually needed right now?
- Can a simpler version achieve the same goal?
- Are there features that "might be useful later" but aren't required? Remove them.
- Say explicitly what you're excluding and why. Let the user push back if they disagree.

---

## Step 7: Summary

When the objective is clear and the scope is agreed, present a concise summary:

```markdown
## Brainstorm Summary

### Objective
[One sentence]

### Scope
- [What's included]

### Out of scope
- [What was explicitly excluded and why]

### Key decisions
- [Decisions made during brainstorming]

### Open questions
- [Anything still unresolved]
```

Then ask: "Ready to plan this with `/ops:plan`, or do you want to explore further?"

---

## Constraints

- **Do NOT make changes.** This skill is discussion-only — no edits, no commits.
- **Do NOT plan.** If the user wants to plan, suggest `/ops:plan`.
- **Do NOT dispatch agents.** This is a direct conversation with the user. If research is needed, suggest `/ops:research`.
- **Every project goes through this.** "Simple" projects are where unexamined assumptions cause the most wasted work.
