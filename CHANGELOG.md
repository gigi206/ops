# Changelog

## 3.10.0 (2026-04-11)

### Brainstorm safety pipeline — invariant-class exception, brainstorm critic, and plan Duplication Scan

Three coordinated changes that close a structural gap observed on a real authz feature (multi-actor recording delegation): the brainstorm presented Dimension 2 (Source of authority) neutrally, the user picked a hybrid model where the frontend recomposed the authz rule, and the produced code shipped a frontend bug where the membership check was silently dropped. The bug survived all existing review gates because each gate was internally consistent — the brainstorm refused to recommend, the plan critic only checked plan-vs-brainstorm trace (not the brainstorm decisions themselves), and the planner had no inter-task duplication scan. Comparable runs on older brainstorm versions (without forced neutrality) and on a competing brainstorm plugin both converged naturally on the centralized-owner pattern and produced safer code, confirming the gap was a regression introduced by over-correction for stack-agnosticism.

This release adds three layered defenses, each independently effective: a soft gate (invariant-class recommendation), a hard gate (brainstorm critic), and a planner self-check (Duplication Scan).

#### Layer 1 — HARD-GATE-NEUTRALITY invariant-class exception (soft gate)

- refactor(brainstorm): Step 7 HARD-GATE-NEUTRALITY — add explicit "invariant-class" exception. Centralized-owner (Dimension 2 A) and fail-closed (Dimension 4 A) MAY be recommended as defaults when the decision class is authorization, trust, validation, access control, or safety in a multi-actor system with a shared resource. Exception is scoped: does NOT apply to single-actor, peer-to-peer, offline-first / local-first, or intentionally advisory contexts.
- refactor(brainstorm): Step 7 Dimension 2 "My recommendation" — add positive trigger for centralized-owner when the rule is authz/trust/validation/access-control/ownership governing a shared resource. The agent now cites the invariant explicitly: "Authz decisions require a single owner — drift between actors recomputing the same rule is a recurring bug class, not a tradeoff."
- refactor(brainstorm): Step 7 Dimension 4 "My recommendation" — add positive trigger for fail-closed when the decision is authz/trust/validation/payment/safety. A wrong "allow" is worse than a wrong "deny" by definition for these classes.

#### Layer 2 — Brainstorm critic Step 11 (hard gate, signal-gated)

The Layer 1 exception is a soft gate: it relies on the agent applying it correctly. Layer 2 adds a hard gate. The plan-stage critic (`/ops-plan` Step 8) runs after the plan is written and only catches decisions invented post-brainstorm — it does NOT challenge decisions locked during brainstorm. The brainstorm critic closes that gap by reviewing the locked decisions themselves before transition.

- feat(brainstorm): new step `step-11-critic-review.md` between summary (Step 10) and transition (Step 12). Dispatches `ops:critic` in the new BRAINSTORM review mode to verify locked architectural decisions against the invariant-class exception. Mode-aware with deterministic signal-gating based on the Step 10 summary format (Dimensions 2/3/4 are guaranteed to start with an A/B/C prefix, so detection is a plain text match — no LLM judgement needed). **Simple mode**: skipped unless an invariant-class signal escalates (D1 = fragile channel + auth context, D2 = B/C, D4 = B/C, or authz/safety keyword in Objective). **Normal mode**: skipped unless an invariant-class signal (D1/D2/D4) escalates — on a brainstorm where all invariant-class dimensions are at the safe default (A) or N/A, the critic verdict is a guaranteed APPROVE, so paying one dispatch for a no-op is avoided. **Complex mode**: runs unconditionally.
- refactor(brainstorm): `step-11-transition.md` renamed to `step-12-transition.md`. Skill is now 12 sequential step files instead of 11. Hand-offs and "next file" pointers updated in Steps 9, 10, and 12. Step counts in `SKILL.md` workflow table updated.
- refactor(brainstorm): `SKILL.md` global constraints — softened "Do NOT dispatch agents" to "Do NOT dispatch research or implementation agents" with an explicit single carved-out exception for the Step 11 critic dispatch. The brainstorm critic is the ONLY allowed agent dispatch in `/ops-brainstorm`.
- feat(critic): new "Brainstorm review mode" in `agents/critic.md`, triggered by the literal first-line marker `REVIEW MODE: BRAINSTORM`. Reduced protocol — Phase 0 (project rules + read step-07 exception) → Phase 1 (always run, predict 3 invariant-class antipatterns) → Phase 2 (Lens 5-B only: invariant-class check across **Dimensions 1, 2, and 4 — D3/D5/D6/D7 are explicitly out of scope as they are deployment/UX/process concerns belonging to plan-stage Lens 2, not invariant-class**, single-source-of-truth check, authority placement check) → Phase 3 (Architect + Skeptic perspectives only) → Phases 4/4.5/4.75 (gap analysis, self-audit, realist check) → Phase 6 (verdict APPROVE / SUGGESTIONS / REJECT). Adversarial mode (Phase 5) disabled. Dimension 1 trigger requires strict co-occurrence of fragile-channel keyword AND correctness-critical keyword within the Dimension 1 answer itself (not inferred from loose phrases scattered elsewhere in the summary) — intentionally tight to keep the false-positive rate low.
- feat(critic): top-level "Review modes" section documents the two distinct dispatch modes (PLAN, BRAINSTORM), default-to-PLAN behavior when no marker is present, and the input/mode mismatch error path. Dispatchers must include the literal mode marker as the first line of the prompt body.
- feat(brainstorm): Step 11 verdict handling — APPROVE appends a `Brainstorm critic verdict: APPROVE` line to the Brainstorm Summary "Other key decisions" block; SUGGESTIONS resolves each suggestion one at a time (no batching) with revise-or-decline-with-reason flow; REJECT presents an A/B/C forced choice (revise specific dimension and re-critic with 3-iteration cap, override with documented reason, or abort brainstorm). The verdict line is consumed by `/ops-plan` Step 8 critic as evidence the locked decisions were already reviewed (does NOT cause the plan critic to skip — it complements, not replaces).
- refactor(brainstorm): `step-12-transition.md` end-of-step checklist — add two load-bearing verifications to protect the handoff to `/ops-plan`. (1) If Step 11 produced a critic verdict, the `**Brainstorm critic verdict**: …` line MUST be present inside the `## Brainstorm Summary` block before transitioning; if missing (summary edited/paraphrased/regenerated after Step 11), re-append it. (2) If Step 11 was skipped by signal-gating, the Summary must be intact and unmodified since Step 10. Protects the critic→plan critic coupling against silent drift during transition.
- docs(brainstorm): the new step explicitly states that brainstorm critic and plan critic are complementary, not duplicate. They run on different inputs (summary vs. plan) and check different things (locked-decision sanity vs. plan-vs-summary trace). Both must run for full coverage.
- feat(plan): Step 7 — implement the consumer side of the verdict chain. When writing the plan header, read the `**Brainstorm critic verdict**: …` line from the handed-off Brainstorm Summary and copy it verbatim below the `**Mode**: …` header. Handles all four verdict forms (APPROVE, SUGGESTIONS resolved, REJECT — OVERRIDDEN + reason line, skipped — no invariant-class signal) and the "no brainstorm at all" case (omit the line). Includes a safety recovery clause: if Step 11 ran but the line is missing from the Summary, STOP and re-append from conversation history before writing the plan.
- feat(plan): Step 8 — the critic dispatch "Required dispatch context" list adds a 4th item. If the plan header contains the verdict line, forward it verbatim to the plan-stage critic with the framing *"The brainstorm stage already ran its own critic on the locked architectural decisions. This does NOT cause you to skip Lens 5 — the plan-stage Lens 5 still runs the brainstorm trace check (plan-vs-summary). Use the verdict as evidence that the dimensions themselves were reviewed: focus your Lens 5 on plan-vs-summary trace rather than re-litigating the dimensions."* Override case (`REJECT — OVERRIDDEN by user`) triggers extra scrutiny on any plan task derived from the overridden dimension. End-of-Step checklist updated to verify the forwarding. The verdict chain is now implemented end-to-end: brainstorm Step 11 (append) → Step 12 (verify) → plan Step 7 (propagate to plan header) → plan Step 8 (forward to critic dispatch).

#### Layer 3 — Plan Duplication Scan (planner self-check)

The Layer 1+2 gates protect the architectural decisions, but they do not protect against duplicated *implementation* logic that emerges only when comparing two tasks side by side. Observed effect on the same feature: a plan with two interface-surface toggles produced two tasks that each inlined ~30 lines of structurally identical handler code in the same UI component, totaling ~60 lines of duplication. Neither task was a duplication on its own — the duplication only emerged when comparing the two tasks side by side. The plan-stage critic's Lens 5 "Why not extract" check operates **per-task** and was structurally unable to flag it because it never performed the inter-task comparison. The Duplication Scan adds that comparison as a forcing function inside the planner itself, before critic review runs.

- feat(plan): Step 7 — new MANDATORY section "Duplication Scan" inserted between "Task Decomposition" and "No Placeholders". Pairwise compares the new logic across all tasks and flags duplications matching one of five criteria: same input/output AND same domain concept; same decision rule applied at two boundaries; same reaction to the same event with the same payload shape; same external call with the same serialization; same boilerplate across 3+ tasks. Each detected duplication produces a new `[high-risk]` extraction task ordered before its consumers, plus updated Files/Change/Validation in the consuming tasks, plus a one-line rationale in the plan's Design/Approach section.
- feat(plan): Duplication Scan anti-anti-pattern guards explicitly forbid over-extraction. Single call sites stay inline. Coincidental shape similarity (same types, unrelated domains) is NOT extracted. Framework-mandated boilerplate (route registration, model declaration, DI wiring) is NOT extracted. Cross-domain similarity is NOT extracted. The sanity check: if the extracted helper has zero domain meaning (no name describing what it represents in the problem domain), revert the extraction.
- feat(plan): Duplication Scan is mode-aware. Simple mode SKIPS the scan entirely (express path, low duplication risk on 1-3 tasks) — the plan-stage critic's Lens 5 remains the safety net. Normal mode runs a LIGHT pass (exact-shape duplication only). Complex mode runs the FULL pass (all five criteria including same-rule-at-two-boundaries detection). Mode is read from the `**Mode**: …` line in the plan header.
- feat(plan): Step 7 — new end-of-step checklist item verifies the scan was actually run. Either the plan's Risks section contains the literal note `"Duplication scan: clean (N tasks compared)"` (auditable evidence) OR an extraction task is present in the task list. Plans without this evidence are not allowed to proceed to critic review.
- docs(plan): Duplication Scan documents itself as **complementary**, not duplicate, to the plan-stage critic's Lens 5 "Why not extract" check. The Lens 5 check operates per-task and stays as a safety net for cases where the planner missed the inter-task comparison. Both run for full coverage.
- docs(plan): Examples table in the new section is presented as illustrative and stack-agnostic — adapts to any tech stack ("two interface-surface handlers", "one authorization rule applied at two boundaries", "two services calling the same external API"), not coupled to any specific framework or language.

#### Drift fixes and process

- fix(implement): Step 2d per-task review — `step-02-execute-tasks.md` no longer treats "no mode header present" as equivalent to `Mode: Normal`. A plan written by hand or by an unknown source now defaults to **Complex** ceremony (full per-task review), matching `skills/implement/SKILL.md:25` and `skills/plan/step-07-write-plan.md:20`. Previously the three files were in silent contradiction: SKILL.md said "default Complex" while step-02 skipped per-task review on "no mode". Observable behavior change: handcrafted plans now run per-task review by default — explicit `**Mode**: Normal` is required to opt into the lighter ceremony. Cross-references to both canonical sources added inline so future edits to any of the three are grep-discoverable.
- fix(plan): Step 7 — Simple-mode edge case handler. Simple-mode brainstorms normally transition to `/ops-do`, not `/ops-plan`, so step-07 should never see a Simple context. If it does (user manually invokes `/ops-plan` from a Simple-mode brainstorm, or escalates mid-conversation), the rule is: upgrade to `**Mode**: Normal` when writing the plan header and document the upgrade in the plan's Approach section with a one-line rationale. Explicitly forbid writing `**Mode**: Simple` in a plan header — `/ops-implement` only recognizes Normal and Complex, so a Simple header would fall through to the Complex default (wrong ceremony for what was originally a Simple feature).
- fix(plan): Step 7 — Duplication Scan now opens with an explicit "When to run" paragraph: after Task Decomposition is complete (every task has Description + Files + Change + Validation + risk tag), before the End-of-Step checklist. Running earlier is pointless (no tasks to compare), running later is too late (checklist gate and critic dispatch already shipped).
- feat(project): `AGENTS.md` — new "README synchronization" section added after "Versioning". States that any change affecting skills, agents, pipeline flow, hard gates, mode-aware ceremony, requirements, or structure tree MUST update `README.md` in the same change, not in a follow-up commit. Heuristic: *"if a user reading only the README would get a misleading picture of what the skill now does, the README update is mandatory."* Introduced after observing that the brainstorm critic, invariant-class exception, and HARD-GATE-SEMGREP all shipped with stale README content in earlier iterations of this release bundle.

## 3.9.1 (2026-04-11)

### HARD-GATE-SEMGREP — enforce `ops-semgrep-scan.sh` over raw `semgrep`

