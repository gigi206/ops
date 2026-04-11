# Step 10 — Summary


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

For each dimension from the Step 7 checklist that applies, list the user's chosen answer (preserve the user's exact wording for dimensions 2/3/4 where the structural templates apply). Mark non-applicable dimensions explicitly with N/A and the reason. This is the structured trace the critic's Lens 5 brainstorm trace check consumes downstream.

- **Dimension 1 — State / data location**: [chosen value, e.g. "existing config table — no migration" / "new dedicated store"] OR `N/A — no new persistent state`
- **Dimension 2 — Source of authority (decision ownership)**: [user's answer to Dimension 2 template, e.g. "A — centralized owner, service X computes the decision" / "B — local, each consumer decides from its own state"] OR `N/A — no shared decision to assign`
- **Dimension 3 — Configuration & defaults**: [user's answer to Dimension 3 template, e.g. "C — disabled by default, global config lets operators change the default" / "D — hardcoded constant"] OR `N/A — feature has no toggle/policy`
- **Dimension 4 — Failure mode**: [user's answer to Dimension 4 template, e.g. "A — fail-closed, deny by default" / "B — fail-open, allow by default"] OR `N/A — no async/external dependency`
- **Dimension 5 — Interface surface placement**: [exact placement confirmed by user, e.g. "new CLI subcommand under existing group" / "new API endpoint in v2 namespace" / "new section in admin UI"] OR `N/A — no interface change`
- **Dimension 6 — Backward compatibility**: [chosen value, e.g. "existing data preserved as-is, new default OFF" / "lazy migration on access"] OR `N/A — no behavior change for existing consumers`
- **Dimension 7 — Test boundaries**: [chosen value, e.g. "unit + integration" / "e2e only"] OR `N/A — trivial change`

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
- [ ] Dimensions 2, 3, 4 — if applicable — are listed with the user's exact wording (not a summary or paraphrase).
- [ ] The summary block is visible in your current conversation context and will remain so when Steps 11 and 12 reference it.

Do NOT mark the milestone task completed yet — Steps 11 and 12 remain.

**→ Next: read `skills/brainstorm/step-11-critic-review.md` now and execute Step 11.**

Do NOT continue without reading that file first.
