# Step 6 — Clarifying questions

**If Simple mode** (from Step 3): ask at most 1-2 clarifying questions, only if something is genuinely ambiguous. If the intent is already clear from Steps 2-3, skip to the End block. Do NOT ask questions just to fill the step.

**If Normal or Complex mode**: ask as many clarifying questions as needed, one at a time (per common_instructions rule 2).

- **Multiple choice preferred** — easier to answer than open-ended when possible. Use the **A/B/C question format**: list 2-4 lettered options (one per line) followed by a one-line recommendation. This is the canonical structure used throughout this skill.
- Focus on understanding: purpose, constraints, success criteria.
- The user's answer to question 1 may change what question 2 should be.

**Scope of this step**: Step 6 is for intent and context clarification only (purpose, constraints, success criteria, scoping). Architectural decisions — state location, decision ownership / authority, configuration & defaults, failure mode, interface surface placement, backward compatibility, test boundaries — are **not** asked here. They are handled in Step 7 with a mandatory checklist and structural templates. Do not anticipate Step 7's questions in Step 6.

---

## ✅ End of Step 6

Before proceeding, verify:
- [ ] Every question you asked was sent in its own message (never bundled with another question).
- [ ] Your questions targeted intent/context (purpose, constraints, success criteria, scoping) — NOT architectural decisions.
- [ ] You used the A/B/C format whenever possible.
- [ ] You have enough clarity about the user's goal to propose 2-3 macro-approaches in Step 7.

Mark the task "Brainstorm: clarify & explore" as `completed` via `TaskUpdate`.

**→ Next: read `skills/brainstorm/step-07-architectural-decisions.md` now and execute Step 7.**

Do NOT continue without reading that file first.