Observed drift where the security gate bypassed `ops-semgrep-scan.sh` and either asserted "semgrep not installed" without checking, or called raw `semgrep` directly. Both behaviors break the diff-aware baseline selection and the structured key=value output contract.

- refactor(security-gate): Step 1b — wrap SAST instructions in `<HARD-GATE-SEMGREP>`. Mandates `command -v ops-semgrep-scan.sh` as the first (and only) probe. Fallback to raw `semgrep` is allowed only when that check fails. Writing "semgrep not installed" without running the script is explicitly called out as a violation.
- refactor(review-pipeline): Step 3 Security Gate — same HARD-GATE-SEMGREP block added inline, replacing the softer "NOT raw semgrep" sentence. Clarifies that the script already handles the not-installed, no-files, error, and no-findings cases — do not re-implement any of them.

## 3.9.0 (2026-04-11)

### Brainstorm adaptive ceremony — Simple / Normal / Complex modes

Complexity gate rewritten from 3 labels with no real flow differences to 3 modes with genuinely different pipelines. The mode propagates from brainstorm through plan into implement.

- refactor(brainstorm): Step 3 — **Simple** mode (~10 min): skips steps 4-5, 1-2 clarifying questions max, all architectural dimensions batched (no A/B/C), design as single block, YAGNI merged into summary, transitions to `/ops-do`.
- refactor(brainstorm): Step 3 — **Normal** mode (~20-25 min): skips steps 4-5, full clarifying questions, dimensions opt-in one by one, design section by section, transitions to `/ops-plan`. Per-task review skipped during implementation — final review only.
- refactor(brainstorm): Step 3 — **Complex** mode (1h+): full flow (steps 4-5 included: scope decomposition + visual companion), extra dimensions beyond the 7 defaults, design section by section with documented alternatives, transitions to `/ops-plan`. Full per-task review during implementation.
- refactor(brainstorm): SKILL.md — global constraints updated to document the three modes.
- feat(plan): Step 7 — plan header includes `**Mode**: Normal` or `**Mode**: Complex` to propagate ceremony level to `/ops-implement`.
- refactor(implement): Step 2d per-task review — now conditional on Complex mode (was conditional on `[high-risk]` only). Normal mode skips per-task review entirely.
- refactor(implement): SKILL.md — review layers documentation and red flags table updated for mode-based ceremony.

## 3.8.0 (2026-04-10)

### Stack-agnostic rewrite + adaptive ceremony + spec/plan merger

Stack-agnostic rewrite of brainstorm dimensions and critic Lens 5. Adaptive ceremony to reduce overhead for simple features across the full pipeline. Spec and plan merged into a single document. Brainstorm→plan fast-path to eliminate redundant work.

**Brainstorm skill (14 files):**
- refactor(brainstorm): Step 1 — reduce 10 per-step tasks to 3 milestone tasks ("clarify & explore", "architectural decisions", "finalize"). Individual steps no longer create/complete their own tasks.
- refactor(brainstorm): Steps 4/5 swapped — assess scope now runs before visual companion offer (scope may change what visuals are relevant). Files renamed: `step-04-assess-scope.md`, `step-05-visual-companion.md`. All hand-offs and SKILL.md step list updated.
- refactor(brainstorm): Step 7 — architectural dimensions changed from opt-out to opt-in. Dimensions with no real choice (obvious answer or N/A) are listed in a batch block — no individual A/B/C question needed. Dimensions with genuine choices still require forced A/B/C. End-of-step checklist updated.

**Plan skill — spec/plan merger:**
- refactor(plan): Merge spec and plan into a single document. Step 6 becomes "Validate Design" (keeps section-by-section user validation, drops spec file writing, spec-reviewer dispatch, and separate user presentation). Step 7 writes a unified plan to `docs/plans/YYYY-MM-DD-<topic>.md` containing both design and task breakdown. Step 8 critic dispatch simplified (one file path instead of two). Spec-reviewer agent no longer dispatched in the plan flow.

**Plan skill — brainstorm→plan fast-path:**
- fix(plan): Step 1 — preserve full brainstorm summary verbatim (including per-dimension architectural decisions) for critic Lens 5. Explicit fallback for partial/incomplete brainstorm: if no `## Brainstorm Summary` block found in context, treat as fresh plan.
- fix(plan): Step 2 — skip full project structure exploration post-brainstorm. Only read project instruction file (CLAUDE.md etc.) if brainstorm did not reference it.
- fix(plan): Step 3 — new "Delta Research Mode" post-brainstorm. HARD-GATE-RESEARCH (mandatory 3 agents) does not apply when brainstorm already explored context. Dispatches only needed agents: researcher-code always (delta prompt), researcher-doc only if unvalidated external dependencies, git-historian only if brainstorm was in a previous session.
- fix(plan): Step 4 — brainstorm findings accepted as evidence source alongside delta research in the adequacy table.
- fix(plan): Step 5 — skip approach proposal when brainstorm already locked an approach. State locked decisions, check delta research for invalidations, flag conflicts to user.
- No changes to the solo plan path — all existing behavior when `/ops-plan` runs without prior brainstorm is preserved.

**Plan skill — risk tags and conflict handling:**
- feat(plan): Step 7 — mandatory `[low-risk]` / `[high-risk]` task risk tags with always-high-risk list (auth, permissions, schema, encryption, CI/CD, secrets). Tags determine per-task ceremony during implementation.
- fix(plan): Step 7 — new "Conflict with brainstorm decisions" rule: flag conflicts between brainstorm decisions and project instruction rules to the user instead of silently overriding.

**Implement skill (2 files):**
- refactor(implement): Step 2 HARD-GATE-NO-BUNDLING — reduced from 17-line duplicate to 2-line reference to SKILL.md source gate.
- refactor(implement): Step 2 model selection — simplified from 3-tier complexity table to risk-tag-based rule (`[low-risk]` → sonnet, `[high-risk]` → default model, retry on failure).
- feat(implement): Step 2d per-task review — now conditional on `[high-risk]` tag. `[low-risk]` tasks skip per-task review entirely (caught by final review).
- refactor(implement): Step 2d reviewer scope — removed Lens 5 architectural drift from per-task review (delegated to final review at full-diff scale where it has cross-task visibility). Tradeoff note added for future re-evaluation.

**Agent changes (3 files):**
- refactor(critic): Phase 1 pre-engagement predictions — now conditional: skip for plans with ≤5 tasks and no cross-cutting concerns. Always-run triggers for auth, permissions, schema, public API, cross-module deps.
- refactor(implementer): Step 4 — `[low-risk]` tasks route to direct implement (skip TDD). Anti-rationalization table updated for risk-tag awareness.
- refactor(code-reviewer): Removed Step 5 (Security Scan) — security analysis is handled by security-gate + security-reviewer. Basic security hygiene (hardcoded secrets, disabled TLS) remains in Step 4 Code Quality table. Steps renumbered. YAML description updated for Lens 5 scope clarification.

**Security gate (1 file):**
- feat(security-gate): New complexity filter — trigger matches on small diffs (<50 LOC, boolean flags only, no new interfaces) are LOW-SENSITIVITY and don't force dispatch alone. Four triggers always force dispatch regardless: auth, secrets, encryption, CI/CD.

**Shared infrastructure:**
- feat: new `data/common_instructions.md` — cross-cutting rules (user language, one question at a time, stop-and-propose, no unsolicited changes) factored out of individual skills. All 18 user-invocable SKILL.md files now reference it.
- fix: `data/bootstrap-context.md` — added common_instructions reference at the top of the skill routing table.
- fix: `bin/ops-semgrep-scan.sh` — filter non-scannable file extensions (.md, .txt, .rst, .adoc, .pdf, images, fonts, media, archives) before passing to semgrep. Fixes "Invalid scanning root" errors.
- refactor: `scripts/` directory renamed to `bin/` — aligns with Claude Code plugin convention (auto-adds `bin/` to PATH). OpenCode plugin creates a symlink to work around `:` in package cache paths.
- refactor: `agents/spec-reviewer.md` deleted — no longer dispatched after spec/plan merger. References cleaned from redispatch-optimization.
- refactor: `scripts/ops-capture-task-state.sh` deleted — replaced by inline `git diff HEAD` + `git ls-files` instructions in implement step-02.
- refactor: `step-06-write-review-spec.md` renamed to `step-06-validate-design.md` — reflects the new role (design validation, no spec writing).
- refactor(review-pipeline): security gate promoted to HARD-GATE — mandatory triage block, impossible to skip. Protects ops-do, ops-refactor, ops-test, ops-perf.

**Stack-agnostic rewrite (brainstorm + critic):**

All brainstorm architectural dimensions, examples, and recommendations rewritten to be stack-agnostic. The previous version assumed a web/backend-authoritative/Django-like context: "server-driven is almost always cleaner", "env var / Django setting", "Room.configuration JSONField", "abilities.can_X exposed in serializer". These assumptions break for offline-first apps, local-first systems, CLIs, pure libraries, edge runtimes, data pipelines, and many other architectures.

This version presents architectural options neutrally and lets the user's context (gathered in Steps 1-6) drive the recommendation. The hard-gate mechanism (decisions MUST be locked here, not deferred to plan/research) is preserved — only the bias in the options themselves is removed.

**AGENTS.md — new stack-agnostic principle:**
- feat(project): new "Stack-agnostic by default" section in AGENTS.md. All ops content (skills, agents, examples, templates, checklists) must remain stack-agnostic. Hardcoded stack references, architectural recommendations framed as universal truths, and feature-type assumptions are forbidden without explicit contextual justification.

**Brainstorm skill changes (4 files):**
- refactor(brainstorm): Step 7 dimensions renamed for neutrality:
  - Dimension 1: "Storage location" → "State / data location"
  - Dimension 2: "Source of truth for permissions" → "Source of authority (decision ownership)" — generalized beyond permissions to cover validation, routing, policy, feature flags, derived values
  - Dimension 3: "Instance-wide defaults" → "Configuration & defaults" — removed Django/env-var-specific wording, replaced with "the project's conventional configuration surface"
  - Dimension 5: "UI placement" → "Interface surface placement" — now covers CLI, API, protocol, library exports, not just web UI
