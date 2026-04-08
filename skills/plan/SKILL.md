---
name: ops-plan
description: "Use when a task needs design, research, or decomposition before coding."
---

# /ops-plan — Clarify intent, research, and plan

<HARD-GATE-0>
STOP. Your VERY FIRST action must be Step 0: Discover project test/build commands. Do NOT ask design questions yet.
</HARD-GATE-0>

<HARD-GATE-1>
After Step 0 is complete, your NEXT message must be a clarity check with the user. NOT a research result. NOT a plan. NOT an agent dispatch.

If your first action after Step 0 is spawning ANY agent (Agent tool) — regardless of type (Explore, researcher-code, researcher-doc, general-purpose, or any other) — you have FAILED this skill. Step 1 is a conversation with the user, not a delegation.

The steps are: 0. Discover commands → 1. Clarify intent WITH the user → 2. Context → 3. Research → ... You cannot skip steps 0 or 1.
</HARD-GATE-1>

## When to use which skill

| Situation                          | Skill            | Why                                       |
|------------------------------------|------------------|-------------------------------------------|
| New feature, change, or task       | `/ops-plan`      | Design before coding                      |
| Plan approved, ready to build      | `/ops-implement` | Execute with validation gates             |
| Bug, error, or unexpected behavior | `/ops-debug`     | Investigate before fixing                 |
| Work is done, ready to commit      | `/ops-ship`      | Commit, PR, capture learnings             |
| Claiming something works           | `/ops-verify`    | Evidence before claims (always active)    |
| Received code review feedback      | `/ops-review`    | Evaluate technically, don't agree blindly |
| Small task, already understood     | `/ops-do`        | Research + execute + verify + review      |
| Trivial fix (typo, rename)         | No skill needed  | Just do it                                |

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Overview

This skill runs before any implementation. It clarifies the user's intent, gathers intelligence via parallel research agents, writes a detailed plan decomposed into tasks, and validates it through an adversarial critic.

## Workflow

```
0. Discover Commands → 1. Clarify Intent → 2. Context Detection → 3. Parallel Research → 4. Research Adequacy Check → 5. Design Approaches → 6. Write & Review Spec → 7. Write Plan → 8. Critic Review → 9. User Approval
```

---

## Step 0: Discover Project Commands (MANDATORY — runs FIRST)

Discover the project's actual test/build/lint commands by checking: `Makefile` targets, `bin/` scripts, `package.json` scripts, `docker-compose` services, `tox.ini`, `noxfile.py`, or similar. Use these discovered commands — not generic ones (`python -m pytest`, `npm test`) — in task validation commands throughout the plan.

You MUST output this block before proceeding to Step 1:

```
## Discovered Commands
- Test: `<command>` (source: Makefile / package.json / tox.ini / ...)
- Build: `<command>`
- Lint: `<command>`
- Not found: [list what was checked but not found]
```

If this block does not appear in your output before Step 1, you have skipped a required step.

### Environment Health Check

If during command discovery you notice signs of a misconfigured environment (e.g., no `node_modules` but `package.json` exists, broken `Makefile`, missing `.venv`), propose to the user:

> "Your environment may not be fully set up. Want to run `/ops-init` first to diagnose LSP, tools, and dependencies? Or should we continue as-is?"

Wait for the user's decision before proceeding to Step 1. If they want to run init, let them invoke `/ops-init` and resume planning afterward.

---

## Step 1: Clarify Intent (MANDATORY — cannot be skipped)

### If `/ops-brainstorm` was already run

If the user ran `/ops-brainstorm` before invoking `/ops-plan`, the brainstorming is already done. In this case:
1. Read the brainstorm summary from the conversation
2. Output a short recap: chosen approach, scope, key decisions
3. Skip to Step 2 (Context Detection)

The user already validated the approach.

### The Process

**Clarity check:**
Verify you can restate what is asked, why, and what success looks like. If you can't answer all 3 confidently, ask the user to clarify.

