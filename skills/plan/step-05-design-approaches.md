# Step 5 — Design Approaches

Mark the task "Plan: design approaches" as `in_progress` now via `TaskUpdate`.

## If `/ops-brainstorm` already locked an approach

The brainstorm locked a macro-approach (Step 7) and validated a design section by section (Step 8). Do NOT re-propose approaches.

**Instead:**
1. State the locked approach and key architectural decisions from the brainstorm summary.
2. Check if delta research (Step 3/4) revealed anything that **invalidates** a locked decision. If yes, flag it to the user: "Research found [X] which contradicts brainstorm decision [Y]. Do you want to revisit this decision, or proceed as planned?"
3. **External dependencies**: if the brainstorm identified external dependencies the user already approved, they are validated. For any NEW external dependency that emerged during delta research (Step 3/4), apply the dependency validation process below:
   - Present the dependency with why / alternatives / risk profile
   - Wait for user approval before proceeding
4. If no invalidation and no new dependencies: proceed directly to Step 6.

**Skip** the approach proposal, alternatives presentation, and the "lead with your recommendation" process below.

---

## Propose approaches (when brainstorm was NOT already run)

Based on research results, propose **2-3 approaches** to the user.

## For each approach

- **Name**: Short label (e.g., "Approach A: extend existing module" / "Approach B: new standalone component")
- **How it works**: 2-3 sentences
- **Pros**: Why this approach is good
- **Cons**: What are the tradeoffs
- **Fits conventions**: Does it match existing patterns found by researcher-code?
- **Reuse**: Does existing code already solve part of this? Could we extend it instead of building from scratch?

## Presentation rules

- **Lead with your recommendation** — present the recommended option first, explain why it's best, then present alternatives
- **Be conversational** — adapt the format to the context. A simple choice can be 3 sentences per option. A complex architectural decision needs more depth.
- **Use the visual companion** if active — for choices with visual implications (layouts, architectures, data flows), show side-by-side comparisons in the browser instead of describing them in text
- **Always present at least one alternative** — even if one approach is clearly superior. The user needs to make an informed decision, not rubber-stamp yours.

## External Dependency Validation (MANDATORY)

Before proceeding to design validation, identify ALL external dependencies that emerged during the design — components, libraries, tools, charts, images, or services that the project does not already use.

**Distinguish between:**
- **User-requested dependencies** — the user explicitly asked for this ("add rate limiting with Redis") → already validated
- **Agent-chosen dependencies** — you selected this to fulfill the request ("use library X for the UI") → NOT validated, MUST ask

For each agent-chosen dependency, present to the user:

> "To implement [feature], I'd use **[dependency name]** ([source/maintainer]).
> - **Why**: [what it provides]
> - **Alternatives**: [at least 1 alternative + "build it ourselves" if feasible]
> - **Risk**: [maintenance status, maturity, last release]
> Which option do you prefer?"

## Gate

Do not proceed to design validation until the user has chosen an approach and validated all external dependencies. If you chose a dependency, the user must approve it — "Implement X" does not mean the user validated every sub-component.

If a dependency was already validated conversationally during intent clarification or brainstorming, you do not need to re-ask — but you must still present its risk profile (maintenance status, last release, community size) if not covered during the conversation.

If the plan contains an agent-chosen dependency that was never presented to the user, you have FAILED this skill.

---

## ✅ End of Step 5

Before proceeding, verify:

**If post-brainstorm (approach already locked):**
- [ ] You stated the locked approach and key architectural decisions.
- [ ] You checked delta research for invalidations and flagged any to the user.
- [ ] New external dependencies (if any) were validated with the user.

**If no prior brainstorm:**
- [ ] You proposed 2-3 named approaches with name / how it works / pros / cons / fits conventions / reuse.
- [ ] You led with your recommendation and presented at least one alternative.
- [ ] You identified ALL external dependencies that emerged during design.
- [ ] For each agent-chosen dependency: you presented it to the user with alternatives + risk profile, and got explicit approval.
- [ ] The user explicitly chose one approach before you proceed.

Mark the task "Plan: design approaches" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-06-validate-design.md` now and execute Step 6.**

Do NOT continue without reading that file first.
