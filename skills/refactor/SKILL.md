---
name: ops-refactor
description: "Use when code needs restructuring without changing its external behavior."
---

# /ops-refactor — Refactor code safely

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Purpose

Restructure existing code to improve its design without changing external behavior. The key constraint: **every step must be verifiable** — if tests pass before and after, behavior is preserved.

---

## Workflow

```
1. Scope → 2. Research → 3. Coverage gate → 4. Plan incremental steps → 5. Execute → 6. Verify → 7. Review Pipeline
```

---

## Step 1: Scope and Intent

Clarify what the user wants to refactor and why:
- Which files/modules/components?
- What's wrong with the current structure? (duplication, tight coupling, unclear boundaries, too-large files)
- What does "better" look like? (specific goal, not vague "cleaner code")

Present the scope:
> "I'll refactor [target] to [goal]. The behavior must remain unchanged. Does this sound right?"

---

## Step 2: Research (2 agents in parallel)

Dispatch two agents **in parallel** — both Agent tool_use blocks in a **single message** (see `ops-subagent-rules`):

### researcher-code
- Map the target code: structure, dependencies, integration points
- Identify what depends on this code (callers, importers, consumers)
- Flag risks: tight coupling, side effects, shared mutable state
- Note existing test coverage for the target area

### researcher-doc
- Query Context7 MCP for relevant refactoring patterns (if a specific technique is involved)
- Focus: language-specific refactoring idioms, framework migration patterns (if applicable)

**Wait for both agents to return before proceeding.**

---

## Step 3: Coverage Gate

**This is a hard gate.** Before touching any code, verify that the behavior is testable:

1. Run existing tests for the target area. **All must pass.** This is the baseline.
2. Assess coverage:
   - If coverage tools exist → run them and report the percentage for the target files
   - If no coverage tools → manually check if critical paths have tests

**Decision:**
- **Good coverage** (critical paths tested) → proceed to Step 4
- **Low coverage** (major behaviors untested) → **STOP.** Present to user:
  > "The code I'm about to refactor has low test coverage. Without tests, I can't guarantee behavior is preserved. Options:
  > A) Add tests first with `/ops-test`, then refactor
  > B) Proceed anyway (risky — behavior changes may go undetected)
  > C) Narrow the scope to the tested parts only"

Wait for user decision.

---

## Step 4: Plan Incremental Steps

Break the refactoring into small, independently verifiable steps. Each step must:
- Be a single, focused change (rename, extract, move, inline, split)
- Leave the code in a working state after completion
- Be verifiable by running the test suite

Present the steps to the user:
> "I'll refactor in [N] steps:
> 1. [Step description] — verify: tests pass
> 2. [Step description] — verify: tests pass
> ...
> Each step preserves behavior. Approve?"

This is a soft gate — proceed if the user confirms or doesn't object.

---

## Step 5: Execute

For each step:
1. **Make the change** — one focused transformation
2. **Run the test suite** — all tests must pass
3. **If tests fail** → undo the change, diagnose, and either fix the approach or ask the user
4. **If tests pass** → proceed to next step

**Do NOT combine steps.** Each step is independently committed in your mental model — if step 3 breaks something, you roll back step 3, not steps 1-3.

**Do NOT change behavior.** If you find a bug during refactoring, report it but don't fix it. Fixing a bug changes behavior — that's a separate task.

---

## Step 6: Verify

After all steps are complete:
1. Run the full test suite — all tests must pass
2. Compare the diff to ensure no behavior was changed (only structure)
3. `/ops-verify` behavioral rule applies — show the evidence

---

## Step 7: Review Pipeline

Run the `ops-review-pipeline` process with the following code-reviewer context:
- The refactoring goal (from Step 1)
- Explicit instruction: **verify behavior preservation** — the code should do the same thing in a better way. Flag any behavioral changes.