- refactor(brainstorm): Step 7 Dimension 2 template rewritten — 3 options renamed: "Server-driven" → "Centralized owner", "Client-driven" → "Local / decentralized owner", "Hybrid" → "Hybrid / reconciling". Recommendation replaced with "no default — depends on your context" + explicit context-fit guide per option. The template no longer assumes backend/frontend split.
- refactor(brainstorm): Step 7 Dimension 3 template rewritten — stack-specific mechanism names removed. New rule: "do NOT name a specific configuration mechanism unless the user has already told you which conventional configuration surface this project uses."
- refactor(brainstorm): Step 7 adds `<HARD-GATE-NEUTRALITY>` block — enforces neutral presentation of options, forbids universal claims ("almost always cleaner", "the right default"), forbids stack assumptions, and requires context-conditioned recommendations (cite user's prior answer or present neutrally).
- refactor(brainstorm): Step 7 "Note on scope" added — 7 dimensions are a default checklist, not exhaustive or universally applicable. Features may need extra dimensions not listed; some features will have many N/A dimensions. The checklist is a safety net, not a quota.
- refactor(brainstorm): Step 7 end-of-step checklist updated — new verification items for neutrality and stack-agnostic wording.
- refactor(brainstorm): Step 7 "verbatim templates" → "structural templates" — the structure (question + lettered options + context-fit framing) must be preserved, but wording can be adapted to the feature. Removes rigidity while keeping the anti-ambiguity protection.
- refactor(brainstorm): Step 10 summary template aligned — dimension names updated to match Step 7 renames. Example values replaced with stack-neutral alternatives. "verbatim answer" → "user's exact wording".
- refactor(brainstorm): Step 6 enumeration updated — architectural subjects list aligned with new dimension names.

**Critic agent changes (1 file):**
- refactor(critic): Lens 5 "Authority placement check" neutralized — removed "Server-computed is almost always cleaner". New framing: flag when the plan does not justify its authority placement choice, not when it picks a specific approach. Explicitly states "centralized, local, or hybrid can all be correct depending on context."
- refactor(critic): Lens 5 "Single source of truth check" neutralized — removed stack-specific examples ("backend permission + frontend hook + serializer"). Now uses generic "component" language.
- refactor(critic): Lens 5 "Instance defaults check" renamed to "Configuration defaults check" — removed "env var / Django setting / config", replaced with "whatever configuration surface the project uses".
- refactor(critic): Lens 5 "Coupling check" example neutralized — removed recording-specific example, replaced with generic "module gaining an unexpected dependency on an unrelated domain".
- No behavior change to the critic's Lens 5 severity rules, APPROVE/REJECT decision table, or the brainstorm trace check. Only the bias in the individual check descriptions is removed.

## 3.7.1 (2026-04-09)

### Research skill — chain-of-custody decomposition into 6 step files

Sixth application of the chain-of-custody pattern. Decomposition of `/ops-research` (143 lines). The skill uses the same 3-parallel-agents dispatch pattern as plan's Step 3 (already protected with `<HARD-GATE-RESEARCH>` in the plan decomposition), making it a natural fit for the same enforcement pattern as a standalone skill.

- feat(research): `SKILL.md` rewritten as a ~55-line bootstrap containing Instruction Priority and Subagent Rules references, purpose, workflow diagram with the 6 step file paths, execution rules (including the note that Steps 4 and 5 are conditional on researcher-doc's output), and the constraints section (no changes, no planning, cite sources). No step content remains in `SKILL.md`.
- feat(research): 6 new step files under `skills/research/`:
  - `step-01-clarify.md` — creates the 6-task progress checklist as a preamble (with explicit note that tasks 4 and 5 are conditional), then restates the user's question and asks ONE clarifying question if scope is ambiguous.
  - `step-02-parallel-research.md` — contains `<HARD-GATE-RESEARCH>` collocated with the 3-agent dispatch instruction (researcher-code + researcher-doc + git-historian in Research Mode, single message), preserving the exact enforcement pattern from plan's Step 3.
  - `step-03-synthesize.md` — combines agent findings (agreements/gaps/contradictions), parses researcher-doc's `Source Verification Needed` list, **branching hand-off**: Branch A (no high targets → skip to step-06, mark steps 4 and 5 as completed with N/A note), Branch B (high targets → step-04).
  - `step-04-conditional-repo-analysis.md` — only runs if Branch B was chosen. Dispatches researcher-repo agents in parallel (one per high-severity target) with full context (target name, ecosystem, Step 3 synthesis, researcher-doc rationale, repo URL).
  - `step-05-final-synthesis.md` — only runs if Step 4 ran. Integrates researcher-repo findings into the Step 3 synthesis.
  - `step-06-present.md` — structured synthesis output template (Codebase Patterns / Documentation / History & Ownership / Repository Analysis / Risk Assessment / Gaps) with every finding citing its source. Asks user whether to dig deeper or proceed to planning/implementation.
- feat(research): every step file ends with a mandatory `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction, and (c) an explicit hand-off. Step 3 has a branching hand-off handling both the "no repo analysis needed" and "repo analysis needed" branches with explicit task marking for the conditional steps (step 4/5 tasks are marked completed with N/A note in Branch A rather than left pending). Step 6 is terminal.
- feat(research): task tracking added — Step 1's preamble creates a 6-task checklist. Task names: "Research: clarify", "Research: parallel research", "Research: synthesize", "Research: conditional repo analysis", "Research: final synthesis", "Research: present". Tasks 4 and 5 are created upfront but marked `completed` with the note "not applicable — no high-severity source verification gaps" if Branch A is taken in Step 3. This gives visible progress tracking with transparent conditional handling.
- No content loss: the `<HARD-GATE-RESEARCH>` block is preserved verbatim from the original (same content, only relocated from the inline section to inside `step-02-parallel-research.md`). The 3 agent descriptions (researcher-code, researcher-doc, git-historian with Research Mode and 6-month window), the Source Verification Needed parsing logic (absent / low / high), the researcher-repo dispatch prompt template (target name, ecosystem, topic, synthesis, rationale, repo URL), the Present output template, and the read-only constraints are all intact.
- No behavior change: the 6-step workflow, the 3-agents parallel dispatch, the conditional repo analysis trigger, the synthesis logic, and the downstream handoff expectation all behave identically to v3.7.0. Only the file layout, the branching hand-off structure, and the addition of task tracking changed.

## 3.7.0 (2026-04-09)

### Debug skill — chain-of-custody decomposition into 8 step files

Fifth application of the chain-of-custody pattern after brainstorm (3.3.0), plan (3.4.0), implement (3.5.0), and init (3.6.0). Decomposition of `/ops-debug` (185 lines — the largest skill not yet decomposed). Structurally similar to implement: multi-step workflow with typed agent dispatch (git-historian), per-step enforcement rules, code quality + review pipeline, discovery check, and circuit breaker. The Iron Law ("NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST") is a strong de facto hard gate that benefits from explicit HARD-GATE framing for weaker models.

- feat(debug): `SKILL.md` rewritten as a ~65-line bootstrap containing the new `<HARD-GATE-IRON-LAW>` block (wrapping the existing Iron Law with explicit FAILURE enforcement language), Instruction Priority and Subagent Rules references, workflow diagram with the 8 step file paths, execution rules (including the notes that Step 1.5 Instrumentation is inlined into step-01, Circuit Breaker is inlined into step-04, and Step 3 has a branching hand-off), and the global "Red Flags — you are about to guess" anti-pattern table (5 rows). No step content remains in `SKILL.md`.
- feat(debug): 8 new step files under `skills/debug/`:
  - `step-00-browser-bug-triage.md` — creates the 8-task progress checklist as a preamble, then determines whether the bug is browser-related and which chrome-devtools-mcp skills to use in Steps 1, 3, 7.
  - `step-01-investigate.md` — 5-point investigation (read error, reproduce, git-historian dispatch in Investigation Mode, trace data flow, combine findings) + **inlined Step 1.5 (conditional Instrumentation)** as a sub-section with its "skip if" condition. Enforces "DO NOT attempt a fix during investigation — Iron Law".
  - `step-02-hypothesize.md` — max 3 hypotheses rule with the 3-column table template (hypothesis / supporting evidence / would disprove it), ranked by likelihood, explicit "do NOT exceed 3" enforcement.
  - `step-03-test-hypotheses.md` — test each hypothesis with a minimal test, non-deterministic bug handling (run 5+ times for timing issues), **branching hand-off**: Branch A (at least one CONFIRMED → step-04), Branch B (all REFUTED → back to step-01 to re-investigate, do NOT mark the task completed, do NOT attempt a fix).
  - `step-04-fix.md` — write the minimal fix addressing the confirmed root cause, **added Failure Handling** (new 3-attempt retry rule, borrowed from implement's Step 2 pattern to strengthen the Iron Law discipline before the 5+ circuit breaker triggers — see the dedicated bullet below for the behavior delta) + **inlined Circuit Breaker** (5+ failed attempts → `ops-circuit-breaker` process + escalate to user, do NOT mark task completed).
  - `step-05-code-review.md` — ops-code-quality + ops-security-gate + code-reviewer dispatch, with the "trivial fix exception" branch (skip only if ≤1 file AND pure typo/comment/config change with no logic).
  - `step-06-discovery-check.md` — apply `ops-discovery-checks` process with scope "the current fix" and pause target "debugging".
  - `step-07-verify.md` — run original failing command, run related tests for regressions, show evidence output explicitly, then declare fixed.
- feat(debug): every step file ends with a mandatory `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) an explicit hand-off pointing to the next file. Step 3 has a branching hand-off (Branch A → step-04, Branch B → back to step-01). Step 7 is terminal ("Skill complete. There is no next file to read.").
- feat(debug): task tracking added — Step 0's preamble creates an 8-task checklist matching the 8 steps. Task names: "Debug: browser bug triage", "Debug: investigate", "Debug: hypothesize", "Debug: test hypotheses", "Debug: fix", "Debug: code review", "Debug: discovery check", "Debug: verify". Each step file marks its own task `in_progress` at the start and `completed` at the end via `TaskUpdate`. Mirrors the pattern established in brainstorm 3.3.0, plan 3.4.0, and init 3.6.0.
- refactor(debug): Iron Law upgraded from a `## The Iron Law` prose section to a `<HARD-GATE-IRON-LAW>` block with explicit FAILURE enforcement language. The original wording ("NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST. Violating the letter of the rules is violating the spirit of the rules. Do NOT guess. Investigate systematically. Understand the root cause before writing a fix.") is preserved verbatim, plus a new enforcement sentence: "If you catch yourself about to write a fix without a CONFIRMED hypothesis from Step 3, STOP — you are violating the Iron Law and this is a FAILURE of this skill." This is the same pattern applied to init's `<HARD-GATE-LANGUAGE>` in v3.6.0 — take an implicit strong rule and make it an explicit enforceable gate.
- refactor(debug): Several enforcement sentences added to step bodies to reinforce the HARD-GATE-IRON-LAW framing. Locations: `step-00-browser-bug-triage.md` adds a non-browser fall-through clarification ("If the bug is not browser-related... note it and proceed."); `step-01-investigate.md` adds an Iron Law back-reference after "DO NOT attempt a fix during investigation"; `step-02-hypothesize.md` adds an explicit "Do NOT exceed 3 hypotheses" enforcement clause with go-back instruction; `step-03-test-hypotheses.md` adds an explicit "Do NOT attempt a fix without a CONFIRMED hypothesis — this violates the Iron Law" reminder; `step-05-code-review.md` strengthens the trivial fix exception with "Any logic change — however small — does NOT qualify"; `step-06-discovery-check.md` extends the discovery source list to mention "or by the git-historian results from Step 1"; `step-07-verify.md` strengthens the evidence requirement from "(command output)" to "(command output, not just 'it works')". All seven additions are aligned with existing semantics and strictly stricter than v3.6.2 — no new rules contradicting prior behavior, only explicit reinforcement of rules that were already implicit in the prose. The new enforcement sentences exist because chain-of-custody decomposition for weaker models benefits from making implicit rules explicit at the point of execution (the same rationale that produced HARD-GATE-NO-BUNDLING in v3.6.1 and HARD-GATE-LANGUAGE in v3.6.2).
- No content loss: Step 1.5 (Instrument) preserved verbatim as an inline sub-section in `step-01-investigate.md` with its "skip if" condition. Circuit Breaker preserved verbatim as an inline sub-section in `step-04-fix.md`. Step 2's hypothesis table template, Step 3's non-deterministic bug handling (run at least 5 times, add timing instrumentation, look for shared state), Step 5's trivial fix exception, and the Red Flags table (5 rows) are all intact.
- One new behavioral addition (otherwise no behavior change in existing rules): the 3-attempt Failure Handling retry rule in `step-04-fix.md` (documented in the step-04 bullet above). Borrowed from `skills/implement/step-02-execute-tasks.md`'s pattern, this rule introduces an intermediate retry escalation (1st failure → adjust fix, 2nd failure → try different approach, 3rd failure → reconsider the confirmed hypothesis) BEFORE the existing 5+ circuit breaker triggers. It is strictly stricter than v3.6.2 (which only had the 5+ circuit breaker with no intermediate ladder), aligned with the Iron Law discipline (forces the model back to Step 3 to re-examine the hypothesis after 3 failures rather than blindly continuing), and does not contradict any v3.6.2 rule. The 8-step workflow, the Iron Law semantics, the max-3-hypotheses rule, the git-historian Investigation Mode dispatch (scope: error-path files, window: 30 days, focus: regressions), the 5+ circuit breaker trigger, the trivial fix exception, the code-reviewer + security-gate dispatch pattern, the Discovery Check scope/pause-target, and the downstream expectation (show evidence before declaring fixed) all behave identically to v3.6.2. File layout changes, Iron Law framing as HARD-GATE, addition of task tracking, and the enforcement sentence additions in step bodies (documented above) are pure restructure / explicit reinforcement — none contradict v3.6.2 semantics.

## 3.6.2 (2026-04-09)

### Implement skill — add HARD-GATE-LANGUAGE to prevent mid-session language drift

Second empirical defect observed during chain-of-custody validation on GLM-5.1 (OpenCode), separate from the v3.6.1 no-bundling issue but present in the same validation context. The conversation started in French, brainstorm and plan executed entirely in French, but when transitioning into `/ops-implement` the model's user-facing output switched to English and stayed in English for subsequent messages — while the user's prompts were still in French.

Root cause: no ops skill other than `/ops-init` has an explicit language consistency rule. The model's "language state" is inferred implicitly from the conversation context, and over long sessions the implicit anchor toward English (from reading many English step files and English tool outputs — build logs, validation errors, agent reports) can overcome the user's non-English prompts. Implement is the most likely skill to trigger this drift because its step files are the most technically dense (vocabulary like "implementer / validation gate / conformity check / HARD-GATE / dispatch" saturates the attention) and its Step 2 loop generates the longest runs of English tool output.

- fix(implement): new `<HARD-GATE-LANGUAGE>` block in `skills/implement/SKILL.md` bootstrap, placed immediately after the existing top-level `<HARD-GATE>` block and before `## Instruction Priority`. Five sentences, tight: (1) user-facing output uses the user's conversation language; (2) technical terms (tool/command/skill/agent names, code identifiers, paths) stay in English; (3) step files are English tooling for the model, not content for the user — reading English instructions does NOT license English replies; (4) if the model catches itself drafting a reply in English when the user writes in another language, STOP and restart in the user's language; (5) drift to English mid-session is a FAILURE.
- Scope: intentionally localized to `skills/implement/SKILL.md` only, NOT echoed into `step-02-execute-tasks.md`. Rationale: the no-bundling gate required a step-02 echo in v3.6.1 because the bypass was observed INSIDE the loop iteration; the language drift, by contrast, was observed at the SKILL.md-to-step-02 transition and could be a one-shot anchoring effect rather than a loop-iterated drift. A single gate at the top of SKILL.md should be sufficient. If language drift recurs inside the loop despite this gate, a step-02 echo can be added in a follow-up patch.
- Scope: not applied to brainstorm, plan, or init — the observed drift happened only at the implement transition. Brainstorm and plan ran entirely in French throughout the validation session. Applying the fix globally to all 4 decomposed skills would be speculative defense without empirical evidence in those skills.
- No behavior change in sessions that were already maintaining language consistency (typically Claude Code on a well-aligned Claude model) — the gate adds a constraint that compliant models already satisfy. The gate targets the specific drift pattern observed on GLM-5.1 and similar non-Claude models.

## 3.6.1 (2026-04-09)

### Implement skill — reinforce no-bundling HARD-GATE at the top of step-02 (observed bypass attempt)

First empirical defect found during chain-of-custody validation on GLM-5.1 (OpenCode). An end-to-end session executed `/ops-brainstorm` → `/ops-plan` → `/ops-implement` flawlessly across 31 step files, but when entering `step-02-execute-tasks.md` with an 18-task plan, the model offered the user three options:

1. "Execute the full pipeline rigorously (18 individual implementer dispatches + per-task reviews — very thorough but very long)"
2. "Execute tasks directly myself using the edit tools, task by task" (bypass)
3. "Batch the simpler tasks into direct edits, then use subagents for the complex frontend tasks" (bundling + bypass)

The user correctly picked option 1, so the session remained compliant, but the fact that options 2 and 3 were offered at all is a direct violation of the top-level `<HARD-GATE>` block in `skills/implement/SKILL.md` which forbids bundling and bypass with explicit FAILURE language. The diagnosis: in LOOP steps (implement Step 2 loops per-task), the top-level HARD-GATE in the bootstrap `SKILL.md` is read once at skill invocation and then drifts far from the point of enforcement as the loop progresses. The "One task per agent" bullet inside `## 2a. Dispatch Implementer Agent` was not formatted as a HARD gate and did not trigger the same compliance weight as the bootstrap gate. This is a pattern-specific weakness: linear decomposed skills (brainstorm, plan, init) do not have this issue because each step is read once and handed off immediately — but implement's Step 2 is re-executed N times in a loop inside the same file.

- fix(implement): new `<HARD-GATE-NO-BUNDLING>` block added at the very top of `skills/implement/step-02-execute-tasks.md`, between the `# Step 2 — Execute Tasks` H1 and the "For each task in the plan..." intro. The block explicitly forbids bundling, bypass, and offering the user "faster alternatives" or "lighter options". It lists four verbatim forbidden phrasings (including the exact phrases GLM-5.1 used in the observed bypass attempt) with "you have FAILED this skill" enforcement language. It explicitly says "Token cost is NOT a valid reason to bundle" to address the rationalization the model used ("faster, same result, just without the subagent overhead"). It references the post-hoc count audit in the End of Step 2 completion checklist as the fail-safe, and explains that this gate is a deliberate reinforcement of the SKILL.md top-level gate because the top-level gate is "far" from the enforcement point in a LOOP step.
- No other changes to `step-02-execute-tasks.md` — the 6 sub-sections (2a-2f), the Failure Handling sub-section, and the End of Step 2 block are unchanged.
- No behavior change in the compliant case: the new gate does not add any new required action, it only forbids more bypass patterns explicitly. Sessions that were already following the top-level HARD-GATE (like the Claude Code runtime does reliably) will see no difference in execution.
- Lesson for future chain-of-custody decompositions: **LOOP steps require gate repetition at the top of the loop file**. Linear steps can rely on the bootstrap SKILL.md gate because each step is visited once and the bootstrap is still "fresh" in attention. Loops break this assumption — the step file is re-entered repeatedly, but the bootstrap is read only once at skill invocation. Any future skill decomposition with a loop step (none are currently planned) must repeat the top-level gates inside the loop file.

## 3.6.0 (2026-04-09)

### Init skill — chain-of-custody decomposition into 7 step files (OpenCode + weaker-models compatibility)

Fourth application of the chain-of-custody pattern validated in 3.3.0 (brainstorm), 3.4.0 (plan), and 3.5.0 (implement). The init skill is the third-largest in the repo at 318 lines. Motivation is identical: the skill runs on non-Claude models via OpenCode whose instruction-following is weaker than Claude's family. Init was a high-priority target because its language prime-directive (Phase 0's `echo $LANG` instruction) was buried in prose and models would frequently start producing diagnostic output before detecting the language — producing English output in a French locale and vice versa.

