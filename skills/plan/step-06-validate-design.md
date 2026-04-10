# Step 6 — Validate Design

Mark the task "Plan: validate design" as `in_progress` now via `TaskUpdate`.

After the user has chosen an approach, validate the design before writing the plan.

## If `/ops-brainstorm` Step 8 already validated design sections

The brainstorm presented the design section by section and the user approved each one. Do NOT re-present section by section — this would duplicate validated work.

**Instead:**
1. List the sections validated during brainstorm (from the brainstorm summary's "Design sections validated" field).
2. Mention any adjustments from delta research (Step 3/4) or invalidated decisions (Step 5).
3. Ask: "These design sections were validated during brainstorm: [list]. [Any adjustments noted.] Anything to change before I write the plan, or should I proceed?"
4. If the user says proceed → go directly to End of Step 6.
5. If the user wants changes → re-present and re-validate ONLY the changed sections, not all of them.

## When brainstorm was NOT already run (or Step 8 was not completed)

Present the design **section by section** — not as a single wall of text. Each section should be validated by the user before moving to the next.

- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover across sections: architecture, components, data flow, error handling, testing strategy
- **Ask after each section**: "Does this look right so far?" — wait for the user to validate
- If the user requests changes to a section, revise it and re-present before moving on

**Design for isolation and clarity:**
- Break the system into smaller units that each have one clear purpose
- Communicate through well-defined interfaces
- Can someone understand what a unit does without reading its internals?
- Smaller, well-bounded units are easier to implement, test, and review

---

## ✅ End of Step 6

Before proceeding, verify:
- [ ] **If post-brainstorm**: you listed the validated sections, noted any adjustments, and asked the user to confirm or request changes. OR:
- [ ] **If no prior brainstorm**: you presented the design section by section (not as a wall of text), asked for validation after each section, and the user approved each one (possibly after revisions).

Mark the task "Plan: validate design" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-07-write-plan.md` now and execute Step 7.**

Do NOT continue without reading that file first.
