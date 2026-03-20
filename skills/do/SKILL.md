---
name: ops:do
description: "Lightweight structured workflow: research, execute, verify, review."
---

# /ops:do — Lightweight structured workflow

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops:subagent-rules` process.

## Workflow

```
1. Restatement → 2. Research (2 agents) → 3. Scope Guard → 4. Tasks (optional) → 5. Execute → 6. Verify + Code Quality → 7. Security Gate + Code Review → 8. Run Tests + Check CLAUDE.md
```

---

## Step 1: Restatement

Reformulate the user's intent in one sentence to confirm understanding. No Socratic questions, no brainstorming, no YAGNI filter.

This is NOT a gate — no user approval required. State what you understood and proceed to Step 2. If the user corrects the restatement, acknowledge the correction, restate again, and continue.

---

## Step 2: Research (2 agents in parallel)

Dispatch two agents **in parallel** using the Agent tool:

### researcher-code
- Explore the codebase for patterns, conventions, existing implementations, integration points, and risks relevant to the task.

### researcher-doc
- Query Context7 MCP (fallback: web search) for relevant library/tool documentation.

**Wait for both agents to return before proceeding.**

---

## Step 3: Scope Guard

After research returns, evaluate whether the task is actually simple enough for `/ops:do`:

- If research reveals **non-obvious design choices** (multiple valid approaches, conflicting patterns, architectural implications) → suggest escalating to `/ops:plan`.
- If research reveals the change is **far larger than expected** (touching many independent subsystems) → suggest escalating to `/ops:plan`.

This is a safety valve, not a gate. The user can override.

---

## Step 4: Tasks (optional)

Based on the complexity of the **decision**, not the volume of files:

- **No tasks**: mechanical/evident change — proceed directly to Step 5.
- **Grouped tasks**: few logically distinct steps. Format: `description → validation command`.

---

## Step 5: Execute

Implement the changes directly (no implementer agent). If tasks were defined in Step 4, follow them in order.

---

## Step 6: Verify + Code Quality

1. **Verify**: run build/compile commands, validation commands, dry-runs. `/ops:verify` behavioral rule applies — never claim a result without showing the evidence.
2. **Code quality**: run the `ops:code-quality` process on all modified files (format + lint). Fix any issues before proceeding.

---

## Step 7: Security Gate + Code Review

### Security Gate

Run the `ops:security-gate` process on the complete diff. If triggers match, the security-reviewer is dispatched in parallel with the code-reviewer.

### Code Review (light)

Dispatch the **code-reviewer** agent with:

- The complete diff (`git diff`)
- The user's original intent (restatement from Step 1)
- The task list from Step 4 (if any)
- The project's CLAUDE.md rules (if applicable)
- Explicit instruction: **skip spec compliance check** (no spec exists — use user intent and task list as reference)

Scope: LSP diagnostics, code quality, CLAUDE.md conventions. No spec compliance.

**One cycle maximum**: fix issues, re-run review once. If still failing → escalate to user.

---

## Step 8: Run Tests + Check CLAUDE.md

1. **Run tests**: if the project has a test suite, run it. Max 2 fix attempts if tests fail, then escalate to user. Skip if no test infrastructure.
2. **Update documentation**: if the project has documentation affected by the change, update it. Skip if none exists or none is affected.
3. **Check CLAUDE.md** (always last): read `CLAUDE.md` and `.claude/CLAUDE.md`. Verify all applicable rules were followed. Fix violations before completing.