- feat(init): `SKILL.md` rewritten as a ~80-line bootstrap containing the new `<HARD-GATE-LANGUAGE>` block (making the language prime-directive explicit and enforceable), the Instruction Priority reference, the global `## Stop-and-propose rule` section, the workflow diagram with the 7 step file paths, the 8-rule execution section, and the global `## Rules` section (hoisted from the very bottom of the old file to the bootstrap where it primes behavior for every step). No step content remains in `SKILL.md`.
- feat(init): 7 new step files under `skills/init/`:
  - `step-00-bootstrap.md` — language detection (CRITICAL prime-directive repeated as Preamble 1), creates the 7-task progress checklist as Preamble 2, then 0a detect CLI (with early-exit for unknown CLI), 0b detect languages (single combined glob), 0c detect package managers, 0d summary output.
  - `step-01-recap.md` — 1a skills count, 1b agents count, 1c MCP dispatch to CLI-specific sub-skill (`claude-code.md` or `opencode.md`).
  - `step-02-ops-tools.md` — 2a qlty, 2b semgrep, 2c JSON parser, stop-and-propose with install command tables and qlty init fallback.
  - `step-03-project-linters.md` — detect project linters, verify installation, stop-and-propose.
  - `step-04-linter-prerequisites.md` — Level 1 package/dependency environment, Level 2 plugins and type stubs, stop-and-propose with multi-method install options.
  - `step-05-build-tools.md` — detect expected build tools from 12 project indicators, stop-and-propose.
  - `step-06-lsp.md` — LSP dispatch to CLI-specific sub-skill + Final Summary table inlined at the end (was a separate section in the old file; inlining avoids a trivial step-07 file for 8 lines of template).
- feat(init): new `<HARD-GATE-LANGUAGE>` block in `SKILL.md` bootstrap, making the language prime-directive explicit and enforceable at skill-invocation time. The block says: "Your very first action — before reading any step file, before any diagnostic, before any tool call other than this one — must be to run `echo $LANG` via Bash ... If you start producing diagnostic output (including reading any other step file) without having first run `echo $LANG` and chosen the output language, you have FAILED this skill." The directive is also repeated inside `step-00-bootstrap.md` as Preamble 1 for redundancy. Previously this directive was buried in Phase 0's prose and models frequently skipped it on weaker providers.
- refactor(init): internal terminology renamed "Phase" → "Step" throughout for consistency with the other decomposed skills (brainstorm, plan, implement all use "Step N"). Pure terminology rename with no behavior change. Affected locations: all 7 step files' H1 headers (`# Phase 0 — Bootstrap` → `# Step 0 — Bootstrap`, etc.), the workflow table in `SKILL.md`, every cross-reference from one step to another ("Phase 0c" → "Step 0c" in step-02's install-command-filtering note, "Phase 3" → "Step 3" in step-04's "for each installed linter" instruction, "Phase 0b" → "Step 0b" in the Rules section, "Phase 6" → "Step 6" in the workflow description), the Final Summary table header column (`| Phase | Status |` → `| Step | Status |`), and the `## Stop-and-propose rule` description ("stop at the end of that phase" → "stop at the end of that step", "combine multiple phases" → "combine multiple steps"). Zero semantic change.
- feat(init): every step file ends with a mandatory `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) an explicit hand-off pointing to the next file. Step 6 is the terminal step with "Skill complete. There is no next file to read."
- feat(init): task tracking preserved and made explicit — the original `## Task tracking` section (old lines 22-24) instructed to "create one task per phase" without naming them. Task naming is now explicit in `step-00-bootstrap.md`'s Preamble 2, with 7 named tasks: "Init: bootstrap", "Init: recap", "Init: ops tools", "Init: project linters", "Init: linter prerequisites", "Init: build tools", "Init: LSP". Each step file marks its own task `in_progress` at the start and `completed` at the end via `TaskUpdate`. This mirrors the pattern established in brainstorm 3.3.0 and plan 3.4.0.
- No content loss: the language prime-directive, the CLI detection + early-exit for unknown CLI, the combined-extensions glob pattern, the Ansible detection heuristics, the stop-and-propose rule, the qlty/semgrep install command tables (including the curl-always fallback for qlty), the qlty init fallback condition table, the linter detection list, the Level 1 / Level 2 prerequisite structure with multi-install-method options, the build tool detection table (12 indicators), the CLI-specific sub-skill dispatches (old Phase 1c → new step-01 1c; old Phase 6 → new step-06), and the Final Summary table are all preserved. The global `## Rules` section (old lines 311-318) is relocated verbatim from the bottom of the old file to the bootstrap `SKILL.md`, where it applies to every step.
- No behavior change: the 7-step workflow, the language prime-directive (now more enforceable via the explicit HARD-GATE wrapper), the stop-and-propose mechanism, the 4 A/B/C-style option prompts across steps 2-5, the CLI sub-skill dispatches, the task tracking, the Final Summary, and the downstream expectation (tools are reported but NOT passed to downstream skills) all behave identically to v3.5.0. Only the file layout, the "Phase" → "Step" terminology rename, the explicit `<HARD-GATE-LANGUAGE>` framing, and the hoisting of the Rules section from the bottom to the bootstrap changed.

## 3.5.0 (2026-04-09)

### Implement skill — chain-of-custody decomposition into 4 step files (OpenCode + weaker-models compatibility)

Third application of the chain-of-custody pattern validated in 3.3.0 (brainstorm) and 3.4.0 (plan). The implement skill was the largest in the repo at 401 lines with four distributed `<HARD-GATE-*>` blocks — the highest-risk skill for silent gate-skipping on weaker models.

- feat(implement): `SKILL.md` rewritten as a ~140-line bootstrap containing the top-level `<HARD-GATE>` block (pipeline enforcement + bundling prohibition + two-review-layers rationale), the Instruction Priority and Subagent Rules references, the Prerequisite, the workflow diagram with the 4 step file paths, the execution rules (including the "Step 2 is a per-task LOOP" reminder), and the global "Red Flags — you are about to break the pipeline" anti-pattern table (8 rows). No step content remains in `SKILL.md`.
- feat(implement): 4 new step files under `skills/implement/`:
  - `step-01-load-plan.md` — loads the plan, verifies task decomposition, registers plan tasks via `TaskCreate`.
  - `step-02-execute-tasks.md` — **the per-task LOOP**. Contains all 6 sub-steps (2a Dispatch Implementer, 2b Validation Gate, 2c Conformity Check, 2d Per-task Quality Review with `<HARD-GATE-PER-TASK-REVIEW>`, 2e Discovery Check, 2f Task Completion Record) inline as `##`-level headings, plus the inlined Failure Handling sub-section. The End of Step 2 block explicitly instructs the model to stay in this file and iterate through ALL plan tasks before handing off to Step 3.
  - `step-03-final-review.md` — renumbered from the original Step 4. Contains Pre-review Audit, `<HARD-GATE-CODE-QUALITY>`-wrapped Code Quality sub-section, Security Triage (14 triggers), Dispatch Reviews (code-reviewer + optional security-reviewer in parallel), and Handle Review Results.
  - `step-04-completion.md` — renumbered from the original Step 5. Contains `<HARD-GATE-FINAL-VALIDATION>`, the `## Final Validation Checklist` block, `TaskList` verification, completion summary, Learnings capture, spec status update to `Implemented`, and the "what next?" user prompt.
- feat(implement): the original `Step 3: Failure Handling` (~15 lines) has been **inlined into `step-02-execute-tasks.md`** as a `## Failure Handling` sub-section at the end of the per-task pipeline. It is not a sequential step — it is a sub-procedure that kicks in during Step 2b when a task fails validation. Inlining is semantically cleaner than a trivial orphan file.
- feat(implement): every step file ends with a mandatory `## ✅ End of Step N` block containing (a) a step-specific completion checklist and (b) an explicit hand-off pointing to the next file. Step 2's End block is the LOOP gate — it explicitly instructs the model to return to the top of the file while plan tasks remain, and only hand off to Step 3 when all plan tasks have been processed.
- refactor(implement): internal "Step 4" and "Step 5" references renumbered consistently to "Step 3" and "Step 4" to match the new 4-step numbering. Affected locations: top-level `<HARD-GATE>` block ("Final review (Step 4)" → "(Step 3)"), Step 2a DONE_WITH_CONCERNS handling ("final completion summary (Step 5)" → "Step 4"), Step 2d rationale ("which happens in Step 4 on the full diff" → "Step 3", "Final review (Step 4) is the expensive one" → "Step 3", "security-reviewer in Step 4 handles that" → "Step 3"), Step 2f Task Completion Record ("feeds the final validation in Step 5" → "Step 4"), `<HARD-GATE-CODE-QUALITY>` block (4 "Step 4" → "Step 3" references), Step 4 completion summary bullet ("the final review (Step 4)" → "Step 3"). All are mechanical 1-character-word updates.
- No new task tracking added: `/ops-implement` already uses `TaskCreate`/`TaskUpdate`/`TaskList` for **plan-task** tracking (registered in Step 1, updated during Step 2, verified in Step 4). Adding step-level tasks would duplicate this and clutter the user-visible task list. Step files' `## ✅ End of Step N` blocks therefore do NOT include `TaskUpdate` for step-level progress — they rely on the existing plan-task tracking for progress visibility. This is an intentional deviation from the brainstorm/plan decomposition pattern, justified by implement's pre-existing task tracking.
- No content loss: all four `<HARD-GATE-*>` blocks preserved verbatim content-wise (with only the mechanical "Step 4" → "Step 3" reference updates noted above); the 2a Model Selection table, the 2b validation command table, the per-task dispatch prompt (including the 5 placeholder variants for non-text content), the repeated-finding circuit breaker rule, the Task Completion Record template, the Failure Handling procedure, the Pre-review Audit block template, the Security Triage block template, the code-reviewer and security-reviewer dispatch instructions, the Final Validation Checklist template, and the Learnings capture template are all intact.
- No behavior change: the per-task pipeline (2a → 2f), the two review layers (per-task lightweight + final full-diff), the four HARD gates, the required output blocks, the 3-fail retry + circuit breaker, the `TaskList` verification, and the downstream `/ops-ship` expectation all behave identically to v3.4.0. Only the file layout and the "Step N" numbering (Step 4→3, Step 5→4, old Step 3 inlined into Step 2) changed.

