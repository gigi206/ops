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

Reformulate the user's intent in one sentence to confirm understanding. No Socratic questions, no YAGNI filter.

This IS a gate — wait for user approval before proceeding. Ask the user to confirm and offer the option to launch `/ops:brainstorm` if they want to explore the intent further. If the user corrects the restatement, acknowledge the correction, restate again, and wait for confirmation.

---

## Step 2: Research (2 agents in parallel)

Dispatch two agents **in parallel** — both Agent tool_use blocks in a **single message** (see `ops:subagent-rules`):

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
- **Grouped tasks**: few logically distinct steps. Format: `description → shell validation command` (e.g., "Add permission class → `python3 -m py_compile permissions.py`"). The validation command must be an executable shell command when possible, not a description like "validation visuelle".

---

## Step 5: Execute

Implement the changes directly (no implementer agent). If tasks were defined in Step 4, follow them in order.

---

## Step 6: Verify + Code Quality

1. **Verify**: run build/compile commands, validation commands, dry-runs. `/ops:verify` behavioral rule applies — never claim a result without showing the evidence.
2. **Code quality**: read the `ops:code-quality` skill file, then follow its Steps 1–6 in order on all modified files. You MUST produce the structured report format defined in its Step 6. If no tools are detected, output the "no tools detected" report variant — do NOT brute-force tool execution (e.g., retrying a missing linter multiple times). Fix any issues before proceeding.

---

## Step 7: Security Gate + Code Review

### Security Gate

Read the `ops:security-gate` skill file, then follow its process on the complete diff. Specifically: use `ops-semgrep-scan.sh` (NOT raw `semgrep`) and parse its key=value output format. If triggers match, dispatch the security-reviewer in the **same message** as the code-reviewer (see `ops:subagent-rules`).

### Code Review (light)

Dispatch the **code-reviewer** agent with:

- The complete diff (`git diff`)
- The user's original intent (restatement from Step 1)
- The task list from Step 4 (if any)
- The project's CLAUDE.md rules (if applicable)
- Explicit instruction: **skip spec compliance check** (no spec exists — use user intent and task list as reference)

Scope: LSP diagnostics, code quality, CLAUDE.md conventions. No spec compliance.

**One cycle maximum**: fix issues, then re-dispatch every reviewer that found issues (code-reviewer AND security-reviewer if it was dispatched). Wait for their verdicts and verify approval before proceeding. If still failing after one cycle → escalate to user.

---

## Step 8: Run Tests + Check CLAUDE.md

1. **Run tests**: if the project has a test suite, run it. Max 2 fix attempts if tests fail, then escalate to user. Skip if no test infrastructure.
2. **Update documentation**: if the project has documentation affected by the change, update it. Skip if none exists or none is affected.
3. **Check CLAUDE.md** (always last): read the project's `CLAUDE.md`, `.claude/CLAUDE.md`, AND the user's global `~/.claude/CLAUDE.md`. Verify all applicable rules were followed. Fix violations before completing.
