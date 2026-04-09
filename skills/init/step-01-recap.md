# Step 1 — Recap

Mark the task "Init: recap" as `in_progress` now via `TaskUpdate`.

Show what ops provides in this environment.

## 1a. Skills

Count available skills by scanning the skills directory. Report: "**N skills** loaded" with a collapsed list if the user wants details.

## 1b. Agents

Count registered agents by scanning the `agents/` directory in the ops plugin root (same level as `skills/`). Each `.md` file is one agent. Report: "**N agents** registered".

On OpenCode: verify agents are actually available by listing the agent names the plugin registered via `config.agent`. If the count is 0 or lower than expected, note the registration failure.

## 1c. MCP Servers

Dispatch to the CLI-specific sub-skill for MCP diagnostic only:
- If `cli=claude-code`: follow the MCP section of `skills/init/claude-code.md` (Category 2)
- If `cli=opencode`: follow the MCP section of `skills/init/opencode.md` (Category 2)

Report the status of each MCP server. **If any MCP server is missing or broken, stop and propose solutions.** Wait for the user's decision before proceeding.

---

## ✅ End of Step 1

Before proceeding, verify:
- [ ] You counted and reported available skills.
- [ ] You counted and reported registered agents (on OpenCode, you verified agents are actually registered via `config.agent`).
- [ ] You dispatched to the correct CLI-specific sub-skill (`claude-code.md` or `opencode.md`) for MCP diagnostic.
- [ ] If any MCP server was missing or broken: you stopped, presented findings, proposed solutions, and waited for the user's decision.

Mark the task "Init: recap" as `completed` via `TaskUpdate`.

**→ Next: read `skills/init/step-02-ops-tools.md` now and execute Step 2.**

Do NOT continue without reading that file first.
