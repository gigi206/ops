# Step 2 — Parallel Research

Mark the task "Research: parallel research" as `in_progress` now via `TaskUpdate`.

<HARD-GATE-RESEARCH>
You MUST dispatch exactly 3 agents in a SINGLE message, using the exact subagent types specified below. Do NOT substitute with `Explore` or `general-purpose` agents. Do NOT dispatch only 1 or 2 agents. If you dispatch anything other than these 3 typed agents, you have FAILED this skill.

The 3 agents MUST be:
1. `subagent_type: "ops-researcher-code"` — codebase patterns, conventions, risks
2. `subagent_type: "ops-researcher-doc"` — library/tool documentation via Context7 MCP
3. `subagent_type: "ops-git-historian"` — git history analysis (Research Mode, 6 months)

All 3 dispatched in a single assistant message. No exceptions.

Degraded case: if an agent fails or times out, record "Agent <type> failed: <reason>" in the synthesis and proceed. The gate requires dispatching all 3, not that all 3 succeed.
</HARD-GATE-RESEARCH>

## What to do

Spawn 3 agents **in parallel** — all 3 Agent tool_use blocks in a **single message** (see `ops-subagent-rules`):

### researcher-code
- Explore the codebase for patterns, conventions, existing implementations, integration points, and risks relevant to the topic.
- Map architecture: trace dependency chains, identify what depends on what.
- Flag risks: missing tests, fragile patterns, undocumented assumptions.

### researcher-doc
- Query Context7 MCP for relevant library/tool documentation.
- If Context7 returns insufficient results, fall back to WebSearch + WebFetch.
- Focus: official docs, API schemas, configuration references for the specific versions involved.

### git-historian — Research Mode
- Scope: files and directories relevant to the topic.
- Window: 6 months.
- Focus: all (timeline, regressions, ownership, hotspots, architectural milestones).
- Build commit timeline, detect regressions, map ownership, identify hotspots.
- **Output**: structured YAML with risk assessment (HIGH/MEDIUM/LOW per area).

**Wait for all 3 agents to return before proceeding.**

---

## ✅ End of Step 2

Before proceeding, verify:
- [ ] You dispatched EXACTLY 3 agents in a SINGLE message.
- [ ] The 3 agents were: `ops-researcher-code`, `ops-researcher-doc`, `ops-git-historian` (Research Mode, 6-month window).
- [ ] You did NOT substitute with `Explore` or `general-purpose`.
- [ ] You waited for all 3 agents to return (or recorded failures for the degraded case).

Mark the task "Research: parallel research" as `completed` via `TaskUpdate`.

**→ Next: read `skills/research/step-03-synthesize.md` now and execute Step 3.**

Do NOT continue without reading that file first.