## 3.4.0 (2026-04-09)

### Plan skill — chain-of-custody decomposition into 10 step files (OpenCode + weaker-models compatibility)

Second application of the chain-of-custody pattern validated in 3.3.0 on the brainstorm skill. The plan skill has been decomposed into 10 sequential step files numbered 00-09 (matching the existing Step 0 to Step 9 sequence). Motivation is identical: the skill runs on non-Claude models via OpenCode whose instruction-following is weaker than Claude's family, and the monolithic 426-line `SKILL.md` was exceeding their effective attention budget. Plan was the most urgent next target because it is the longest ops skill and has four distributed HARD gates that weaker models were silently skipping.

- feat(plan): `SKILL.md` rewritten as a ~130-line bootstrap containing the two top-level hard gates (`HARD-GATE-0`, `HARD-GATE-1`), the "When to use which skill" decision table, the Instruction Priority and Subagent Rules references, the Overview, the workflow diagram with all 10 file paths, the execution rules (including the branching-hand-off rule for Steps 4 and 8), and the global "Red Flags — you are about to skip a step" anti-pattern table. No step content remains in `SKILL.md`.
- feat(plan): 10 new step files under `skills/plan/`:
  - `step-00-discover-commands.md` — creates the 10-task progress checklist as a preamble, then discovers project test/build/lint commands. Environment health check with `/ops-init` proposal preserved. Contains a reminder of HARD-GATE-0 and HARD-GATE-1 from the bootstrap.
  - `step-01-clarify-intent.md` — clarity check + scope check + brainstorm offer, with the "brainstorm already done" branch preserved. Requires the `## Intent Confirmed` output block regardless of which branch.
  - `step-02-context-detection.md` — project instruction file + directory structure + conventions.
  - `step-03-parallel-research.md` — `HARD-GATE-RESEARCH` collocated with the 3-agent dispatch instruction (researcher-code + researcher-doc + git-historian, single message).
  - `step-04-research-adequacy.md` — evidence table with 4 dimensions, **branching hand-off with 3 branches**: Branch A (3-4 OK → Step 5), Branch B (1-2 GAP → stay in step, fill the gap, re-evaluate), Branch C (0 evidence → go back to Step 1).
  - `step-05-design-approaches.md` — 2-3 approaches with name/how/pros/cons/fits/reuse + mandatory External Dependency Validation block + approach gate.
  - `step-06-write-review-spec.md` — sub-steps 6a/6b/6c/6d kept in a single file (tightly coupled: present by sections → write file → spec-reviewer loop → present to user). The inner spec-review loop is handled inside the step, not at the hand-off level.
  - `step-07-write-plan.md` — task decomposition mandatory rules + no-placeholders list + project-instruction-driven tasks + sizing guide + TDD granularity.
  - `step-08-critic-review.md` — required dispatch context (plan path, spec path, brainstorm summary verbatim, project instruction file), Lens 5 brainstorm trace rationale, degraded case, `## Critic Re-verification` block template, **branching hand-off with 2 branches**: Branch A (APPROVE → Step 9), Branch B (REJECT → stay, re-dispatch via `ops-redispatch-optimization`, max 3 iterations, re-evaluate).
  - `step-09-user-approval.md` — `HARD-GATE-HANDOFF` collocated with the 3-option user prompt. Explicitly forbids implementing code inline.
- feat(plan): every step file ends with a mandatory `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) an explicit hand-off. Steps 4 and 8 have branching hand-offs that explicitly describe each branch and the corresponding next file or loop-back behavior.
- feat(plan): task tracking added to `/ops-plan` (previously absent) — Step 0's preamble creates a 10-task checklist matching the 10 steps; each step file marks its own task `in_progress` at the start and `completed` at the end via `TaskUpdate`. This mirrors the pattern established in `/ops-brainstorm` 3.3.0. Task names: "Plan: discover commands", "Plan: clarify intent", "Plan: context detection", "Plan: parallel research", "Plan: research adequacy check", "Plan: design approaches", "Plan: write & review spec", "Plan: write plan", "Plan: critic review", "Plan: user approval".
- No content loss: all four `<HARD-GATE-*>` blocks preserved verbatim (`HARD-GATE-0` and `HARD-GATE-1` in `SKILL.md` bootstrap, `HARD-GATE-RESEARCH` in `step-03`, `HARD-GATE-HANDOFF` in `step-09`); the "When to use which skill" table, the research adequacy dimensions table, the external-dependency validation template, the 5-section plan structure, the task decomposition rules, the no-placeholders list, the critic dispatch requirements, the `Critic Re-verification` block template, and the Red Flags table are all intact.
- Minor behavior change: task tracking was not previously part of `/ops-plan` — this is the only behavior change, documented explicitly above. The 10-step workflow, the 4 HARD gates, the required output blocks (`Discovered Commands`, `Intent Confirmed`, research adequacy table, `Critic Re-verification`), the re-dispatch loops, and the downstream `/ops-implement` handoff all behave identically to v3.3.0.

## 3.3.0 (2026-04-08)

### Brainstorm skill — chain-of-custody decomposition into 11 step files (OpenCode + weaker-models compatibility)

The brainstorm skill has been decomposed into 11 sequential step files using a chain-of-custody loading pattern. Motivation: the skill runs on non-Claude models via OpenCode (GPT-4o-mini, Mistral, Gemini Flash, local models) whose instruction-following is measurably weaker than the Claude family. A monolithic 345-line `SKILL.md` was exceeding the effective attention budget of these models — they would silently skip gates and dimensions. The chain-of-custody pattern reduces per-turn instruction load to a single 30-to-180-line step file, and an explicit hand-off at the end of each file removes the model's discretion over when to read the next step.

- feat(brainstorm): `SKILL.md` rewritten as a ~60-line bootstrap containing only purpose, workflow diagram with the 11 file paths, global constraints, execution rules, and the instruction to read `step-01-task-checklist.md` to begin. No step content remains in `SKILL.md`.
- feat(brainstorm): 11 new step files under `skills/brainstorm/`:
  - `step-01-task-checklist.md` — creates the 10-task progress checklist
  - `step-02-clarity-check.md` — restate-what-why-success gate
  - `step-03-explore-context.md` — project state / recent commits / conventions
  - `step-04-visual-companion.md` — mockups/diagrams companion offer
  - `step-05-assess-scope.md` — multi-subsystem decomposition check
  - `step-06-clarifying-questions.md` — intent/context A/B/C questions (one at a time)
  - `step-07-architectural-decisions.md` — HARD-GATE-FORK + 7-dimensions checklist with inline templates (the densest file, ~180 lines)
  - `step-08-design-sections.md` — section-by-section design validation
  - `step-09-yagni-filter.md` — YAGNI Check block
  - `step-10-summary.md` — Brainstorm Summary template with architectural-decisions block
  - `step-11-transition.md` — `/ops-plan` hand-off
- feat(brainstorm): every step file ends with a mandatory `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) an explicit hand-off: `**→ Next: read skills/brainstorm/step-NN+1-[name].md now and execute Step N+1.** Do NOT continue without reading that file first.` This is the chain-of-custody enforcement mechanism — the model does not decide when to load the next file, the current file tells it.
- feat(brainstorm): Step 1 task list expanded from 9 to 10 tasks — `summary & transition` split into `Brainstorm: summary` (Step 10) and `Brainstorm: transition` (Step 11) for atomic per-step progress tracking.
- No content loss: every instruction, template, gate, example, and constraint from the previous monolithic `SKILL.md` has been preserved verbatim and relocated into the appropriate step file. The `<HARD-GATE-FORK>` block (Step 7), the 7-dimension architectural checklist with its 3 inline templates, the Step 10 summary template with numbered dimensions, and the 5 global constraints are all intact.
- No behavior change in the brainstorm workflow: the 11 steps, the gates, the forced choices, and the downstream critic Lens 5 brainstorm trace consumption all behave identically. Only the file layout and per-turn attention load changed.

## 3.2.1 (2026-04-08)

### Brainstorm skill — Step 6/7 consolidation (structural refactor, no behavior change)

Resolved a dual source-of-truth problem in `skills/brainstorm/SKILL.md`: question templates for three architectural dimensions (instance defaults, authorization source, failure mode) lived in Step 6 while the checklist of seven dimensions they belong to lived in Step 7, forcing a meta-paragraph in Step 6 to explain the cross-reference. Symptom: weaker models lost track of which dimensions were templated and which were not, and the "applies if" conditions were duplicated in both steps.

- refactor(brainstorm): Step 6 reduced to intent/context clarification only (~15 lines). Templates A/B/C removed from Step 6; the meta-paragraph "Structure of this section" removed. A new "Scope of this step" note explicitly forbids anticipating Step 7's architectural questions in Step 6.
- refactor(brainstorm): Step 7 "Architectural Dimensions Checklist" restructured from a flat table into an overview table + seven numbered `#### Dimension N` sub-sections. The three templated dimensions (2 Source of truth for permissions, 3 Instance-wide defaults, 4 Failure mode) now contain their A/B/C(/D) templates inline, verbatim, collocated with the dimension they serve. The four non-templated dimensions keep their short question format.
- refactor(brainstorm): Step 10 Summary template renamed dimension headings from free-form ("Source of truth for permissions") to numbered ("Dimension 2 — Source of truth for permissions") to align with Step 7's numbering. Example text updated to reference "answer to Dimension N template" instead of "Template A/B/C answer".
- No behavior change: the HARD-GATE-FORK, the mandatory checklist, the forced choice rules, and the downstream critic Lens 5 brainstorm trace consumption all remain identical. Only the location and naming of content changed.

## 3.2.0 (2026-04-07)

### Architectural decision-locking and per-task quality review (inspired by superpowers analysis)

Improvements addressing a class of failure where `/ops-plan` produces an internally coherent plan whose architecture is measurably inferior to alternatives that were never considered. Root cause: the brainstorm phase deferred architectural decisions to research, and the research phase optimized for shortest implementation path rather than cleanest design. The fix has two pillars expressed across the entries below: (1) lock architectural decisions during brainstorm via mandatory question templates and a HARD-GATE-FORK, and (2) add an early-warning quality gate during implementation via a per-task code-reviewer dispatch with Lens-5-style drift detection.

