# Step 11 — Critic Review (invariant-class safety check)

Mark the task "Brainstorm: critic review" as `in_progress` now via `TaskUpdate`. (If this task does not exist in the checklist created in Step 1, add it via `TaskUpdate` before starting.)

This step dispatches the **critic** agent in **Brainstorm review mode** to review the locked architectural decisions BEFORE the transition to `/ops-plan` (or `/ops-do`). It is the only allowed agent dispatch in `/ops-brainstorm` — see the SKILL.md global constraints for the carved-out exception.

## Why this step exists

The plan-stage critic (`skills/plan/step-08-critic-review.md`) runs **after** the plan is written. By that point the architectural decisions from the brainstorm summary are already propagated into a task breakdown, and the user has mentally committed. The plan critic's Lens 5 catches decisions **invented post-brainstorm**, but it does NOT challenge decisions that were locked **during** brainstorm — because those are presumed validated by the user's explicit choice.

This step closes that gap: it asks the critic to verify that the **locked decisions themselves** are not silently shipping a known invariant-class antipattern (decentralized authz, fail-open safety check, fragile metadata-as-authority, etc.) before the plan locks them in.

The brainstorm critic does NOT replace the plan critic. They run on different inputs (summary vs. plan) and check different things (locked-decision sanity vs. plan-vs-summary trace). Both must run for full coverage.

## Mode gate

Read the complexity mode chosen in Step 3 and the Brainstorm Summary block produced in Step 10. Scan the `### Architectural decisions` block for these **invariant-class signals** (deterministic text match — no LLM judgement needed):

- **Signal D2** — Dimension 2 (Source of authority) answer starts with `B` or `C` (decentralized / hybrid authority).
- **Signal D4** — Dimension 4 (Failure mode) answer starts with `B` or `C` (fail-open / retry-with-fail-open fallback).
- **Signal D1** — Dimension 1 (State / data location) answer contains BOTH keyword classes **within the Dimension 1 answer itself** (NOT inferred from Objective, Chosen approach, or any other section of the summary — Lens 5-B is not a semantic search across the summary):
  - fragile-channel keyword from: *cache, best-effort, metadata, fire-and-forget, queue, eventually-consistent, ephemeral, in-memory-only*; AND
  - correctness-critical keyword from: *authority, permission, identity, ownership, token, grant, authz decision, access binding*.

  This list is the single source of truth — it MUST match `agents/critic.md` Lens 5-B Dimension 1 rule character-for-character. If one list drifts, the gate fires on signals the critic refuses to flag, producing wasted dispatches — the exact failure mode signal-gating was built to prevent.

An **invariant-class signal** is any of D1/D2/D4 matching. These signals are computable by reading the summary — the format is guaranteed parseable by Step 10's end-of-step checklist (Dimensions 2/3/4 listed with the user's exact A/B/C prefix).

### Per-mode behavior

- **Simple mode** — SKIP by default. RUN (escalate) if:
  - any invariant-class signal (D1/D2/D4) matches, **OR**
  - the Objective line mentions any of: *authorization, permission, access, ownership, validation, payment, safety, trust, "who can"*.

  When escalating in Simple mode, prepend the dispatch prompt with: *"NOTE: Simple mode escalation — feature was classified Simple but contains an invariant-class signal. Brainstorm critic runs anyway."*

  Rationale: misclassifying an authz/safety feature as Simple is the exact failure mode this critic is supposed to catch — Simple mode does not get to opt out of invariant-class verification.

- **Normal mode** — SKIP by default. RUN (escalate) if any invariant-class signal (D1/D2/D4) matches.

  When escalating in Normal mode, prepend the dispatch prompt with: *"NOTE: Normal mode escalation — invariant-class signal detected in locked decisions."*

  Rationale: on a brainstorm where all invariant-class dimensions are at the safe default (A) or N/A, the critic verdict is a guaranteed APPROVE — paying one dispatch for a no-op. Normal mode is the dominant path, so signal-gating here reduces baseline cost without weakening the safety property. The unsafe B/C choices are exactly where the critic adds value.

- **Complex mode** — RUN unconditionally. Complex features have more dimensions, more interactions, and more room for subtle errors — the critic overhead is justified regardless of which answers the user locked.

