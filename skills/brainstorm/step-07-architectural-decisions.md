# Step 7 — Propose 2-3 approaches (HARD GATE — architectural decisions are LOCKED here)

Mark the task "Brainstorm: propose 2-3 approaches" as `in_progress` now via `TaskUpdate`.

<HARD-GATE-FORK>
This step is the architectural fork. Decisions taken here CANNOT be deferred to `/ops-plan` or research. The plan and the research phase optimize for "the shortest path given current code", not for "the cleanest design" — if you let architecture be decided downstream, you will end up extending whatever already exists, even when extracting a new abstraction would be cleaner.

You MUST present **at least 2 (ideally 3)** named approaches as a forced choice. The user MUST pick one before you proceed to Step 8. Phrases like "we'll see during the plan", "to be explored during research", "TBD", "we'll figure this out later" are FORBIDDEN for any architectural dimension. If a decision is genuinely uncertain, present the uncertainty as a forced choice itself (e.g., "A: lock decision now to X — B: lock decision now to Y — both are valid, pick one").

If you write "we'll figure this out during the plan" or any equivalent deferral for an architectural question, you have FAILED this skill.
</HARD-GATE-FORK>

<HARD-GATE-NEUTRALITY>
This step asks the user to CHOOSE between architectural options. You MUST present options **neutrally** — the user's context drives the decision, not an assumed stack.

FORBIDDEN in this step:
- Framing any option as "almost always cleaner", "the right default", "the canonical choice", or equivalent universal claims.
- Assuming a web/backend-authoritative/CRUD/monolith context. Features in this project may target CLIs, libraries, offline-first apps, local-first apps, edge runtimes, real-time collaborative systems, data pipelines, batch jobs, embedded systems, or anything else.
- Stack-specific wording in the question itself ("Django setting", "env var", "serializer", "React hook", etc.). If you need to illustrate, list at least two alternatives from different stacks.
- Pre-picking an answer under the guise of "my recommendation". A recommendation is allowed ONLY when it is explicitly conditioned on what the user already told you about their context in Steps 1-6 — never as a default.

If the user's context from Steps 1-6 genuinely points to one option, say so explicitly: "Given that you told me [X] in Step 3, option [Y] fits best because [reason]." Otherwise, present the options and let the user decide.
</HARD-GATE-NEUTRALITY>

Once you understand the problem space, propose **2-3 different approaches** with trade-offs.

## For each approach

- **Name**: Short label (e.g., "A: extend existing module" / "B: new standalone component")
- **How it works**: 2-3 sentences
- **Pros**: Why this approach is good
- **Cons**: What are the tradeoffs
- **Context fit**: Which kind of context/constraint makes this approach the right one (so the user can self-identify)

## Presentation rules

- **Context-conditioned recommendation only** — if the user's answers in Steps 1-6 point clearly to one option, say so and cite the specific answer. Otherwise present options neutrally and let the user pick.
- **Be conversational** — a simple choice can be 3 sentences per option. A complex decision needs more depth.
- **Use the visual companion** if active — for choices with visual implications, show side-by-side comparisons.
- **Always present at least one alternative** — the user needs to make an informed decision, not rubber-stamp yours.
- **Multi-choice format preferred** — when the design has several independent dimensions (e.g., "where state lives", "where authority lives", "surface placement"), ask one A/B/C question per dimension. The user picks letters. Each letter eliminates branches in the design space.

**Wait for the user to choose** before proceeding. Do NOT skip this step even if one approach seems obviously better — "obviously better" is usually a stack assumption in disguise.

## Architectural Dimensions Checklist (MANDATORY)

Before moving to Step 8, you MUST have presented an explicit choice for EACH of the seven dimensions below that applies to the current feature. For each applicable dimension, present a multi-choice question (A/B/C format) and wait for the user's answer. Skipping an applicable dimension is a FAILURE of this skill.

If a dimension is not applicable, state it explicitly in your output: "Dimension X: not applicable because [reason]". This makes the YAGNI filter visible.

### Note on scope

These 7 dimensions are a **default checklist** covering the most common architectural fork points. They are NOT exhaustive and NOT universally applicable:

- Some feature types may need additional dimensions not listed here (e.g., concurrency model for distributed systems, cache invalidation strategy for read-heavy APIs, observability boundaries for ops-critical features, wire format for protocol work). If your context requires an architectural decision that does not fit any of the 7 dimensions, present it as an extra A/B/C question with the same forced-choice discipline.
- Some feature types will have several N/A dimensions (e.g., a pure library has no "Configuration & defaults" dimension, a batch job may have no "Interface surface placement" dimension). Mark them explicitly N/A — the checklist is a safety net, not a quota.
- The 7 dimensions are **neutral prompts**, not prescriptions. None of them has a "correct" default answer.