> Example: "Before I dive in — I want to make sure I understand. You want [restatement]. The goal is [why]. Is that right, or am I missing something?"

**Scope check:**
- If the request describes multiple independent subsystems, flag this and help the user decompose into sub-projects.
- Each sub-project gets its own spec → plan → implementation cycle.

**Offer deeper brainstorming:**
If the problem space is ambiguous, has multiple viable approaches, or would benefit from deeper exploration, suggest the user invoke `/ops-brainstorm` before continuing. Do NOT run a full brainstorming process yourself — that is the role of `/ops-brainstorm`.

> Example: "This has several possible approaches and some open questions. Want me to run `/ops-brainstorm` first to explore the options in depth, or is the direction clear enough to plan directly?"

### Gate

**Do NOT proceed to context detection until:**
- The objective is clear and confirmed by the user.
- The scope is agreed (single project or decomposed into sub-projects).

You MUST output this block before proceeding to Step 2:

```
## Intent Confirmed
- Objective: [one sentence]
- Scope: [one sentence]
- Brainstorm: not needed / already done / suggested to user
```

If this block does not appear in your output before Step 2, you have skipped a required step.

---

## Step 2: Context Detection

**Do NOT skip this step.** It takes seconds and informs every agent downstream. If you jump straight to Step 3 (Research) without doing context detection, you have skipped a required step.

### Explore project structure

Read the project instruction file (`CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` — whichever exists at the project root), directory structure, and key config files to understand conventions. If none exists, infer conventions from the codebase.

---

## Step 3: Parallel Research

<HARD-GATE-RESEARCH>
You MUST dispatch exactly 3 agents in a SINGLE message, using the exact subagent types specified below. Do NOT substitute with `Explore` or `general-purpose` agents. Do NOT dispatch only 1 or 2 agents. If you dispatch anything other than these 3 typed agents, you have FAILED this skill.

The 3 agents MUST be:
1. `subagent_type: "ops-researcher-code"` — codebase patterns, conventions, risks
2. `subagent_type: "ops-researcher-doc"` — library/tool documentation via Context7 MCP
3. `subagent_type: "ops-git-historian"` — git history analysis (Research Mode, 6 months)

All 3 dispatched in a single assistant message. No exceptions.

Degraded case: if an agent fails or times out, record "Agent <type> failed: <reason>" in the research synthesis and proceed. The gate requires dispatching all 3, not that all 3 succeed.
</HARD-GATE-RESEARCH>

Run the `ops-research` process (Steps 2-6: dispatch 3 agents in parallel — researcher-code, researcher-doc, git-historian — synthesize findings, and conditionally dispatch one or more researcher-repo agents in parallel for targets where researcher-doc signals `Source Verification Needed: high`). Scope the research to the task area identified during intent clarification.

---

## Step 4: Research Adequacy Check

Before designing approaches, verify the research produced concrete evidence — not just "we understand".

**You MUST present this table to the user** with the evidence filled in:

| Dimension             | Status   | Evidence                                                       |
|-----------------------|----------|----------------------------------------------------------------|
| **Technical context** | OK / GAP | [Cite `file:line` of similar code or list files read]          |
| **Dependencies**      | OK / GAP | [List of files affected from researcher-code]                  |
| **Risks**             | OK / GAP | [Concrete risks found, or "none found after checking X, Y, Z"] |
| **Documentation**     | OK / GAP | [Sources with versions, e.g., "Context7: express v4.18.2"]     |

This table is not a mental checklist — it must appear in your output so the user can verify the research was adequate.

**If 3-4 dimensions are OK**: Proceed to Step 5.

**If 1-2 dimensions show GAP**:
- Identify the specific gap (e.g., "no similar implementation found — we don't know the pattern to follow")
- Spawn a targeted follow-up agent to fill the gap (researcher-doc or researcher-code, whichever is relevant)
- Do NOT proceed with a half-understood problem

**If 0 dimensions have evidence**: The task is probably too vague. Go back to Step 1 and clarify with the user.