If you SKIP, mark the task as `completed` with a note stating the mode and the reason: `"skipped — Simple mode, no invariant-class signal"` or `"skipped — Normal mode, all invariant-class dimensions at safe default (A) or N/A"`. Then hand off to Step 12. Do NOT mark it `cancelled`.

## Required dispatch context

The critic dispatch prompt MUST include ALL of the following:

1. **Mode marker**: the literal line `REVIEW MODE: BRAINSTORM` as the first line of the prompt body. This tells the critic to use the Brainstorm review mode defined in `agents/critic.md` (skipped Phase 1, reduced Phase 2 to invariant-class lens only, no plan tasks to review).
2. **The Brainstorm Summary block** — copy verbatim the `## Brainstorm Summary` markdown block from Step 10. Do NOT paraphrase, do NOT summarize. The critic needs the exact wording of each Dimension answer to apply the invariant-class exception correctly.
3. **The complexity mode** chosen in Step 3 (Simple/Normal/Complex), including any Simple-mode escalation note.
4. **The project instruction file path** (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) if one exists at the project root. The critic loads it in Phase 0.
5. **The reference to the invariant-class exception**: the literal path `skills/brainstorm/step-07-architectural-decisions.md` so the critic can read the canonical wording of HARD-GATE-NEUTRALITY's exception block.

If you dispatch the critic without ALL of these, the brainstorm critic cannot run correctly — you have FAILED this step.

## What the critic does in BRAINSTORM mode

See `agents/critic.md` → "Brainstorm review mode" for the canonical definition. Summary:

- **Phase 0**: load project instruction file (same as plan mode).
- **Phase 1 (pre-engagement)**: predict 3 ways the locked decisions could ship a class-of-bug (authz drift, fail-open on safety, fragile state propagation, single-actor assumption in a multi-actor system). This is the anti-confirmation-bias step — it runs BEFORE the critic reads the summary in detail.
- **Phase 2 (focused lens)**: only the **invariant-class check** + the **single-source-of-truth check** + the **authority-placement check** apply. Lenses 1, 2 (no plan tasks), 3 (no implementation to review), 4 (no plan to compare) do NOT apply.
- **Phase 3-5**: skipped (no multi-perspective review, no gap analysis on tasks that don't exist yet, no escalation to adversarial mode — that is reserved for plan review).
- **Phase 6 (verdict)**: APPROVE / SUGGESTIONS / REJECT.

## Verdict handling

The critic returns one of three verdicts. Branch on the verdict:

### Branch A — APPROVE

The locked decisions pass the invariant-class check. Append the following line to the Brainstorm Summary block (under "Other key decisions"):

```
- **Brainstorm critic verdict**: APPROVE (invariant-class check passed)
```

This line is consumed by the plan-stage critic (`/ops-plan` Step 8) as evidence that the locked decisions were already reviewed — it does NOT cause the plan critic to skip its own work, but it lets the plan critic focus its Lens 5 on plan-vs-summary trace rather than re-litigating dimensions.

Mark the task as `completed`. Hand off to Step 12.

### Branch B — SUGGESTIONS

The critic flagged something but did not REJECT. Present each suggestion to the user as a single message (one suggestion per message — do NOT batch). For each suggestion, ask the user one of:

- **Accept the suggestion** → revise the relevant dimension. If the revised dimension affects Step 7, Step 8, Step 9, or Step 10 outputs, you MUST loop back to the earliest affected step and re-execute it. Do NOT silently patch the summary block.
- **Decline with a reason** → record the reason in the Brainstorm Summary "Other key decisions" block as `- **Brainstorm critic suggestion declined**: [suggestion] — [reason]`.

After all suggestions are resolved, append:

```
- **Brainstorm critic verdict**: SUGGESTIONS resolved (N accepted, M declined with reason)
```

Mark the task as `completed`. Hand off to Step 12.

### Branch C — REJECT

The critic found a load-bearing invariant-class violation. Present the finding to the user as an A/B/C forced choice (one message, one question, no batching):

> **Critic rejected the locked decisions.**
>
> Finding: [verbatim finding from critic]
>
> What do you want to do?
>
> - **A) Revise** — re-open the affected dimension in Step 7. We will re-execute Steps 7, 8, 10, and re-run this critic.
> - **B) Override with explicit reason** — keep the current decision, document why the invariant-class exception does NOT apply (e.g., "this is intentionally advisory, not load-bearing", "this is offline-first by design", "this is a single-actor context"). The override + reason will be recorded in the Brainstorm Summary and forwarded to the plan critic.
> - **C) Abort brainstorm** — close `/ops-brainstorm` without transitioning. The user will start over or take a different approach.