- feat(brainstorm): `<HARD-GATE-FORK>` in Step 7 forbids deferring architectural decisions to `/ops-plan` or research. Phrases like "we'll figure this out during the plan", "TBD", or any equivalent deferral trigger a skill failure.
- feat(brainstorm): mandatory question Template A "Deployment-instance defaults" — A/B/C/D format covering env-var/setting overrides for instance operators. Applies to any feature with a toggle/policy.
- feat(brainstorm): mandatory question Template B "Source of truth for authorization" — A/B/C format forcing explicit choice between server-driven ability, client-driven reconciliation, or hybrid. Applies to any permission/visibility feature.
- feat(brainstorm): mandatory question Template C "Failure mode" — A/B/C format forcing explicit fail-closed/fail-open/retry choice. Applies to any feature with async or external dependencies.
- feat(brainstorm): Step 7 "Architectural Dimensions Checklist" with 7 dimensions (storage, authority placement, instance defaults, failure mode, UI placement, backward compatibility, test boundaries). Each applicable dimension must have an explicit user choice before moving to Step 8.
- feat(brainstorm): Step 10 Summary template now requires a structured `### Architectural decisions (per dimension)` section listing each Step 7 dimension with its chosen value. This is the data the critic's Lens 5 brainstorm trace check consumes.
- feat(brainstorm): Step 11 Transition explicitly requires keeping the Brainstorm Summary block visible in conversation context so `/ops-plan` Step 8 can attach it to the critic dispatch.
- feat(critic): new **Lens 5 — Architectural Alternatives** with 7 checks (single source of truth, authority placement, coupling, fragility, why-not-extract, instance defaults, brainstorm trace). Severity rules: REJECT if a meaningfully cleaner alternative exists, or if documented fragility affects security/permissions. Phase 6 verdict updated.
- feat(critic): new **4th perspective "Architect"** in Phase 3 multi-perspective review. Drives Lens 5. Surfaces design quality issues that the Executor / Stakeholder / Skeptic perspectives miss.
- feat(critic): new red flags row entries: "extends existing code = right pattern" → SHORTEST path, not CLEANEST; "fragility documented = OK" → documentation is not justification; "alternatives explored = no need to challenge" → if alternatives were explored, they should appear in the brainstorm summary.
- feat(plan): Step 8 critic dispatch now mandates a structured context block — plan path, spec path, **brainstorm summary verbatim** (required for Lens 5 brainstorm trace check), project instruction file. Degraded-case clause for direct `/ops-plan` invocation without prior brainstorm.
- feat(implement): new **Step 2d — Per-task Quality Review** between conformity check and discovery check. Lightweight code-reviewer dispatch on the cumulative working tree state captured by the new `scripts/ops-capture-task-state.sh` script (tracked diff via `git diff HEAD` plus untracked new file contents via `git ls-files --others --exclude-standard`), with the dispatch prompt scoping findings to the task being reviewed. Catches duplication and Lens-5-style architectural drift task by task while context is hot. Fix loop max 3 iterations with repeated-finding circuit breaker. Inspired by superpowers' subagent-driven-development pattern, adapted to ops's "no commit per task" convention.
- feat(scripts): new `scripts/ops-capture-task-state.sh` — read-only script that captures the cumulative working tree state for the per-task quality review (tracked changes via `git diff HEAD` + untracked new files via `git ls-files --others --exclude-standard`, with binary detection). Used by `/ops-implement` Step 2d. Tested empirically against clean trees, modified-only tasks, new-file-only tasks, mixed scenarios, binary files, and a real repo with 4273 lines of state. Per AGENTS.md convention: deterministic logic in `scripts/`, not inlined in skills.
- feat(implement): two-layer review architecture documented in HARD-GATE — per-task lightweight (Step 2d) catches single-task drift; final full-diff review (Step 4) catches cross-task issues. Both mandatory.
- feat(implement): `<HARD-GATE-CODE-QUALITY>` scoped to Step 4 final review only. The per-task review at Step 2d is exempt to keep iteration cheap. qlty/lint hygiene at the per-task level is delegated to commit hooks or to the final code-quality pass.
- feat(implement): per-task quality review entry in Task Completion Record (Step 2f) with iteration count and suggestions list.
- feat(implement): three new red flags row entries: "skip per-task, final will catch it", "fix per-task issues in final pass", "task 1 was clean so skip task 2".
- feat(researcher-code): new top-of-file mission statement — "**You report observations, not recommendations.**" Reframes the agent as observer rather than architect. Patterns are observations. Architectural decisions belong to the brainstorm phase and the planner.
- feat(researcher-code): explicit forbidden phrasing list — "recommended", "the right approach", "natural fit", "naturally extend", "we should", "the plan should". Required phrasing examples for neutral observation framing.
- feat(researcher-code): new output markers `[FRAGILITY]` for fire-and-forget / fail-open / missing tests on critical paths, `[POTENTIAL EXTENSION POINT]` for existing mechanisms the task could mechanically extend (decision deferred to planner).
- feat(researcher-code): Output Format updated — "Files in scope (observation, not prescription)" replaces "Files to Create/Modify"; "Currently interacts with" replaces "Will interact with"; "(observations only)" appended to Similar Implementations heading.
- fix(implement): line 123 referenced "completion summary (Step 4)" but the completion summary is in Step 5. Corrected to reference task completion record (Step 2f) and final completion summary (Step 5).
- fix(implement): renumbered sub-steps 2d→2e (Discovery Check) and 2e→2f (Task Completion Record) to make room for the new 2d (Per-task Quality Review). All cross-references updated.
- fix(full): Step 3 pipeline description updated to include the per-task quality review and completion record.
- fix(README + CHANGELOG): "4 lenses" → "5 lenses incl. architectural alternatives", "3 perspectives" → "4 perspectives incl. Architect".

## 3.1.1 (2026-04-02)

### Review skill — anti-sycophancy and source-aware feedback handling

- feat: add anti-sycophancy section to `ops-review` — forbidden responses table (performative agreement, gratitude expressions), correct response examples (technical acknowledgment only), self-test: "technical content or social noise?"
- feat: source-specific feedback handling — user feedback (trusted, skip to action) vs. external reviewers (verify technically first, 4-point checklist with YAGNI grep check)
- feat: strengthened ambiguity handling — STOP and clarify ALL unclear items before implementing, multi-item ordering: blocking → simple → complex, test each individually
- fix: consistency cleanup — "just say thanks" → "acknowledge and proceed", deduplicated Prohibited Behaviors table against new anti-sycophancy section
- inspired by superpowers plugin `receiving-code-review` skill, adapted to ops conventions

## 3.1.0 (2026-04-02)

### Targeted persuasion mechanisms for LLM compliance

- feat: add hybrid Red Flags / Rationalization tables to 6 core files — `implementer`, `critic`, `verify`, `plan`, `implement`, `debug`
- feat: elevate `verify` "The Gate" to named Iron Law with code-block preamble and letter/spirit inoculation
- feat: elevate `debug` "Philosophy" to named Iron Law with code-block preamble and letter/spirit inoculation
- feat: add letter/spirit inoculation to `implementer` TDD Iron Rule
- feat: add non-TDD Red Flags table to `implementer` agent (validation skip, scope creep, report honesty)
- feat: add anti-complacency Red Flags table to `critic` agent (rubber-stamping, premature approval)
- feat: CSO-optimized skill descriptions — 7 skills rewritten from process-focused to trigger-focused (`plan`, `implement`, `debug`, `do`, `refactor`, `ship`, `full`)
- docs: design spec at `docs/specs/2026-04-02-persuasion-mechanisms-design.md`

## 3.0.0 (2026-03-30)

### OpenCode compatibility + skill renaming + internal refactoring

- **BREAKING**: all skill names renamed from `ops:*` to `ops-*` for cross-platform filename compatibility (e.g., `/ops:plan` → `/ops-plan`)
- feat: OpenCode support via `.opencode/plugins/ops.js` (plugin ESM) with dynamic slash command registration
- feat: `package.json` added for OpenCode git-based plugin installation
- feat: `AGENTS.md` as primary project instructions (OpenCode native), `CLAUDE.md` now points to it via `@AGENTS.md`
- refactor: CLI-agnostic project instruction references — all skills and agents now reference `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (whichever exists) instead of hardcoded `CLAUDE.md`
- feat: `data/bootstrap-context.md` — shared skill routing table read by both Claude Code and OpenCode adapters
- feat: `.opencode/INSTALL.md` with installation instructions
- refactor: `hooks/session-start` reads `data/bootstrap-context.md` instead of hardcoded HEREDOC
- refactor: all cross-references, hook routing table, agent descriptions, README updated from `ops:*` to `ops-*`
- deleted: `COMPARISON-vs-SUPERPOWERS.md` (removed)
- refactor: `ops-init` CLI-agnostic redesign — CLI detection script, shared entry point, per-CLI sub-skills (Claude Code + OpenCode)
- refactor: extract shared review sequence (code quality → security gate → code review → project instruction check) into `ops-review-pipeline` internal skill — eliminates duplication across `do`, `perf`, `refactor`, and `test`
- refactor: `ops-plan` Step 0 no longer runs full `ops-init` — limited to project command discovery (build/test/lint), with environment health check that proposes `/ops-init` if issues detected
- refactor: `ops-init` simplified to single mode (user-invoked only), removed dual plan/user-invoked mode
- fix: clarify project instruction file locations as "at the project root" in `instruction-priority`, `review-pr`, `security`, and `review-pipeline` — prevents agents from searching user-level directories
- feat: `/ops-audit` — full codebase audit (qlty + semgrep), unified report with cross-triage and severity classification
- feat: duplication checks in `ops-plan` Step 5 (Reuse criterion) and critic Lens 1
- fix: remove dead semgrep baseline scan from `ops-init` (`.semgrep/baseline.json` was generated but never consumed)
- feat: `ops-init` restructured into 6 phases with stop-and-propose — recap (skills/agents/MCP), ops tools (qlty/semgrep), project linters, linter prerequisites, build tools, LSP
- feat: language rule in `ops-instruction-priority` — respond in the user's language
- feat: spec status lifecycle (`Draft` → `Approved` → `Implemented`) across `ops-plan` and `ops-implement`
- feat: `ops-do` scope guard redirects to `/ops-brainstorm` instead of `/ops-plan`
- feat: OpenCode agent registration via plugin `config.agent` hook — all 11 ops agents available as subagents
- feat: build verification step in `ops-review-pipeline` — propose compile/build before code review
- feat: LSP usage guidance in `ops-subagent-rules` — all agents prefer LSP over grep for code navigation
- fix: semgrep config — do not create `.semgrep.yml` (`--config auto` provides community rules)
- feat: English-only rule in `AGENTS.md` for the ops repository

## 2.3.4 (2026-03-30)

### Reasoning effort baselines for all agents

- feat: added `effort` frontmatter to all 11 agent definitions — opus agents default to `high`, sonnet agents (researcher-doc, git-historian) default to `medium`
- feat: added effort baseline rule to `ops:subagent-rules` — respect agent defaults, prefer lowering for mechanical subtasks
- docs: README agents table now includes Model and Effort columns

## 2.3.3 (2026-03-30)

### ops:plan — Lightweight intent clarification replaces built-in brainstorm

- refactor: replaced Step 1 full brainstorm process (~120 lines, 9 sub-steps) with lightweight intent clarification (~40 lines, 3 sub-steps: clarity check, scope check, offer `/ops:brainstorm`)
- removed: embedded brainstorm checklist, visual companion offer, YAGNI filter, design-by-sections, approach proposals — all now exclusive to `/ops:brainstorm`
- added: explicit suggestion to invoke `/ops:brainstorm` when the problem space is ambiguous
- renamed: gate block from "Brainstorm Complete" to "Intent Confirmed"
- updated: all internal references (workflow summary, hard gates, overview, research scoping) from "brainstorm" to "clarify intent"

## 2.3.2 (2026-03-30)

### ops:plan — Prompt consolidation (545 → 473 lines, -13%)

- refactor: removed graphviz diagram from Step 1 (-52 lines) — fully redundant with checklist + prose
- refactor: condensed "Proposing 2-3 approaches" in Step 1 to 2 lines (detail lives in Step 5)
- refactor: condensed "Presenting design by sections" in Step 1 to 2 lines (detail lives in Step 6a)
- refactor: merged duplicate dependency gates in Step 5 into single gate preserving content constraint, workflow sequencing, and consequence language
- refactor: condensed verbose prose in Step 1 — clarity check, clarifying questions, working in codebases
- refactor: removed 3 doubly-enforced emphasis instances (already covered by HARD-GATE tags or consequence language)

## 2.3.1 (2026-03-30)

### ops:plan — No-placeholders rule + TDD granularity

- feat: "No Placeholders" section — explicit list of plan anti-patterns (TBD, "similar to Task N", "add appropriate error handling", etc.)
- feat: TDD granularity rule — tasks should follow micro-cycle (write failing test → run → implement → run → commit) when applicable

### ops:implement — Model selection guidance

- feat: model selection guidance for implementer agents — mechanical tasks use fast models (sonnet/haiku), integration tasks use sonnet, architecture/judgment tasks use the default model
- Reduces cost and increases speed for well-specified tasks

## 2.3.0 (2026-03-30)

### ops:brainstorm — Richer brainstorming process (inspired by superpowers analysis)

- feat: new Step 7 "Propose 2-3 approaches" — present trade-offs and recommendation, wait for user choice before proceeding
- feat: new Step 8 "Present design by sections" — each section validated individually by the user before moving to the next
- feat: task tracking throughout brainstorming — 9 tasks created and tracked for progress visibility
- feat: Step 11 transition — direct offer to launch `/ops:plan`, skipping redundant re-brainstorming
- refactor: workflow expanded from 7 steps to 11

### ops:plan — Brainstorm phase alignment + validation improvements

- feat: Step 1 checklist expanded with "Propose 2-3 approaches" and "Present design by sections"
- feat: Step 1 detects if `/ops:brainstorm` was already run and skips to Step 2 with recap
- feat: Step 6a changed to section-by-section design validation with user approval per section
- feat: Brainstorm Complete gate block now tracks approach chosen and design sections validated
- fix: process flow (graphviz) updated with approach proposal and section validation loops
- fix: LSP diagnostics added to validation gate table in implement skill (Step 2b)
- fix: new Step 0b discovers project test/build commands (Makefile, bin/, package.json) for task validation
- fix: critic REJECT loop requires updating task breakdown to reflect spec changes from review loops

## 2.2.5 (2026-03-30)

### ops:plan — Hardened workflow gates (7 improvements)

- fix: new `HARD-GATE-HANDOFF` at Step 9 — `/ops:plan` NEVER implements code inline; user's "implemente" triggers `/ops:implement` as a separate skill invocation
- fix: critic REJECT now requires structured `## Critic Re-verification` output block before re-dispatch — prevents silent bypass of mandatory re-dispatch
- fix: `HARD-GATE-1` now forbids ALL agent types after Step 0 (was "research agent" only — Explore agents slipped through)
- feat: new Step 0b with mandatory `## Discovered Commands` output — task validation commands must use real project commands, not generic ones
- feat: mandatory `## Brainstorm Complete` exit summary before Step 2 — enforces visual companion evaluation and YAGNI check completion
- fix: Step 6a simplified — removed section-by-section approval requirement (redundant with spec-reviewer loop), keeps design presentation conversational
- fix: Step 9 now presents 3 explicit options (launch implement / review first / implement later) instead of open-ended question

## 2.2.4 (2026-03-24)

### ops:do — Workflow hardening

- fix: Step 1 restatement is now a gate (waits for user approval), with option to escalate to `/ops:brainstorm`
- fix: Step 4 task format requires executable shell validation commands, not prose descriptions
- fix: Step 6 code-quality now explicitly references skill file Steps 1–6 and handles missing tools gracefully (no brute-force retries)
- fix: Step 7 security-gate references `ops-semgrep-scan.sh` and its key=value output format (aligns with v2.2.3 script extraction)
- fix: Step 7 re-dispatch now includes both code-reviewer and security-reviewer when both found issues