---

## Step 5: Design Approaches

Based on research results, propose **2-3 approaches** to the user.

### For each approach:
- **Name**: Short label (e.g., "Approach A: extend existing module" / "Approach B: new standalone component")
- **How it works**: 2-3 sentences
- **Pros**: Why this approach is good
- **Cons**: What are the tradeoffs
- **Fits conventions**: Does it match existing patterns found by researcher-code?
- **Reuse**: Does existing code already solve part of this? Could we extend it instead of building from scratch?

### Presentation rules:
- **Lead with your recommendation** — present the recommended option first, explain why it's best, then present alternatives
- **Be conversational** — adapt the format to the context. A simple choice can be 3 sentences per option. A complex architectural decision needs more depth.
- **Use the visual companion** if active — for choices with visual implications (layouts, architectures, data flows), show side-by-side comparisons in the browser instead of describing them in text
- **Always present at least one alternative** — even if one approach is clearly superior. The user needs to make an informed decision, not rubber-stamp yours.

### External Dependency Validation (MANDATORY)

Before proceeding to spec writing, identify ALL external dependencies that emerged during the design — components, libraries, tools, charts, images, or services that the project does not already use.

**Distinguish between:**
- **User-requested dependencies** — the user explicitly asked for this ("add rate limiting with Redis") → already validated
- **Agent-chosen dependencies** — you selected this to fulfill the request ("use library X for the UI") → NOT validated, MUST ask

For each agent-chosen dependency, present to the user:

> "To implement [feature], I'd use **[dependency name]** ([source/maintainer]).
> - **Why**: [what it provides]
> - **Alternatives**: [at least 1 alternative + "build it ourselves" if feasible]
> - **Risk**: [maintenance status, maturity, last release]
> Which option do you prefer?"

### Gate

Do not proceed to spec writing until the user has chosen an approach and validated all external dependencies. If you chose a dependency, the user must approve it — "Implement X" does not mean the user validated every sub-component.

If a dependency was already validated conversationally during intent clarification or brainstorming, you do not need to re-ask — but you must still present its risk profile (maintenance status, last release, community size) if not covered during the conversation.

If the spec contains an agent-chosen dependency that was never presented to the user, you have FAILED this skill.

---

## Step 6: Write & Review Spec

After the user has chosen an approach, flesh it out into a full design and persist it.

### 6a. Present the design by sections

Present the design **section by section** — not as a single wall of text. Each section should be validated by the user before moving to the next.

- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Cover across sections: architecture, components, data flow, error handling, testing strategy
- **Ask after each section**: "Does this look right so far?" — wait for the user to validate
- If the user requests changes to a section, revise it and re-present before moving on
- The spec-reviewer (Step 6c) will validate the full spec — but section-by-section validation catches misunderstandings early

**Design for isolation and clarity:**
- Break the system into smaller units that each have one clear purpose
- Communicate through well-defined interfaces
- Can someone understand what a unit does without reading its internals?
- Smaller, well-bounded units are easier to implement, test, and review

### 6b. Write spec document

Write the spec to `docs/specs/YYYY-MM-DD-<topic>-design.md`. Do NOT commit — the user decides when to commit.

The spec captures the **what** and **why** — the plan (Step 7) captures the **how** (task breakdown).

Set `**Status**: Draft` in the spec header.

User preferences for spec location override the default path.

### 6c. Spec review loop

Dispatch the **spec-reviewer** agent to verify the spec is complete and ready for planning.