Wait for the user's choice.

- **If A**: read `skills/brainstorm/step-07-architectural-decisions.md` again, re-execute it for the affected dimension only, then re-execute Step 8 (only the affected design section), Step 10 (regenerate summary), and re-enter this step (Step 11). Maximum 3 iterations of this loop. If still REJECT after 3 rounds, escalate to user with both critic findings and offer Branch C explicitly.
- **If B**: append to the Brainstorm Summary "Other key decisions" block:
  ```
  - **Brainstorm critic verdict**: REJECT — OVERRIDDEN by user
  - **Override reason**: [user's exact reason]
  ```
  Mark the task as `completed`. Hand off to Step 12. The plan critic will see the override marker and apply extra scrutiny in its own Lens 5.
- **If C**: mark the task as `cancelled`. Do NOT hand off to Step 12. Tell the user the brainstorm is closed and ask what they want to do next.

## Anti-loop guard

Maximum 3 iterations of the Branch A revise-and-re-critic loop. If the critic still REJECTs after 3 rounds, present BOTH the latest critic findings AND the previous override option (Branch B) to the user, and let them decide. Do NOT enter a 4th iteration silently.

---

## ✅ End of Step 11

Before proceeding, verify ONE of the following branch checklists:

### If skipped (Simple mode, no invariant-class signal)

- [ ] You verified Simple mode in Step 3.
- [ ] You verified the Brainstorm Summary contains NO Dimension 2 answer starting with `B` or `C`.
- [ ] You verified the Brainstorm Summary contains NO Dimension 4 answer starting with `B` or `C`.
- [ ] You verified Dimension 1 does NOT contain the fragile-authority keyword pairing (no fragile-channel keyword + correctness-critical keyword co-occurring inside the Dimension 1 answer itself — see Mode gate Signal D1 above for the canonical keyword lists).
- [ ] You verified the Objective line contains NO authz/safety keyword from: *authorization, permission, access, ownership, validation, payment, safety, trust, "who can"*.
- [ ] You marked the task `completed` with the note "skipped — Simple mode, no invariant-class signal".

### If skipped (Normal mode, no invariant-class signal)

- [ ] You verified Normal mode in Step 3.
- [ ] You verified the Brainstorm Summary contains NO Dimension 2 answer starting with `B` or `C`.
- [ ] You verified the Brainstorm Summary contains NO Dimension 4 answer starting with `B` or `C`.
- [ ] You verified Dimension 1 does NOT contain the fragile-authority keyword pairing (same canonical rule as Simple mode — Signal D1 above).
- [ ] You marked the task `completed` with the note "skipped — Normal mode, all invariant-class dimensions at safe default (A) or N/A".

### If APPROVE (Branch A)

- [ ] You dispatched the critic with ALL 5 required context items, including `REVIEW MODE: BRAINSTORM` as the first line.
- [ ] The critic returned APPROVE.
- [ ] You appended the verdict line to the Brainstorm Summary "Other key decisions" block.
- [ ] You marked the task `completed`.

### If SUGGESTIONS (Branch B)

- [ ] You presented each suggestion to the user one at a time (no batching).
- [ ] For each suggestion: either re-executed the affected step(s) on accept, or recorded the decline reason.
- [ ] You appended the SUGGESTIONS-resolved verdict line to the Brainstorm Summary.
- [ ] You marked the task `completed`.

### If REJECT (Branch C)

- [ ] You presented the A/B/C forced choice as a single message.
- [ ] You executed the user's choice exactly (revise & re-critic with iteration cap, or override with documented reason, or abort).
- [ ] If overridden: you recorded BOTH the verdict line AND the override reason in the Brainstorm Summary.
- [ ] If aborted: you marked the task `cancelled` and did NOT hand off to Step 12.
- [ ] If iteration cap reached: you escalated to the user with both findings.

Do NOT mark the milestone task completed yet — Step 12 remains (unless aborted).

**→ Next: read `skills/brainstorm/step-12-transition.md` now and execute Step 12** (unless the user chose Branch C — abort, in which case the skill ends here).

Do NOT continue without reading that file first.
