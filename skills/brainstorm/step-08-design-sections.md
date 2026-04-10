# Step 8 — Present design by sections

**If Simple mode** (from Step 3): present the design as a **single concise block** (not section by section). Cover the key points: what changes, where, and how. Ask for confirmation once. Then proceed to Step 10 (skip Step 9 — YAGNI is merged into the summary).

**If Normal mode**: present the chosen approach's design **section by section**, not as a single wall of text. Each section should be validated by the user before moving to the next.

**If Complex mode**: same as Normal (section by section), but also **document the rejected alternatives** for each major design decision: "We chose X because [reason]. Alternative Y was considered but rejected because [reason]." This feeds the critic's Lens 5 brainstorm trace check and helps future maintainers understand why the design looks the way it does.

## How to section the design

- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover across sections: architecture, components, data flow, error handling, testing strategy
- **Ask after each section**: "Does this look right so far?" or "Any changes to this part?"

## Example flow

```
→ "Section 1 — Data model: [description]" → user approves
→ "Section 2 — Backend logic: [description]" → user wants a change → revise → user approves
→ "Section 3 — Frontend integration: [description]" → user approves
→ "Section 4 — Testing strategy: [description]" → user approves
```

## Design for isolation and clarity

- Break the system into smaller units that each have one clear purpose
- Communicate through well-defined interfaces
- Can someone understand what a unit does without reading its internals?

## Working in existing codebases

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work, include targeted improvements as part of the design.
- Do NOT propose unrelated refactoring. Stay focused on what serves the current goal.

---

## ✅ End of Step 8

Before proceeding, verify:
- [ ] You presented the design as discrete sections, not as a single wall of text.
- [ ] You explicitly asked for validation after each section ("Does this look right so far?" or equivalent).
- [ ] The user approved every section (possibly after revisions).
- [ ] The design follows existing codebase patterns and respects isolation/clarity principles.
- [ ] You did NOT propose unrelated refactoring beyond what the current goal requires.

Mark the task "Brainstorm: architectural decisions" as `completed` via `TaskUpdate`.

**→ If Simple: read `skills/brainstorm/step-10-summary.md` now and execute Step 10** (skip Step 9 — include a brief YAGNI note in the summary instead).

**→ If Normal or Complex: read `skills/brainstorm/step-09-yagni-filter.md` now and execute Step 9.**

Do NOT continue without reading the correct file first.