## 2.2.3 (2026-03-24)

### Architecture — Script extraction

- feat: new `scripts/ops-semgrep-scan.sh` — encapsulates SAST scanning logic (config detection, diff-aware baseline, JSON parsing, error handling) previously described as LLM prompt prose
- feat: `hooks/session-start` derives `CLAUDE_PLUGIN_ROOT` and adds `scripts/` to PATH for direct script access (scripts prefixed `ops-` to avoid namespace collisions)
- dropped: `scripts/detect-tools.sh` concept — formatter/linter detection delegated to the LLM instead of a finite script; qlty/semgrep binary checks remain in respective skills

### ops:implement — Prose tightening

- chore: tightened implement skill prose (no semantic change)
- fix: `PROJECT_ROOT` in `ops-semgrep-scan.sh` now uses `git rev-parse --show-toplevel` instead of defaulting to CWD
- fix: file list detection in `ops-semgrep-scan.sh` now includes untracked files via `git ls-files --others --exclude-standard`

### ops:code-quality — Simplified tool detection

- refactor: tool detection (Step 1) now relies on LLM examination of project config files instead of a hardcoded tool list

### ops:security-gate — Script-based SAST

- refactor: semgrep invocation delegated to `ops-semgrep-scan.sh`, called directly from PATH
- feat: new `status=findings_unknown` when no JSON parser available — LLM parses raw JSON instead of relying on lossy grep fallback

### ops:setup — JSON parser diagnostic

- feat: Category 3 now detects `jq` / `python3` availability for semgrep result parsing

### Bug fixes (ops-semgrep-scan.sh)

- fix: paths with spaces handled correctly (array-based command construction)
- fix: semgrep stderr captured to temp file for diagnostics instead of being silently suppressed

## 2.2.2 (2026-03-23)

### ops:code-quality — Structural analysis (smells + metrics)

- feat: new Step 4 "Smells" — runs `qlty smells` on modified files to detect duplication, high cyclomatic complexity, and other structural issues
- Distinguishes new vs pre-existing smells: only flags issues introduced by the current work
- feat: new Step 5 "Metrics" — runs `qlty metrics --functions` on modified files, reports only functions exceeding thresholds (cognitive > 15, cyclomatic > 20)
- feat: security findings passthrough — qlty security plugin findings (trivy, trufflehog, osv-scanner, bandit, checkov) are forwarded to `ops:security-gate` instead of being handled in code-quality
- Steps renumbered: Report is now Step 6
- Report output updated with Smells, Metrics, and Security findings lines

### ops:security-gate — Diff-aware SAST + qlty integration

- feat: diff-aware semgrep scanning via `--baseline-commit` — only reports new findings, not pre-existing ones
- feat: baseline detection logic: feature branch → `git merge-base HEAD main`, main branch → `HEAD~1`, fallback documented
- fix: empty semgrep config handling — `.semgrep.yml` with `rules: []` now falls back to `--config auto`
- feat: new Step 1c — incorporates security findings from qlty into triage decision
- Dispatch decision now considers three signal sources: trigger triage + semgrep + qlty

### ops:implement — Traceable validation pipeline

- fix: Task Completion Record (Step 2e) now lists multiple validation commands instead of a single line
- fix: added explicit note linking per-task validation commands to final validation aggregation
- fix: Final validation (Step 5) expanded from one-liner to structured 5-step process: scan → deduplicate → expand scope → execute → report
- feat: Final Validation Checklist template with task attribution per command
- Security triage output now includes SAST and qlty security findings lines

### ops:debug — Aligned review pipeline

- fix: Step 5 restructured to follow the same sequence as ops:implement: Code Quality → Security Gate → Code Review

## 2.2.1 (2026-03-23)

### /ops:setup — Piebald-AI marketplace removal

- fix: removed `Piebald-AI/claude-code-lsps` third-party marketplace and all associated plugins (HTML/CSS, Vue, Scala, PowerShell, Julia, LaTeX, Ada, Solidity)
- Marketplace count reduced from 3 to 2 (`claude-plugins-official` + `boostvolt/claude-code-lsps`)
- Glob file extension list trimmed to match remaining marketplace coverage

### /ops:setup — MCP Servers diagnostic (Category 4)

- feat: new Category 4 "MCP Servers" in `/ops:setup` — checks `context7` and `chrome-devtools-mcp` plugin availability
- Verifies `enabledPlugins` and `extraKnownMarketplaces` in `~/.claude/settings.json`
- Grouped installation prompt (marketplace + plugin) with A/B/C options
- All "Categories 2-3" references updated to "Categories 2-4" across setup, plan, README

### /ops:debug — Browser Bug Triage (Step 0)

- feat: new Step 0 "Browser Bug Triage" in `/ops:debug` — routes to `chrome-devtools-mcp` skills for browser/frontend bugs

### /ops:plan — Spec no longer auto-committed

- fix: `/ops:plan` no longer commits the spec automatically — the user decides when to commit (via `/ops:ship` or manually)

### Cross-cutting updates

- README.md: updated setup description, requirements (added chrome-devtools-mcp), setup detail table, mermaid diagram

## 2.2.0 (2026-03-23)

### New skill: /ops:setup

- feat: new `/ops:setup` skill — diagnose environment (languages, LSP, code quality tools, security analysis tools) and propose installation for missing tools
- Absorbs `ops:environment-setup` internal phase — all language detection, 4-level LSP diagnostic, marketplace/plugin/binary tables migrated
- Two entry modes: user-invoked (full diagnostic + install proposals) or called by `/ops:plan` Step 0 (Categories 2-3 informational only)
- Detects qlty (unified code quality), semgrep (SAST), and project-specific formatters/linters

### qlty integration in code-quality

- feat: `ops:code-quality` now detects qlty as a priority unified tool — if `qlty` is in PATH and `.qlty/qlty.toml` exists, uses `qlty fmt` and `qlty check` instead of individual formatters/linters
- Two-stage detection: qlty in PATH + `.qlty/qlty.toml` present → use qlty; otherwise → fallback to individual tools
- Crash/timeout resilience: if qlty fails, logs error and continues with fallback
- Report now mentions `/ops:setup` when no tools are detected

### Semgrep integration in security-gate

- feat: new Step 1b in `ops:security-gate` — optional SAST scan with `semgrep scan --config auto --json` on modified files
- Gate-level triage of semgrep findings: LLM evaluates each finding in context of the diff before dispatching — obvious false positives are dismissed without consuming a security-reviewer cycle
- Security Triage output now includes SAST line (findings count / clean / not found / error)
- Crash/timeout/network resilience: if semgrep fails, logs error and continues with LLM triage only

### New file: mise.toml

- feat: `mise.toml` at repo root declares pipx, qlty (`github:qltysh/qlty`), and semgrep (`pipx:semgrep`) as development dependencies for ops contributors

### Cross-cutting updates

- skills/plan/SKILL.md: HARD-GATE-0 updated to reference `ops:setup` instead of prescriptive Glob/ToolSearch/LSP sequence; Step 0a reference changed from `ops:environment-setup` to `ops:setup`
- hooks/session-start: added `/ops:setup` to routing table and routing hints
- README.md: added `/ops:setup` to quick use, workflow diagram, standalone skills table, skills reference; updated code-quality and security-gate descriptions; added qlty and semgrep to requirements; updated structure tree
- .claude-plugin/plugin.json: version bump 2.1.1 → 2.2.0, added setup to description

### Removed

- `ops:environment-setup` internal phase — absorbed into `/ops:setup`

### Stats
- Skills: 17 user-facing + 7 internal phases = 24 total (was 16 + 8 = 24)
- Agents: 11 (unchanged)

## 2.1.1 (2026-03-23)

### Documentation

- docs: workflow and agent dispatch diagrams in README — global workflow diagram, per-skill agent dispatch map (LR layout with agents grouped by role), and individual mermaid diagrams for each skill showing the complete pipeline with agents as hexagonal nodes

### Skill hardening

- fix(implement): add hard gate for validation ownership — orchestrator must run validation commands, not rely on implementer's report
- fix(implement): add hard gate for code-quality ordering — must run before dispatching reviewers
- fix(implement): require structured security triage output (14-trigger checklist) before dispatch decision
- fix(implement): add hard gate for final validation — all commands from all tasks, explicit gap reporting
- fix(implement): strengthen TaskList consistency check — flag anomalies instead of silently proceeding
- fix(plan): require YAGNI assessment block in output before proceeding to research
- fix(plan): add hard gate for research dispatch — enforce exactly 3 typed agents in a single message

## 2.1.0 (2026-03-23)

### New agent: researcher-repo

- feat: new `researcher-repo` agent (Opus) — clones and analyzes external repositories (libraries, frameworks, applications, tools) when documentation and web research are insufficient
- Protocol: locate repo → detect version → shallow clone (version used) → analyze → optionally clone HEAD for comparison → structured report → cleanup
- Version-aware: clones the tag matching the project's dependency version, then optionally compares with HEAD/main
- Mandatory cleanup of cloned directories on completion (success or failure)

### New skill: /ops:clone-analyze

- feat: standalone skill for direct repository analysis — user invokes `/ops:clone-analyze <target>` to analyze an external repo
- 3-step workflow: Clarify → Dispatch researcher-repo → Present findings

### Conditional dispatch in /ops:research

- feat: `researcher-doc` now returns a `Source Verification Needed` list (per target: `high | low | none`) — signals which libraries/tools need source code analysis
- feat: `/ops:research` conditionally dispatches one or more `researcher-repo` agents in parallel for targets with `Needed: high`
- Workflow expanded from 4 steps to 6: Clarify → Parallel Research → Synthesize → Conditional Clone → Final Synthesize → Present

### Security

- fix: `--config core.hooksPath=/dev/null` on all `git clone` commands in researcher-repo — prevents execution of hooks from cloned repositories
- fix: `--config core.fsmonitor=false` on all `git clone` commands — prevents fsmonitor hook execution (CVE-2022-24765 vector)
- feat: post-clone `.gitattributes` filter audit — flags unknown filter drivers in the report

### Robustness

- feat: tag resolution via single `git ls-remote --tags --refs` call instead of 6 sequential clone attempts
- feat: pre-clone size guard via GitHub/GitLab API — abandons clone if repo exceeds 500 MB
- feat: added `pkg/v<version>` to tag resolution order for Go module repos

### Cross-cutting updates

- hooks/session-start: added `/ops:clone-analyze` to routing table
- skills/plan/SKILL.md: updated research delegation to mention parallel multi-target researcher-repo dispatch
- README.md: added researcher-repo agent, clone-analyze skill, updated counts (11 agents, 16 skills), added clone-analyze to Mermaid diagram
- agents/researcher-doc.md: documented that `Source Verification Needed` is consumed by `/ops:research` only

### Stats
- Agents: 10 → 11 (+researcher-repo)
- Skills: 15 → 16 user-facing (+clone-analyze)

## 2.0.1 (2026-03-21)

### Fixes from session 615af0fa analysis

#### Parallel dispatch enforcement (11 skills)
- fix: explicit "single message, multiple Agent tool_use blocks" rule in `ops:subagent-rules` — models were dispatching agents in separate messages (sequential) despite "in parallel" instructions
- fix: inline reminders at every parallel dispatch site (research, implement, do, test, perf, refactor, circuit-breaker, review-pr, debug)
- fix: `ops:subagent-rules` heading and description updated to reflect new parallelism scope

#### Spec commit sequencing (plan)
- fix: move spec git commit from Step 6b (before review) to Step 6d (after review loop) — previously, the committed version was stale if the spec-reviewer found issues
- fix: explicit `git add && git commit` instruction with guard: "Do NOT say committed unless git commit succeeded"

#### Visual Companion gate (plan)
- fix: add visual companion check to brainstorm gate — model must evaluate whether the topic involves visual questions before proceeding to context detection

#### Security transparency in spec review (plan)
- fix: security-related issues found by spec-reviewer must be presented to user before fixing — security decisions should be transparent, not silently resolved

#### Cross-reference and numbering fixes
- fix: `debug/SKILL.md` cross-reference corrected from `/ops:implement Step 2d` (Discovery Check) to `Step 4` (Final Review)
- fix: `implement/SKILL.md` Step 5 final validation marked MANDATORY with justification
- fix: `implement/SKILL.md` Step 5 duplicate numbering (two `3.`) corrected to sequential 1-2-3-4-5

## 2.0.0 (2026-03-20)

### Composable phases architecture

Extracted ~400 lines of duplicated content from 8 skills into 8 reusable internal phases. Skills now reference phases instead of inlining shared content.

#### New internal phases (`user-invocable: false`)
- `ops:instruction-priority` — instruction hierarchy (user > CLAUDE.md > ops skill > system prompt)
- `ops:subagent-rules` — context rules for dispatching subagents
- `ops:environment-setup` — language/framework detection + 4-level LSP diagnostic (test, marketplace, plugin, binary)
- `ops:code-quality` — format + lint modified files before code review
- `ops:discovery-checks` — Minor/Significant/Major discovery categorization
- `ops:circuit-breaker` — repeated failure diagnostic (researcher-code + git-historian)
- `ops:security-gate` — triage (14 triggers) + dispatch security-reviewer + re-verification loop (cap 3)
- `ops:redispatch-optimization` — generic re-dispatch prompt optimization pattern

