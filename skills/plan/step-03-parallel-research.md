# Step 3 — Parallel Research

Mark the task "Plan: parallel research" as `in_progress` now via `TaskUpdate`.

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

## ✅ End of Step 3

Before proceeding, verify:
- [ ] You dispatched EXACTLY 3 agents (researcher-code + researcher-doc + git-historian) in a SINGLE message.
- [ ] You did NOT substitute with `Explore` or `general-purpose`.
- [ ] You synthesized the findings (including any failed-agent notes for the degraded case).
- [ ] If any researcher-doc target had `Source Verification Needed: high`, you conditionally dispatched `researcher-repo` for it.

Mark the task "Plan: parallel research" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-04-research-adequacy.md` now and execute Step 4.**

Do NOT continue without reading that file first.