**Overview of the 7 dimensions** (details below):

| # | Dimension | When it applies |
|---|---|---|
| 1 | State / data location | Any new persistent or long-lived state |
| 2 | Source of authority (decision ownership) | Any feature where more than one component could compute the same rule/decision |
| 3 | Configuration & defaults | Any feature with a toggle, setting, policy, or per-resource option |
| 4 | Failure mode | Any feature depending on async work, external systems, or any source of state that can be unavailable |
| 5 | Interface surface placement | Any feature adding or modifying an interface (UI, CLI, API, protocol, library export…) |
| 6 | Backward compatibility | Any feature changing existing behavior or data shape |
| 7 | Test boundaries | Any non-trivial feature |

Three dimensions (2, 3, 4) have **mandatory structural templates** — you MUST preserve their structure (the question + the lettered options + the context-conditioned recommendation rule) when presenting them. The wording can be adapted to the specific feature, but you cannot skip options or drop the context-fit framing. The other four dimensions use the plain A/B/C format with the short question shown in their section.

---

### Dimension 1 — State / data location

**Applies if**: any new persistent or long-lived state (database row, file, in-memory cache, external store, local storage, message queue entry, etc.).

Question: "Where does this state live: reuse existing location X / add a new field on existing structure Y / new dedicated structure Z?" — and name concrete candidates from the current codebase.

---

### Dimension 2 — Source of authority (decision ownership)

**Applies if**: more than one component could in principle compute the same rule or decision (permission check, validation, routing, policy evaluation, feature flag resolution, derived value, etc.).

> **Question — where the decision lives (single owner vs. distributed)**
>
> The system needs to decide "[specific rule, e.g. 'can this actor do X?', 'is this input valid?', 'which variant is active?']". Which component owns that decision?
>
> - **A) Centralized owner** — one component (the one that holds the ground truth) computes the decision and exposes the result (boolean, enum, object) to every other component. No other component re-computes the rule. Advantage: single source of truth, no drift. Cost: the consumer depends on the owner being reachable/up-to-date.
> - **B) Local / decentralized owner** — each component that needs the decision computes it itself from the state it already has. Advantage: no dependency on a remote owner, works offline, lowest latency. Cost: the rule is duplicated and can drift between implementations.
> - **C) Hybrid / reconciling** — multiple components contribute inputs, one of them reconciles them to produce the decision. Advantage: can combine sources that naturally live in different places. Cost: failure modes are complex (partial data, out-of-order updates, stale reconciliation).
>
> **Context fit** (the user chooses, not you):
> - A fits well when: there is a clear ground-truth component, latency is not critical, and the consumer is online/connected to the owner.
> - B fits well when: the feature must work offline/disconnected, latency matters, or the "owner" would be an artificial remote indirection.
> - C fits well when: the decision inherently depends on inputs from multiple independent sources that cannot be consolidated into one.
>
> My recommendation: state "no default — depends on your context" UNLESS the user has already told you in Steps 1-6 something that makes one option clearly unsuitable (e.g., "must work offline" → A is unsuitable; "strict audit requirement" → B is unsuitable). In that case, cite the specific prior answer and explain the fit.

Skipping this dimension tends to push the design toward "extend whatever channel is already there" (often C) instead of picking a clean owner. Asking the question explicitly forces the choice.

---

### Dimension 3 — Configuration & defaults

**Applies if**: the feature introduces any toggle, flag, setting, policy, or per-resource configuration.

> **Question — default value, override mechanism, and scope**
>
> For this new [toggle / setting / policy], how is the default value handled?
>
> - **A)** Disabled by default, explicit per-resource opt-in. No global/instance-wide configuration.
> - **B)** Enabled by default, explicit per-resource opt-out. No global/instance-wide configuration.
> - **C)** Disabled by default, **but** a global/instance-wide configuration mechanism (environment variable / config file / CLI flag / build-time constant / runtime setting / whatever the project's conventional configuration surface is) lets the operator change the default at global scope, with per-resource override still possible.
> - **D)** Always forced to a fixed value, no configuration possible (hardcoded constant).
>
> **Context fit** (the user chooses, not you):
> - A is natural when: conservative rollout is the priority, or operators should not be able to enable the feature wholesale.
> - B is natural when: the feature is considered safe/beneficial by default and opt-out is expected to be rare.
> - C is natural when: operators of the project (self-hosted, multi-tenant, per-deployment) need to set a different default than what ships in the code.
> - D is natural when: the value is an invariant, not a policy — there is no legitimate reason to vary it.
>
> My recommendation: state "no default — depends on your deployment model" UNLESS the user has already told you in Steps 1-6 something relevant (e.g., "this is a library, no deployment" → D or A; "self-hosted with ops who need per-instance control" → C). Cite the prior answer.