#### New skills
- `/ops:research` — autonomous exploration: dispatches researcher-code + researcher-doc + git-historian in parallel
- `/ops:brainstorm` — interactive Socratic brainstorming extracted from /ops:plan Step 1
- `/ops:full` — meta-pipeline: chains /ops:plan → user approval → /ops:implement → /ops:ship
- `/ops:test` — add tests to existing untested code (dispatches test-writer agent)
- `/ops:refactor` — restructure code without changing behavior (coverage gate → incremental steps → verify)
- `/ops:perf` — performance investigation and optimization (baseline → profile → optimize → measure)
- `/ops:review-pr` — review external PRs (dispatches pr-reviewer agent + security-gate)

#### New agents
- `test-writer` — analyzes existing code and writes meaningful tests (behavior, not implementation)
- `pr-reviewer` — reviews external PRs with structured actionable comments

#### Refactored skills
- `/ops:plan` — removed inline instruction-priority, subagent-rules, environment-setup, lsp-setup, redispatch-optimization
- `/ops:implement` — removed inline instruction-priority, subagent-rules, discovery-checks, circuit-breaker, security-triage, security-redispatch, redispatch-optimization
- `/ops:do` — removed inline instruction-priority, subagent-rules, environment-setup, lsp-setup
- `/ops:debug` — removed inline instruction-priority, subagent-rules, discovery-checks, circuit-breaker
- `/ops:security` — removed inline instruction-priority, security-triage, security-redispatch
- `/ops:verify` — removed inline instruction-priority
- `/ops:review` — removed inline instruction-priority
- `/ops:ship` — removed inline instruction-priority

#### Harmonization
- Ansible detection added to `ops:environment-setup` (previously only in `/ops:plan` inline)
- Ansible LSP entry added to boostvolt marketplace table in `ops:environment-setup`
- Instruction-priority extracted into `ops:instruction-priority` phase and referenced from all 11 user-facing skills

#### Hook updated
- SessionStart routing table expanded: 15 entries (was 8) — added research, brainstorm, full, test, refactor, perf, review-pr

#### Stats
- Skills: 8 → 15 user-facing + 8 internal phases = 23 total
- Agents: 8 → 10 (+test-writer, +pr-reviewer)

## 1.6.1 (2026-03-20)

- feat: add Ansible LSP support (ansible-language-server via boostvolt/claude-code-lsps)
- feat: add Ansible-specific detection in Step 0a (ansible.cfg, galaxy.yml, roles/, playbooks/ markers)

## 1.6.0 (2026-03-19)

- feat: add `/ops:do` skill — lightweight structured workflow (research, execute, verify, review) for well-understood tasks

## 1.5.2 (2026-03-19)

- feat: optimize review agent re-dispatch prompts — re-dispatches now include previous findings + corrections instead of full context
- feat: standardize circuit breaker caps to 3 iterations — spec-reviewer stays at 3, critic 2→3, security-reviewer loops capped at 3
- feat: add re-dispatch loop for security-reviewer in implement and security skills (previously single conditional re-dispatch)

## 1.5.1 (2026-03-19)

- feat: add Terraform, Clojure, Dart, Elixir, Gleam, Nix, OCaml, Ruby, Zig LSP support (boostvolt/claude-code-lsps)
- feat: add Piebald-AI/claude-code-lsps as third marketplace (community) for HTML/CSS, Vue, Scala, PowerShell, Julia, LaTeX, Ada, Solidity
- fix: clarify HARD-GATE-0 wording — "do not ask design questions" instead of "do not talk to user"

## 1.5.0 (2026-03-18)

- feat: move language detection and LSP diagnostic to Step 0 (runs before brainstorming to catch restart-requiring issues early)

## 1.4.2 (2026-03-17)

- docs: fix install instructions — separate marketplace and local clone methods, remove incorrect commands

## 1.4.1 (2026-03-17)

### Fixes from session d6e7934d analysis
- fix: require risk profile (maintenance status, last release, community size) for dependencies validated conversationally during brainstorming, not just at the formal Step 5 gate
- fix: remove `--all` flag from git-historian search commands — prevents finding commits from unmerged branches, stashes, or orphaned refs that are not on the current branch lineage

## 1.4.0 (2026-03-16)

- docs: add tip about git cloning external sources for deeper understanding
- docs: add marketplace prerequisite to install instructions

## 1.3.0 (2026-03-16)

### Move code review and security review to final-only

Per-task code review and security review removed. Both now happen once at the end on the complete diff.

**Why**: Real-world cost analysis showed per-task reviews would cost ~$37 (15 code-reviewers + 10 security-reviewers) while adding no detection value — the final review catches the same bugs with better cross-task context. Two sessions confirmed: 5 bugs found in final review (session 659f), 0 bugs caught by per-task reviews that the final review missed (session 7ea1).

#### Per-task pipeline simplified
- Pipeline is now: `implementer → validation → conformity check → discovery check → task completion record`
- No code-reviewer or security-reviewer dispatched per task
- Conformity check (orchestrator-level, no agent dispatch) remains as the per-task quality gate
- Task completion record simplified: removed code review and security triage lines

#### Final review restructured
- Security triage now happens once on the complete diff with explicit output format
- Code-reviewer and security-reviewer dispatched in parallel on the full diff
- Pre-review audit simplified to count implementers vs tasks (no per-task review counts)

#### Cost impact
- Estimated review cost per session: ~$3-4 (1 final code review + 1 final security review) instead of ~$37 (15+10 per-task dispatches)

## 1.2.0 (2026-03-16)

### Orchestrator compliance enforcement — anti-skip mechanisms

Based on real-world session analysis where the orchestrator skipped code reviews (2/15 tasks reviewed), never dispatched the security-reviewer (despite network policies, access control, and identity federation), and bundled multiple tasks into single implementer agents.

#### External Dependency Validation gate (plan)
- New MANDATORY gate in Step 5: all agent-chosen dependencies must be presented to the user with alternatives before inclusion in the spec
- Distinguishes user-requested dependencies (already validated) from agent-chosen dependencies (must ask)
- Prevents the agent from silently choosing libraries, charts, tools, or services without user approval

#### Task Completion Record (implement)
- New Step 2f: mandatory structured output for every task with explicit security triage line
- Forces the orchestrator to write "Security triage: YES/NO" after evaluating the 14 triggers — no silent skipping
- Covers all pipeline steps: implementer status, validation command + exit code, conformity, code review, security triage, discovery

#### Pre-review Audit (implement)
- New mandatory audit before final review: counts implementers dispatched, code reviews completed, security reviews dispatched
- Detects discrepancies (bundled tasks, skipped reviews, missing security dispatches) and blocks final review until fixed

#### Anti-bundling post-hoc verification (implement)
- HARD-GATE now includes post-hoc count check: implementer agents dispatched must equal tasks in plan
- If fewer implementers were dispatched than tasks exist, the orchestrator must re-run the bundled tasks individually

## 1.1.1 (2026-03-16)

### Remove technology-specific examples
- Replaced all Kubernetes/infra-specific examples (Kustomize, Helm, ArgoCD, Cilium, ConfigMap, ServiceMonitor, cert-manager) with technology-agnostic equivalents across all skills and agents
- Examples now use generic patterns (Express, PostgreSQL, React, auth middleware, API routes) that apply to any stack
- Affected files: ship/SKILL.md, plan/SKILL.md, implement/SKILL.md, researcher-doc.md, spec-reviewer.md, COMPARISON-vs-SUPERPOWERS.md

## 1.1.0 (2026-03-16)

### New skill: `/ops:security`
- On-demand security review — invoke directly without going through `/ops:implement` or `/ops:debug`
- Supports multiple scopes: staged changes, specific files, directories, branch diff, specific commit
- Triages security domains before dispatching, skips review when nothing sensitive is found
- Optional fix-and-verify loop: apply fixes, re-dispatch security-reviewer to confirm

### Security reviewer rewritten — fully technology-agnostic
- Covers the full spectrum: application code, infrastructure as code, CI/CD pipelines, container/runtime, supply chain, policy enforcement
- 9 analysis categories (was 5): added CI/CD & Build Pipeline, Supply Chain & Dependencies, Policy Enforcement & Compliance, expanded Infrastructure & Runtime
- Broader trust boundaries: `build → deploy`, `human → machine` in addition to classic user/service boundaries
- Broader attacker profiles: CI/CD attacker, supply chain attacker, insider
- No technology names anywhere — principles over vendors
- Explicit constraint: "Technology-agnostic. Name the principle, not the vendor."

### Security escalation triggers expanded (implement, debug)
- 8 triggers → 14 triggers covering full DevSecOps spectrum
- Added: IaC, CI/CD pipelines, runtime privileges, dependency/supply chain, policy enforcement, data storage/retention, logging/audit/observability
- Removed technology-specific references (OIDC, OAuth2, Kyverno, OPA) — replaced with agnostic equivalents

### SessionStart hook updated
- Added `/ops:security` to skill routing table

## 1.0.1 (2026-03-16)

Enforcement fixes based on real-world session analysis. Addresses orchestrator compliance gaps where steps were skipped or shortcuts taken.

### Enforce per-task code review (`implement/SKILL.md`)
- Add HARD-GATE: every task must complete full pipeline (implementer → validation → conformity → code review) before next task starts
- One task = one implementer agent — no bundling multiple tasks into a single dispatch
- Parallelization rules: max 3 parallel tasks, each with its own complete pipeline
- Code review made MANDATORY with strict trivial-task exception (≤1 file, pure rename/comment/config, no logic)
- Conformity check (2c) made MANDATORY with explicit diff-vs-plan verification

### Enforce security-reviewer dispatch (`implement/SKILL.md`, `debug/SKILL.md`)
- Security escalation is now a gate, not a suggestion — "you have FAILED this skill" if skipped
- Added OIDC/SSO/OAuth2 and Kyverno/OPA to security-sensitive areas list
- Final review: security-reviewer mandatory when any task touched security areas
- "When in doubt, dispatch" — false positives are cheap, missed vulns are not

### Enforce critic and spec-reviewer re-dispatch (`plan/SKILL.md`)
- Critic re-dispatch after REJECT is now MANDATORY — "you have FAILED this skill" if skipped
- Spec-reviewer re-dispatch after fixes is now MANDATORY

### Enforce context detection and research adequacy (`plan/SKILL.md`)
- Context detection (Step 2) cannot be skipped — "Do NOT skip this step"
- LSP Level 1 test is now mandatory (takes seconds)
- Research adequacy check must present an explicit OK/GAP table to the user

### Enforce brainstorm discipline (`plan/SKILL.md`)
- "One question at a time" reinforced: ONE question per message, not 2-3 grouped
- Anti-pattern: "If you catch yourself writing Question 4:, Question 5: — STOP"
- Explicit user approval question added at Step 9

### Enforce TaskList verification (`implement/SKILL.md`)
- TaskList call at completion is now MANDATORY — must be called and shown

### Remove hardcoded model references (all SKILL.md files)
- Removed all `(Sonnet)` and `(Opus)` model annotations from skill files
- Model is defined in agent frontmatter, not in the skill — avoids inconsistency

### Agents upgraded to Opus
- **spec-reviewer** — Sonnet → Opus
- **implementer** — Sonnet → Opus
- **code-reviewer** — Sonnet → Opus
- **security-reviewer** — Sonnet → Opus

### Align debug/SKILL.md
- Same security escalation enforcement as implement
- Same trivial-task exception for code review
- Removed model references

## 1.0.0 (2026-03-15)

Initial public release.

### Skills
- `/ops:plan` — Brainstorm, parallel research (3 agents), spec writing, adversarial critic review, user approval
- `/ops:implement` — Task-by-task execution with validation gates, conformity checks, code review, security escalation, circuit breakers, TaskCreate/TaskUpdate tracking
- `/ops:debug` — Systematic root-cause investigation with hypothesis testing and circuit breaker
- `/ops:review` — Evaluate code review feedback technically before acting
- `/ops:ship` — Validate, commit, optional PR, capture learnings, propose `.claude/rules/` from recurring lessons
- `/ops:verify` — Behavioral skill (always active): evidence before claims

### Agents
- **critic** (Opus) — Adversarial plan review with 5 lenses (incl. architectural alternatives), 4 perspectives (incl. Architect), self-audit
- **researcher-code** (Opus) — Codebase patterns, conventions, architecture mapping, risk flagging
- **researcher-doc** (Sonnet) — External docs via Context7 MCP with version validation and source priority
- **git-historian** (Sonnet) — Commit timeline, regressions, ownership, hotspots
- **spec-reviewer** (Opus) — Spec completeness validation (7 dimensions)
- **implementer** (Opus) — Task execution with TDD (Red/Green/Refactor), deletion rule, anti-rationalization
- **code-reviewer** (Opus) — LSP diagnostics, spec compliance, code quality, security scan, TDD adherence
- **security-reviewer** (Opus) — Threat analysis, attack scenarios, evidence-based findings

### TDD
- Full TDD reference with code examples, deep arguments, and troubleshooting
- Testing anti-patterns guide (mock behavior, test-only methods, incomplete mocks)

### Hooks
- SessionStart hook injects skill routing context

### Visual
- Browser-based brainstorm companion with WebSocket server (from superpowers, MIT)
