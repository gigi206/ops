---
name: ops-refactor
description: "Use when code needs restructuring without changing its external behavior."
---

# /ops-refactor — Refactor code safely

**Read `data/common_instructions.md` before executing this skill.**

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

<HARD-GATE-REFACTOR-LSP>

**Before planning any step that changes a function/method/class signature** (adding a parameter, removing a parameter, reordering parameters, changing a parameter type, changing a return type, renaming the symbol, removing the symbol), you MUST run LSP `findReferences` on that symbol FIRST. This is not optional. Grep-based blast-radius analysis is lossy: it misses aliases, re-exports, dynamic dispatch, and cross-module imports that LSP resolves correctly. The reference list is the concrete input to the step plan — without it, you cannot predict what else breaks.

For each signature change, the step description MUST include the reference count and the callers affected as an inline annotation at the end of the step line, in this canonical compact form: `(reference scan: N callers across M files: file1:line, file2:line, …)`. The example below (line ~107) demonstrates this form. If a single step touches many callers and the inline list would be unwieldy, truncate the file list with `…` and spell out the full list in a follow-up sub-step bullet under the step line — but the count (`N callers across M files`) must always be present inline.

**If LSP is not available** for the target language (no server, or `/ops-init` Step 6 flagged LSP as missing), note it explicitly in Step 4 output: *"LSP not available — falling back to grep-based reference scan. Blast radius may be incomplete."* Then run a best-effort grep for the symbol name. Do NOT proceed silently on grep-only analysis — the user needs to know the guarantee is weaker.

**Non-signature refactorings** (rename-within-scope, extract-local, inline-local, move-file-only-internal) do NOT require `findReferences` when they are lexically scoped to a single file or function. Use LSP `documentSymbol` + a read of the target file instead.

See `ops-subagent-rules` HARD-GATE-LSP for the canonical rule.

</HARD-GATE-REFACTOR-LSP>

Present the steps to the user. Every signature-change step MUST list the reference count on its line; non-signature steps do not need it:

> "I'll refactor in [N] steps:
> 1. [Signature-change step description, e.g. "add `ctx` parameter to `handleRequest`"] — verify: tests pass (reference scan: 12 callers across 5 files: `a.ext:L`, `b.ext:L`, …)
> 2. [Another signature-change step] — verify: tests pass (reference scan: 3 callers in 2 files: `x.ext:L`, `y.ext:L`)
> 3. [Non-signature step, e.g. "extract local helper `formatKey` within `handleRequest`"] — verify: tests pass
> 4. [Non-signature step, e.g. "rename internal variable `r` to `result`"] — verify: tests pass
> ...
> Each step preserves behavior. Approve?"

Signature-change steps without a reference count are a HARD-GATE-REFACTOR-LSP violation — the planner either forgot to run `findReferences` or is hiding the blast radius. Do NOT proceed on a signature-change step with a missing reference count.

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
