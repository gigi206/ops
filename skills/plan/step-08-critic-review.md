# Step 8 — Critic Review

Mark the task "Plan: critic review" as `in_progress` now via `TaskUpdate`.

Spawn the **critic** agent to review the plan.

## Required dispatch context

The critic dispatch prompt MUST include ALL of the following:

1. **The plan file path** (e.g. `docs/plans/YYYY-MM-DD-<topic>.md`) — the plan now contains both the design and the task breakdown in a single document.
2. **The brainstorm summary block** — copy verbatim the "Brainstorm Summary" markdown block from the conversation context (the one produced at the end of `/ops-brainstorm` Step 10, OR the recap you produced in this skill's Step 1 if brainstorm was already done). This is REQUIRED for the critic's Lens 5 brainstorm trace check (was each architectural decision in the plan validated in brainstorm, or invented post-brainstorm?).
3. **The project instruction file path** (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) if one exists at the project root
4. **The brainstorm critic verdict line** (if brainstorm ran its Step 11). Read the plan header written in Step 7 — if it contains a `**Brainstorm critic verdict**: …` line, copy it verbatim into the dispatch prompt with this framing: *"The brainstorm stage already ran its own critic on the locked architectural decisions (Lens 5-B invariant-class check). Verdict: `<line>`. This does NOT cause you to skip Lens 5 — the plan-stage Lens 5 still runs the brainstorm trace check (plan-vs-summary). Use the verdict as evidence that the dimensions themselves were reviewed: focus your Lens 5 on plan-vs-summary trace rather than re-litigating the dimensions."* If the line says `REJECT — OVERRIDDEN by user`, ALSO include the override reason line and instruct the critic to apply **extra scrutiny** in Lens 5 to any task derived from the overridden dimension. If the line says `skipped — no invariant-class signal`, include it verbatim and note to the critic that the brainstorm-stage review was deterministically skipped because the locked dimensions were all at the safe default. If the plan header has no such line (no brainstorm was run at all), omit this context item — do not fabricate one.

If you dispatch the critic without the brainstorm summary, the Lens 5 brainstorm trace check cannot run — and architectural decisions silently invented during research will not be flagged. This is the exact failure mode that Lens 5 was designed to catch. Do NOT dispatch the critic without the brainstorm summary attached.

Degraded case: if the user invoked `/ops-plan` directly without prior brainstorm AND without enough conversation context to reconstruct a brainstorm summary, state in the dispatch prompt: "No brainstorm summary available — the critic should explicitly note in Lens 5 that the brainstorm trace check cannot be performed and treat any architectural decision in the plan with extra scrutiny."

## What the critic does

The critic:
1. **Pre-engagement**: Predicts 3 potential problems BEFORE reading the plan details (prevents confirmation bias)
2. **Reviews against 5 lenses**: Missing steps, Contradictions, Security vulnerabilities, project instruction compliance, **architectural alternatives** (Lens 5)
3. **Multi-perspective review**: Executor, Stakeholder, Skeptic, Architect viewpoints
4. **Gap analysis**: What's missing that nobody asked about?
5. **Self-Audit + Realist Check**: Low-confidence findings become Open Questions, severity ratings are pressure-tested
6. **Escalation**: If CRITICAL found or 3+ IMPORTANT → adversarial mode (expand scope, challenge every decision)
7. **Verdict**: APPROVE or REJECT with confidence levels and perspective attribution

## If REJECT

Revise the plan addressing the critic's concerns, then **re-dispatch the critic** following the `ops-redispatch-optimization` process. This re-dispatch is MANDATORY. Maximum 3 iterations. If still rejected after 3 rounds, present both the plan and the critic's concerns to the user for decision.

If you fix the critic's concerns but do not re-dispatch the critic, you have FAILED this skill. The whole point of the critic is adversarial validation — bypassing the re-check defeats the purpose.

After fixing critic concerns, you MUST output this block BEFORE proceeding:

```
## Critic Re-verification
- Critic verdict: REJECT
- Issues addressed: [list each issue and how it was fixed]
- Re-dispatch: YES — dispatching now
- Iteration: N/3
```

If this block does not appear in your output followed by an actual critic agent dispatch, you have FAILED this skill.

## If APPROVE

Proceed to the End block below and follow Branch A.

---

## ✅ End of Step 8

Before proceeding, verify:
- [ ] You dispatched the critic with ALL required context: plan path, brainstorm summary (verbatim), project instruction file path, and — if the plan header contained a `**Brainstorm critic verdict**: …` line — that line verbatim plus the "does NOT cause you to skip Lens 5" framing.
- [ ] The critic returned a verdict (APPROVE or REJECT).

Then choose your branch based on the verdict:

---

### Branch A — If APPROVE

- [ ] Critic verdict is APPROVE.
- [ ] No CRITICAL findings remain.

Mark the task "Plan: critic review" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-09-user-approval.md` now and execute Step 9.**

Do NOT continue without reading that file first.

---

### Branch B — If REJECT (max 3 iterations)

- [ ] You output the `## Critic Re-verification` block with all 4 fields filled (verdict, issues addressed, re-dispatch, iteration N/3).
- [ ] You re-dispatched the critic via the `ops-redispatch-optimization` process.
- [ ] If after 3 iterations the verdict is still REJECT: present both plan and concerns to the user for decision.

Do NOT mark this task completed yet. Stay in this step — re-evaluate this End block after the re-dispatch finishes. When verdict becomes APPROVE (or iteration 3 forces user escalation), follow Branch A.
