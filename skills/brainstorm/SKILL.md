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
1. Create task checklist → 2. Clarity check → 3. Explore context → 4. Visual companion offer → 5. Assess scope → 6. Clarifying questions → 7. Propose approaches [HARD GATE — architectural lock] → 8. Present design by sections → 9. YAGNI filter → 10. Summary → 11. Transition
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
- **Multiple choice preferred** — easier to answer than open-ended when possible. Prefer the **A/B/C question format** (list 2-4 lettered options, one per line, with a one-line recommendation at the end), which is the canonical structure used by the mandatory templates below AND by Step 7's approach proposals.
- Focus on understanding: purpose, constraints, success criteria
- If you catch yourself writing "Question 4:", "Question 5:" in the same message — STOP. Pick the most important one, send it alone, wait.
- The user's answer to question 1 may change what question 2 should be.

### Mandatory question templates (when applicable)

**Structure of this section** (read this first):
- Step 6 (here) defines question **templates** for 3 architectural dimensions.
- Step 7 below contains the **full checklist** of 7 architectural dimensions and the gate that verifies all applicable dimensions have been addressed before moving to Step 8.
- These 3 templates correspond to 3 of the 7 dimensions in Step 7's checklist — the ones where vague wording is most likely to silently hide an architectural decision (instance defaults, authorization source of truth, failure mode). For the other 4 dimensions (storage, UI placement, backward compat, test boundaries), use the plain A/B/C question format defined above — no specific template is required because the choices are usually framed unambiguously by the question itself.

When the feature triggers the "applies if" condition for one of these 3 templates, you MUST present the question in the templated format below — the structure is what protects against vagueness. The Step 7 dimensions checklist verifies that all applicable dimensions (templated or not) have been addressed before moving to Step 8.

#### Template A — Deployment-instance defaults

**Applies if**: the feature introduces any toggle, flag, setting, policy, or per-resource configuration.

> **Question — default behavior and override**
>
> For this new [toggle / setting / policy], how is the default value handled?
>
> - **A)** Disabled by default, explicit per-resource opt-in. No environment variable.
> - **B)** Enabled by default, explicit per-resource opt-out. No environment variable.
> - **C)** Disabled by default, **but** an environment variable / Django setting / instance config lets operators change the default at instance scope, with per-resource override still possible.
> - **D)** Always forced to a fixed value, no configuration possible (hardcoded constant).
>
> My recommendation: [A/B/C/D] because [context-specific reason]. This is an important deployment decision — option C is often what separates a feature that is "usable in self-hosted deployments" from one that is "only usable with per-resource tweaks".

This question is mandatory for any feature that exposes a toggle/policy. Skipping it leads to features that work for the dev environment but cannot be configured per-instance.

#### Template B — Source of truth for authorization

**Applies if**: the feature touches permissions, visibility, "who can do what", admin/owner/member distinctions, or any UI element conditionally shown based on the user's rights.

> **Question — where the authorization logic lives**
>
> The frontend needs to know whether the current user can [action]. Where does that decision live?
>
> - **A) Server-driven** — the backend computes an `ability` (boolean) and exposes it via the API (e.g. `room.abilities.can_X = true/false`). The frontend just reads the boolean and renders the UI conditionally. No duplication of the permission rule.
> - **B) Client-driven** — the frontend reads the raw state (role, configuration, metadata) and computes the decision itself. Faster to implement but duplicates the logic with the backend (drift risk).
> - **C) Hybrid** — the frontend reconciles multiple sources (local state + shared metadata + backend role). Often tempting when the infrastructure already exists, but introduces complex failure modes (fail-closed flicker, fire-and-forget propagation).
>
> My recommendation: **A**, unless latency or a real-time context forbids it. The rule must have a single owner: the backend. The frontend should never re-decide a permission the backend has already evaluated.

This question is mandatory for any permission/auth/visibility feature. Skipping it tends to push the design toward "extend whatever channel is already there" (option C) instead of "define a clean ability" (option A).

#### Template C — Failure mode

**Applies if**: the feature depends on async work, external services, fire-and-forget propagation, or any source of state that can be unavailable.

> **Question — behavior on failure**
>
> If [the source of truth, e.g. shared room metadata, the external API, the worker] fails or is unavailable:
>
> - **A) Fail-closed** — the action is denied by default. The user sees an error. Maximum security, degraded UX.
> - **B) Fail-open** — the action is allowed by default. The user sees nothing. UX intact, degraded security.
> - **C) Retry with timeout** — try N times before falling back (to fail-closed or fail-open). More complex.
>
> My recommendation: [A/B/C] because [security vs UX context].

These three templates are not exhaustive — see Step 7 "Architectural Dimensions Checklist" for the full list. They are highlighted here because vague wording on these three dimensions is most likely to silently hide an architectural decision.

---

## Step 7: Propose 2-3 approaches (HARD GATE — architectural decisions are LOCKED here)

<HARD-GATE-FORK>
This step is the architectural fork. Decisions taken here CANNOT be deferred to `/ops-plan` or research. The plan and the research phase optimize for "the shortest path given current code", not for "the cleanest design" — if you let architecture be decided downstream, you will end up extending whatever already exists, even when extracting a new abstraction would be cleaner.

