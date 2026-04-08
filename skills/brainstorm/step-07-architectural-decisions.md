# Step 7 — Propose 2-3 approaches (HARD GATE — architectural decisions are LOCKED here)

Mark the task "Brainstorm: propose 2-3 approaches" as `in_progress` now via `TaskUpdate`.

<HARD-GATE-FORK>
This step is the architectural fork. Decisions taken here CANNOT be deferred to `/ops-plan` or research. The plan and the research phase optimize for "the shortest path given current code", not for "the cleanest design" — if you let architecture be decided downstream, you will end up extending whatever already exists, even when extracting a new abstraction would be cleaner.

You MUST present **at least 2 (ideally 3)** named approaches as a forced choice. The user MUST pick one before you proceed to Step 8. Phrases like "we'll see during the plan", "to be explored during research", "TBD", "we'll figure this out later" are FORBIDDEN for any architectural dimension. If a decision is genuinely uncertain, present the uncertainty as a forced choice itself (e.g., "A: lock decision now to X — B: lock decision now to Y — both are valid, pick one").

If you write "we'll figure this out during the plan" or any equivalent deferral for an architectural question, you have FAILED this skill.
</HARD-GATE-FORK>

Once you understand the problem space, propose **2-3 different approaches** with trade-offs.

## For each approach

- **Name**: Short label (e.g., "A: extend existing module" / "B: new standalone component")
- **How it works**: 2-3 sentences
- **Pros**: Why this approach is good
- **Cons**: What are the tradeoffs
- **Recommendation**: Lead with the recommended option and explain why

## Presentation rules

- **Lead with your recommendation** — present the best option first, then alternatives
- **Be conversational** — a simple choice can be 3 sentences per option. A complex decision needs more depth.
- **Use the visual companion** if active — for choices with visual implications, show side-by-side comparisons
- **Always present at least one alternative** — the user needs to make an informed decision, not rubber-stamp yours
- **Multi-choice format preferred** — when the design has several independent dimensions (e.g., "where defaults live", "where authority lives", "UI placement"), ask one A/B/C question per dimension. The user picks letters. Each letter eliminates branches in the design space.

**Wait for the user to choose** before proceeding. Do NOT skip this step even if one approach seems obviously better.

## Architectural Dimensions Checklist (MANDATORY)

Before moving to Step 8, you MUST have presented an explicit choice for EACH of the seven dimensions below that applies to the current feature. For each applicable dimension, present a multi-choice question (A/B/C format) and wait for the user's answer. Skipping an applicable dimension is a FAILURE of this skill.

If a dimension is not applicable, state it explicitly in your output: "Dimension X: not applicable because [reason]". This makes the YAGNI filter visible.

**Overview of the 7 dimensions** (details below):

| # | Dimension | When it applies |
|---|---|---|
| 1 | Storage location | Any new persistent state |
| 2 | Source of truth for permissions | Any feature touching auth/visibility/policy |
| 3 | Instance-wide defaults | Any feature with a toggle/setting/policy |
| 4 | Failure mode | Any feature with async / network / external dependency |
| 5 | UI placement | Any feature adding UI |
| 6 | Backward compatibility | Any feature changing existing behavior |
| 7 | Test boundaries | Any non-trivial feature |

Three dimensions (2, 3, 4) have **mandatory inline templates** — you MUST use them verbatim when applicable. The structure is what protects against vague wording that silently hides an architectural decision. The other four dimensions use the plain A/B/C format with the short question shown in their section.

---

### Dimension 1 — Storage location

**Applies if**: any new persistent state.

Question: "Where is this stored: existing field X / new field Y / new model Z?"

---

### Dimension 2 — Source of truth for permissions

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

Skipping this dimension tends to push the design toward "extend whatever channel is already there" (option C) instead of "define a clean ability" (option A).

---

### Dimension 3 — Instance-wide defaults

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

Skipping this dimension leads to features that work for the dev environment but cannot be configured per-instance.

---

### Dimension 4 — Failure mode

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

---

### Dimension 5 — UI placement

**Applies if**: any feature adding UI.

Question: "Where in the existing UI: section X / new section / standalone view?" — and CONFIRM the literal placement (top/bottom/middle) before validating.

---

### Dimension 6 — Backward compatibility

**Applies if**: any feature changing existing behavior.

Question: "Existing resources: preserved as-is / migrated lazily / migrated eagerly?"

---

### Dimension 7 — Test boundaries

**Applies if**: any non-trivial feature.

Question: "Tests at: unit / integration / e2e / all three?"

---

## ✅ End of Step 7

Before proceeding, verify:
- [ ] You presented at least 2 (ideally 3) named macro-approaches with name / how it works / pros / cons / recommendation.
- [ ] The user explicitly picked one macro-approach.
- [ ] For EACH of the 7 architectural dimensions, you either (a) asked a multi-choice question and got the user's answer, or (b) marked it explicitly `N/A — [reason]`.
- [ ] Dimensions 2, 3, and 4 — if applicable — were asked using their inline templates verbatim (not summarized or reworded).
- [ ] No dimension was deferred with phrases like "TBD", "we'll figure this out later", "during the plan", "during research". If you wrote any such phrase, this step has FAILED and you must restart Step 7.
- [ ] The user's answers are stored in your working memory so you can transcribe them into the Step 10 Brainstorm Summary.

Mark the task "Brainstorm: propose 2-3 approaches" as `completed` via `TaskUpdate`.

**→ Next: read `skills/brainstorm/step-08-design-sections.md` now and execute Step 8.**

Do NOT continue without reading that file first.
