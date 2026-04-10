---
name: ops-do
description: "Use when the task is well-understood, small, and doesn't need design discussion."
---

# /ops-do — Lightweight structured workflow

**Read `data/common_instructions.md` before executing this skill.**

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Workflow

```
1. Restatement → 2. Research (2 agents) → 3. Scope Guard → 4. Tasks (optional) → 5. Execute → 6. Verify → 7. Review Pipeline → 8. Run Tests + Documentation
```

---

## Step 1: Restatement

Reformulate the user's intent in one sentence to confirm understanding. No Socratic questions, no YAGNI filter.

This IS a gate — wait for user approval before proceeding. Ask the user to confirm and offer the option to launch `/ops-brainstorm` if they want to explore the intent further. If the user corrects the restatement, acknowledge the correction, restate again, and wait for confirmation.

---

## Step 2: Research (2 agents in parallel)

Dispatch two agents **in parallel** — both Agent tool_use blocks in a **single message** (see `ops-subagent-rules`):

### researcher-code
- Explore the codebase for patterns, conventions, existing implementations, integration points, and risks relevant to the task.

### researcher-doc
- Query Context7 MCP (fallback: web search) for relevant library/tool documentation.

**Wait for both agents to return before proceeding.**

---

## Step 3: Scope Guard

After research returns, evaluate whether the task is actually simple enough for `/ops-do`:

- If research reveals **non-obvious design choices** (multiple valid approaches, conflicting patterns, architectural implications) → suggest escalating to `/ops-brainstorm` to clarify intent before planning.
- If research reveals the change is **far larger than expected** (touching many independent subsystems) → suggest escalating to `/ops-brainstorm` to decompose the problem.

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

## Step 6: Verify

Run build/compile commands, validation commands, dry-runs. `/ops-verify` behavioral rule applies — never claim a result without showing the evidence.

---

## Step 7: Review Pipeline

Run the `ops-review-pipeline` process with the following code-reviewer context:
- The user's original intent (restatement from Step 1)
- The task list from Step 4 (if any)
- Explicit instruction: **skip plan compliance check** (no plan exists — use user intent and task list as reference)
- Scope: LSP diagnostics, code quality, project conventions. No plan compliance.

---

## Step 8: Run Tests + Documentation

1. **Run tests**: if the project has a test suite, run it. Max 2 fix attempts if tests fail, then escalate to user. Skip if no test infrastructure.
2. **Update documentation**: if the project has documentation affected by the change, update it. Skip if none exists or none is affected.