When asking this question, **do NOT name a specific configuration mechanism** (no "env var", no "Django setting", no "Rails config", no "React prop") unless the user has already told you which conventional configuration surface this project uses. If they haven't, say "the project's conventional configuration mechanism" and let them clarify.

Skipping this dimension leads to features that work for the dev environment but cannot be configured for other deployment contexts.

---

### Dimension 4 — Failure mode

**Applies if**: the feature depends on async work, external services, fire-and-forget propagation, or any source of state that can be unavailable.

> **Question — behavior when the dependency is unavailable or fails**
>
> If [the specific dependency — remote service, worker, shared store, external API, etc.] fails, times out, or is unavailable:
>
> - **A) Fail-closed** — the action is denied by default. The caller sees an error. Maximum safety/correctness, degraded availability.
> - **B) Fail-open** — the action is allowed by default. The caller sees nothing. Maximum availability, degraded safety/correctness.
> - **C) Retry / degrade with timeout** — try N times, then fall back (to A or B, or to a cached/stale value). Better UX than pure A, more complex to implement and reason about.
>
> **Context fit** (the user chooses, not you):
> - A fits when: correctness or safety is non-negotiable (auth, payments, medical, anything where a wrong "allow" is worse than an unavailability error).
> - B fits when: availability is non-negotiable and the decision is reversible/monitored (analytics, telemetry, feature hints, non-critical UX polish).
> - C fits when: the dependency is usually reliable but transient failures are expected, AND the caller can tolerate bounded latency for retries.
>
> My recommendation: state "no default — depends on whether a wrong 'allow' or a wrong 'deny' is the worse outcome in your specific context". If the user already told you which matters more in Steps 1-6, cite it.

---

### Dimension 5 — Interface surface placement

**Applies if**: any feature adding or modifying a user-facing or consumer-facing surface — UI element, CLI command/flag, API endpoint, library export, wire protocol message, log format, metric name, event schema, etc.

Question: "Where in the existing surface does this live: extend existing element X / new element in the same surface / new surface entirely?" — and CONFIRM the literal placement (position, naming, grouping) before validating. Adapt "surface" to the feature type (UI section, CLI subcommand, API route, library module, etc.).

---

### Dimension 6 — Backward compatibility

**Applies if**: any feature changing existing behavior, data shape, interface contract, or default value that existing consumers/data may depend on.

Question: "Existing [resources / callers / data / consumers]: preserved as-is / migrated lazily on access / migrated eagerly in one pass / explicitly broken with a version bump?"

---

### Dimension 7 — Test boundaries

**Applies if**: any non-trivial feature.

Question: "Tests at which layer: unit / integration / end-to-end / all three / none (with explicit justification)?" — and name the layers that actually exist in this project.

---

## ✅ End of Step 7

Before proceeding, verify:
- [ ] You presented at least 2 (ideally 3) named macro-approaches with name / how it works / pros / cons / context-fit.
- [ ] You did NOT frame any option as a universal default. Any recommendation you made was explicitly conditioned on something the user told you in Steps 1-6.
- [ ] The user explicitly picked one macro-approach.
- [ ] For EACH of the 7 architectural dimensions, you either (a) asked a multi-choice question and got the user's answer, or (b) marked it explicitly `N/A — [reason]`.
- [ ] Dimensions 2, 3, and 4 — if applicable — were asked using their structural templates: question + lettered options + context-fit framing + context-conditioned recommendation rule. Wording adapted to the feature, structure preserved.
- [ ] No dimension was deferred with phrases like "TBD", "we'll figure this out later", "during the plan", "during research". If you wrote any such phrase, this step has FAILED and you must restart Step 7.
- [ ] No stack-specific wording leaked into the questions (no "Django setting", "env var" as the only mechanism named, "server-driven", "the backend should…", etc.) unless the user already told you the project's stack.
- [ ] If the feature genuinely needs an architectural decision that does not fit any of the 7 dimensions, you asked it as an extra A/B/C question.
- [ ] The user's answers are stored in your working memory so you can transcribe them into the Step 10 Brainstorm Summary.

Mark the task "Brainstorm: propose 2-3 approaches" as `completed` via `TaskUpdate`.

**→ Next: read `skills/brainstorm/step-08-design-sections.md` now and execute Step 8.**

Do NOT continue without reading that file first.