You MUST present **at least 2 (ideally 3)** named approaches as a forced choice. The user MUST pick one before you proceed to Step 8. Phrases like "we'll see during the plan", "to be explored during research", "TBD", "we'll figure this out later" are FORBIDDEN for any architectural dimension. If a decision is genuinely uncertain, present the uncertainty as a forced choice itself (e.g., "A: lock decision now to X — B: lock decision now to Y — both are valid, pick one").

If you write "we'll figure this out during the plan" or any equivalent deferral for an architectural question, you have FAILED this skill.
</HARD-GATE-FORK>

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
- **Multi-choice format preferred** — when the design has several independent dimensions (e.g., "where defaults live", "where authority lives", "UI placement"), ask one A/B/C question per dimension. The user picks letters. Each letter eliminates branches in the design space.

**Wait for the user to choose** before proceeding. Do NOT skip this step even if one approach seems obviously better.

### Architectural Dimensions Checklist (MANDATORY)

Before moving to Step 8, you MUST have presented an explicit choice for EACH of these dimensions that applies to the current feature. Skipping a dimension that applies is a FAILURE of this skill.

| Dimension | When it applies | Question to ask |
|---|---|---|
| **Storage location** | Any new persistent state | "Where is this stored: existing field X / new field Y / new model Z?" |
| **Source of truth for permissions** | Any feature touching auth/visibility/policy | "Where does the authority live: server-computed ability exposed via API / client-side reconciliation reading state / hybrid?" (see Step 6 question template) |
| **Instance-wide defaults** | Any feature with a toggle/setting/policy | "How is the default set: hardcoded / per-resource only / instance-wide via env var or setting + per-resource override?" (see Step 6 question template) |
| **Failure mode** | Any feature with async / network / external dependency | "If the dependency fails: fail-closed (deny) / fail-open (allow) / retry with timeout?" (see Step 6 question template) |
| **UI placement** | Any feature adding UI | "Where in the existing UI: section X / new section / standalone view?" — and CONFIRM the literal placement (top/bottom/middle) before validating |
| **Backward compatibility** | Any feature changing existing behavior | "Existing resources: preserved as-is / migrated lazily / migrated eagerly?" |
| **Test boundaries** | Any non-trivial feature | "Tests at: unit / integration / e2e / all three?" |

For each applicable dimension, present a multi-choice question (Step 6 format) BEFORE writing the design sections (Step 8). The user's answers are the architectural decisions you write into the spec.

If the dimension is not applicable, state explicitly in your output: "Dimension X: not applicable because [reason]". This makes the YAGNI filter visible.

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

### Architectural decisions (per dimension)

For each dimension from the Step 7 checklist that applies, list the user's chosen answer (verbatim if a Step 6 template was used). Mark non-applicable dimensions explicitly with N/A and the reason. This is the structured trace the critic's Lens 5 brainstorm trace check consumes downstream.

- **Storage location**: [chosen value, e.g. "existing Room.configuration JSONField — no migration"] OR `N/A — no new persistent state`
- **Source of truth for permissions**: [verbatim Template B answer, e.g. "A — server-driven via abilities.can_X exposed in serializer"] OR `N/A — feature does not touch permissions`
- **Instance-wide defaults**: [verbatim Template A answer, e.g. "C — env var RECORDING_X_BY_DEFAULT with per-room override"] OR `N/A — feature has no toggle/policy`
- **Failure mode**: [verbatim Template C answer, e.g. "A — fail-closed, deny by default"] OR `N/A — no async/external dependency`
- **UI placement**: [exact placement confirmed by user, e.g. "new section at bottom of Admin panel, after Access section"] OR `N/A — no UI change`
- **Backward compatibility**: [chosen value, e.g. "existing rooms preserved as-is, default OFF"] OR `N/A — no behavior change for existing data`
- **Test boundaries**: [chosen value, e.g. "backend pytest unit + integration; no frontend tests (no test runner)"] OR `N/A — trivial change`

### Other key decisions
- [Decisions made during brainstorming that are not architectural-dimension answers — e.g. naming, scope clarifications, deferred follow-ups]

### Design sections validated
- [List each section the user approved]

### Open questions
- [Anything still unresolved — but NOT architectural decisions, which must be locked here]
```

---

## Step 11: Transition

After the summary, offer a direct transition to planning:

> "Ready to plan this? I can launch `/ops-plan` directly — it will skip the brainstorming phase since we just completed it, and start from research + spec writing."

If the user accepts, invoke `/ops-plan` with a note that brainstorming is already done (the plan skill's Step 1 can be shortened to a recap rather than re-doing the full brainstorm). **Ensure the Brainstorm Summary block (Step 10) remains visible in conversation context so `/ops-plan` Step 8 can attach it verbatim to the critic dispatch** — without this, the critic's Lens 5 brainstorm trace check cannot run and architectural decisions invented post-brainstorm will not be flagged.

If the user wants to explore further, continue the conversation.

---

## Constraints

- **Do NOT make changes.** This skill is discussion-only — no edits, no commits.
- **Do NOT write specs or plans.** If the user wants to plan, transition to `/ops-plan`.
- **Do NOT dispatch agents.** This is a direct conversation with the user. If research is needed, suggest `/ops-research`.
- **Every project goes through this.** "Simple" projects are where unexamined assumptions cause the most wasted work.
- **Track progress.** Mark each task as completed as you finish it. The user should be able to see where you are in the process.
