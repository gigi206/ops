# Step 10 — Summary

Mark the task "Brainstorm: summary" as `in_progress` now via `TaskUpdate`.

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

### Architectural decisions (per dimension)

For each dimension from the Step 7 checklist that applies, list the user's chosen answer (verbatim for dimensions 2/3/4 where the inline templates apply). Mark non-applicable dimensions explicitly with N/A and the reason. This is the structured trace the critic's Lens 5 brainstorm trace check consumes downstream.

- **Dimension 1 — Storage location**: [chosen value, e.g. "existing Room.configuration JSONField — no migration"] OR `N/A — no new persistent state`
- **Dimension 2 — Source of truth for permissions**: [verbatim answer to Dimension 2 template, e.g. "A — server-driven via abilities.can_X exposed in serializer"] OR `N/A — feature does not touch permissions`
- **Dimension 3 — Instance-wide defaults**: [verbatim answer to Dimension 3 template, e.g. "C — env var RECORDING_X_BY_DEFAULT with per-room override"] OR `N/A — feature has no toggle/policy`
- **Dimension 4 — Failure mode**: [verbatim answer to Dimension 4 template, e.g. "A — fail-closed, deny by default"] OR `N/A — no async/external dependency`
- **Dimension 5 — UI placement**: [exact placement confirmed by user, e.g. "new section at bottom of Admin panel, after Access section"] OR `N/A — no UI change`
- **Dimension 6 — Backward compatibility**: [chosen value, e.g. "existing rooms preserved as-is, default OFF"] OR `N/A — no behavior change for existing data`
- **Dimension 7 — Test boundaries**: [chosen value, e.g. "backend pytest unit + integration; no frontend tests (no test runner)"] OR `N/A — trivial change`

### Other key decisions
- [Decisions made during brainstorming that are not architectural-dimension answers — e.g. naming, scope clarifications, deferred follow-ups]

### Design sections validated
- [List each section the user approved]

### Open questions
- [Anything still unresolved — but NOT architectural decisions, which must be locked here]
```

---

## ✅ End of Step 10

Before proceeding, verify:
- [ ] You produced a `## Brainstorm Summary` block containing ALL of: Objective, Chosen approach, Scope, Out of scope, Architectural decisions (per dimension), Other key decisions, Design sections validated, Open questions.
- [ ] The Architectural decisions block lists ALL 7 dimensions (with `N/A — [reason]` for dimensions that do not apply).
- [ ] Dimensions 2, 3, 4 — if applicable — are listed with the user's verbatim answer (not a summary).
- [ ] The summary block is visible in your current conversation context and will remain so when Step 11 references it.

Mark the task "Brainstorm: summary" as `completed` via `TaskUpdate`.

**→ Next: read `skills/brainstorm/step-11-transition.md` now and execute Step 11.**

Do NOT continue without reading that file first.