1. If **Issues Found**:
   - If the reviewer found **security-related issues** (permissions too broad, missing access checks, data exposure), present them to the user and wait for direction before fixing — security decisions should be transparent, not silently resolved.
   - Fix the issues (for security issues, follow the user's direction).
   - **Re-dispatch the spec-reviewer** following the `ops-redispatch-optimization` process. This re-dispatch is MANDATORY — the reviewer must confirm the fixes are adequate.
2. Repeat until **Approved** (max 3 iterations).
3. If still not approved after 3 iterations, surface the remaining issues to the user for guidance.

### 6d. Present to user

After the spec review loop passes, ask the user to review:

> "Spec written to `<path>`. Please review it and let me know if you want to make any changes before we start writing the implementation plan."

Do NOT commit the spec. The user decides when to commit (via `/ops-ship` or manually).

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

Once the user approves, update the spec status to `**Status**: Approved`.

---

## Step 7: Write Plan

Based on the chosen approach and research results, write a detailed plan with:

1. **Summary**: What we're doing and why (2-3 sentences)
2. **Research findings**: Key insights from the research agents (including researcher-repo if dispatched)
3. **Approach**: The chosen approach and why
4. **Task breakdown**: See task decomposition rules below
5. **Risks**: What could go wrong

### Task Decomposition (MANDATORY)

The plan MUST be decomposed into discrete, ordered tasks. A plan without tasks is NOT a plan — it's a wish.

Each task MUST have ALL of:
- [ ] **Description**: One clear action (not "set up everything")
- **Files**: Exact paths to create or modify
- **Change**: What specifically changes in each file
- **Validation**: The command to verify this task is done

**Rules**:
- **Sizing guide**: Code-level changes: 2-5 minutes. Setup/integration tasks (test framework, CI config, complex resources): up to 30 minutes. No fixed upper limit for complex features — size by coherence, not by clock.
- Each task MUST be independently verifiable via its validation command.
- Tasks MUST be ordered by dependency (prerequisites before dependents, config before consumers, schemas before data).
- A task that touches more than 3 files is probably too big. Consider splitting it.
- **TDD granularity**: When the project has a test framework, each task should follow the TDD micro-cycle: write failing test → run to verify failure → implement minimal code → run to verify pass → commit. The plan should make this explicit in each task's steps when applicable.

### No Placeholders (MANDATORY)

Every task must contain the actual content an implementer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without specifying what to test)
- "Similar to Task N" (repeat the details — the implementer may read tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps when the approach is non-obvious)
- References to types, functions, or methods not defined in any task

If you find yourself writing any of these, stop and fill in the actual content. A plan with placeholders is not a plan — it's a sketch.

### Project Instruction-Driven Tasks (when project instructions exist)

Read the project instruction files (`CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` — whichever exist at the project root) and their subdirectory variants. If none exists, skip this section — there are no project-specific rules to generate tasks from.

If project instructions exist, scan the rules for any action that is required for the type of change being made. If a rule applies, **generate an explicit task for it in the plan**.

Project instruction rules are not just conventions to follow — they are **task generators**. Any rule that says "when doing X, also do Y" means Y must be a task in the plan, not a mental note.

How to apply:
1. Read all project instruction rules
2. For each rule, ask: "does this apply to the current change?"
3. If yes, add a dedicated task with files, change description, and validation command
4. If unsure whether a rule applies, include it — the critic or the user can remove it

**Do NOT treat project instruction rules as "nice to have".** If a rule applies to this change, it MUST have a corresponding task in the plan.

**Gate**: Do NOT proceed to critic review if the plan has no task breakdown or if any task is missing files/change/validation. If project instructions exist and applicable rules have no corresponding tasks, do not proceed either.

**Present the plan in sections** short enough to read and digest — not a wall of text. Let the user absorb each section before the next.

---

## Step 8: Critic Review

Spawn the **critic** agent to review the plan.

### Required dispatch context

The critic dispatch prompt MUST include ALL of the following:

