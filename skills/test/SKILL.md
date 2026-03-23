---
name: ops:test
description: "Add tests to existing untested code. Analyzes behavior, identifies gaps, writes meaningful tests."
---

# /ops:test — Add tests to existing code

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops:subagent-rules` process.

## Purpose

Write tests for existing code that lacks coverage. This is NOT TDD (where tests come before code) — this is adding tests to code that already exists and works. The code is the source of truth; the tests verify it.

---

## Workflow

```
1. Scope → 2. Research → 3. Dispatch test-writer → 4. Validate → 5. Code Quality → 6. Code Review → 7. Check CLAUDE.md
```

---

## Step 1: Scope

Identify what needs testing:
- If the user specified files/modules → use those
- If the user said "add tests" broadly → run coverage tools (if available) to identify gaps, or ask the user to narrow scope

Present the scope to the user:
> "I'll add tests for [files/modules]. Current coverage: [X% if measurable, or 'no coverage tools detected']. Does this scope look right?"

This is a soft gate — proceed if the user confirms or doesn't object.

---

## Step 2: Research (2 agents in parallel)

Dispatch two agents **in parallel** — both Agent tool_use blocks in a **single message** (see `ops:subagent-rules`):

### researcher-code
- Explore the target code: behavior, dependencies, integration points
- Identify existing test patterns and conventions in the project
- Flag code that may be hard to test (tight coupling, side effects, global state)

### researcher-doc
- Query Context7 MCP for relevant testing library documentation
- Focus: test runner API, assertion patterns, mocking utilities for the detected framework

**Wait for both agents to return before proceeding.**

---

## Step 3: Dispatch test-writer

Dispatch the **test-writer** agent with:
- The target files to test (with their content — follow `ops:subagent-rules`)
- The existing test conventions found by researcher-code
- The testing framework documentation from researcher-doc
- Any specific user instructions (e.g., "focus on edge cases", "integration tests only")

The test-writer will:
1. Analyze the code to understand behavior
2. Assess current coverage
3. Write tests following existing conventions
4. Run all tests and report results

**Handle the test-writer's report:**
- **DONE**: proceed to Step 4
- **DONE_WITH_CONCERNS**: evaluate the concerns, then proceed
- **BLOCKED**: present the blocker to the user (e.g., "code is untestable without refactoring — suggest `/ops:refactor` first")
- **FAILED**: the test-writer found a bug in existing code. Present it to the user — this is valuable.

---

## Step 4: Validate

Run the full test suite to confirm:
1. All new tests pass
2. All existing tests still pass
3. No regressions introduced

`/ops:verify` behavioral rule applies — show the evidence.

If coverage tools are available, show the before/after delta.

---

## Step 5: Code Quality

Run the `ops:code-quality` process on all modified/created files. Fix any issues.

---

## Step 6: Code Review (light)

Dispatch the **code-reviewer** agent with:
- The complete diff (`git diff`)
- Explicit instruction: **focus on test quality** — are tests meaningful, do they test behavior not implementation, do they follow conventions?
- Skip spec compliance (no spec exists)

**One cycle maximum**: fix issues, re-run review once. If still failing → escalate to user.

---

## Step 7: Check CLAUDE.md

Read `CLAUDE.md` and `.claude/CLAUDE.md`. Verify all applicable rules were followed. Fix violations before completing.