1. **The plan file path** (e.g. `docs/specs/YYYY-MM-DD-<topic>-plan.md`)
2. **The companion spec file path** (e.g. `docs/specs/YYYY-MM-DD-<topic>-design.md`)
3. **The brainstorm summary block** — copy verbatim the "Brainstorm Summary" markdown block from the conversation context (the one produced at the end of `/ops-brainstorm` Step 10, OR the recap you produced in this skill's Step 1 if brainstorm was already done). This is REQUIRED for the critic's Lens 5 brainstorm trace check (was each architectural decision in the plan validated in brainstorm, or invented post-brainstorm?).
4. **The project instruction file path** (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) if one exists at the project root

If you dispatch the critic without the brainstorm summary, the Lens 5 brainstorm trace check cannot run — and architectural decisions silently invented during research will not be flagged. This is the exact failure mode that Lens 5 was designed to catch. Do NOT dispatch the critic without the brainstorm summary attached.

Degraded case: if the user invoked `/ops-plan` directly without prior brainstorm AND without enough conversation context to reconstruct a brainstorm summary, state in the dispatch prompt: "No brainstorm summary available — the critic should explicitly note in Lens 5 that the brainstorm trace check cannot be performed and treat any architectural decision in the plan with extra scrutiny."

### What the critic does

The critic:
1. **Pre-engagement**: Predicts 3 potential problems BEFORE reading the plan details (prevents confirmation bias)
2. **Reviews against 5 lenses**: Missing steps, Contradictions, Security vulnerabilities, project instruction compliance, **architectural alternatives** (Lens 5)
3. **Multi-perspective review**: Executor, Stakeholder, Skeptic, Architect viewpoints
4. **Gap analysis**: What's missing that nobody asked about?
5. **Self-Audit + Realist Check**: Low-confidence findings become Open Questions, severity ratings are pressure-tested
6. **Escalation**: If CRITICAL found or 3+ IMPORTANT → adversarial mode (expand scope, challenge every decision)
7. **Verdict**: APPROVE or REJECT with confidence levels and perspective attribution

**If REJECT**: Revise the plan addressing the critic's concerns, then **re-dispatch the critic** following the `ops-redispatch-optimization` process. This re-dispatch is MANDATORY. Maximum 3 iterations. If still rejected after 3 rounds, present both the plan and the critic's concerns to the user for decision.

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

**If APPROVE**: Proceed to Step 9.

---

## Step 9: User Approval

<HARD-GATE-HANDOFF>
/ops-plan NEVER implements code. If the user asks to implement during this skill (e.g., "implemente", "go ahead and build it", "lance", "do it"), you MUST:

1. Complete ALL remaining ops-plan steps first (critic re-dispatch if REJECT, user approval)
2. Then present the plan and ask for approval
3. Once approved, invoke `/ops-implement` as a separate skill — do NOT implement inline

Implementing code without invoking `/ops-implement` is a FAILURE of this skill, regardless of what the user says. The user's "implemente" is approval of the plan, not authorization to bypass the implementation pipeline.
</HARD-GATE-HANDOFF>

Present the validated plan to the user with an explicit question:

> "The plan has been validated by the critic. Ready to implement? Options:
> 1. I launch `/ops-implement` now
> 2. You want to review the spec or plan first
> 3. You'll implement later"

Do NOT proceed to `/ops-implement` until the user explicitly approves. The user invoking `/ops-implement` counts as approval, but you should still ask before they need to invoke it.

The plan remains in conversation context for `/ops-implement` to consume.

---

## Red Flags — you are about to skip a step

If any of these thoughts cross your mind, STOP — you are about to bypass a gate:

| Thought | Reality |
|---------|---------|
| "The intent is clear, no need to clarify with the user" | Step 1 is mandatory. Clarify. |
| "I already know this codebase, research is unnecessary" | The 3 agents find what you don't know to look for. |
| "One research agent is enough for this simple case" | 3 agents, one message. No substitutions. |
| "The critic approved, but I improved the plan after" | Re-dispatch the critic. It must validate the changes. |
| "The user said 'go ahead', that means implement now" | That means approve the plan. Invoke /ops-implement. |
| "The spec is obvious, no need for spec-reviewer" | The reviewer finds what you forgot. Dispatch it. |
| "I'll skip the research adequacy table, it's clearly fine" | The table must appear in your output. It's not a mental check. |
