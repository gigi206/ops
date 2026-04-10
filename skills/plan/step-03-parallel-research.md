# Step 3 — Parallel Research

Mark the task "Plan: parallel research" as `in_progress` now via `TaskUpdate`.

## If `/ops-brainstorm` was already run — Delta Research Mode

The brainstorm already explored project context (Step 3), locked an architectural approach (Step 7), and validated a design (Step 8). Full from-scratch research would duplicate that work.

**In delta research mode, the HARD-GATE-RESEARCH below does NOT apply.** The gate exists to prevent lazy skipping of research in cold-start mode — post-brainstorm, the foundational research was already done.

**Dispatch only what is needed:**

1. **`researcher-code`** — ALWAYS dispatch, but with a **delta prompt**: "The brainstorm already identified [summarize key findings: patterns, files, conventions]. Verify these findings are still accurate. Focus on gaps: patterns, risks, or integration points the brainstorm may have missed. Do NOT re-discover what is already known."
2. **`researcher-doc`** — dispatch ONLY IF the brainstorm summary mentions an external dependency, library, or tool not yet validated by documentation. Skip if all dependencies are internal or already documented.
3. **`git-historian`** — dispatch ONLY IF the brainstorm was run in a previous session (not the current conversation) where git state may have changed since. Skip if brainstorm was run earlier in this same conversation.

Dispatch whichever agents are needed in a single message. It may be 1, 2, or 3 agents depending on the conditions above.

After synthesis, proceed to Step 4 as normal. In the research adequacy table, cite brainstorm findings alongside delta research findings — both count as evidence.

---

## Full Research Mode (when brainstorm was NOT already run)

<HARD-GATE-RESEARCH>
You MUST dispatch at least 2 agents in a SINGLE message, using the exact subagent types specified below. Do NOT substitute with `Explore` or `general-purpose` agents.

**Always dispatch (mandatory):**
1. `subagent_type: "ops-researcher-code"` — codebase patterns, conventions, risks
2. `subagent_type: "ops-researcher-doc"` — library/tool documentation via Context7 MCP

**Conditionally dispatch:**
3. `subagent_type: "ops-git-historian"` — git history analysis (Research Mode, 6 months). Dispatch ONLY IF at least one of these conditions is true:
   - The project has multiple contributors (check `git shortlog -sn --since="6 months ago" | wc -l` > 1)
   - The files to be modified have a history of frequent changes or regressions (hotspots)
   - The task involves modifying or extending existing behavior (not a pure greenfield addition)
   If none of these apply, skip git-historian and note "git-historian: skipped — [reason]" in the synthesis.

All agents dispatched in a single message. Degraded case: if an agent fails or times out, record "Agent <type> failed: <reason>" in the research synthesis and proceed.
</HARD-GATE-RESEARCH>

Run the `ops-research` process: dispatch the agents above in parallel, synthesize findings, and conditionally dispatch one or more researcher-repo agents for targets where researcher-doc signals `Source Verification Needed: high`. Scope the research to the task area identified during intent clarification.

---

## ✅ End of Step 3

Before proceeding, verify:

**If delta research mode (post-brainstorm):**
- [ ] You dispatched `researcher-code` with a delta prompt referencing brainstorm findings.
- [ ] You dispatched `researcher-doc` and/or `git-historian` only if the conditions above required it, and stated why for any skipped agent.
- [ ] You synthesized delta findings alongside brainstorm findings.

**If full research mode (no prior brainstorm):**
- [ ] You dispatched at least 2 agents (researcher-code + researcher-doc) in a SINGLE message.
- [ ] You dispatched git-historian only if a condition was met (multiple contributors, hotspot files, or modifying existing behavior), OR you noted why it was skipped.
- [ ] You did NOT substitute with `Explore` or `general-purpose`.
- [ ] You synthesized the findings (including any failed-agent or skipped-agent notes).
- [ ] If any researcher-doc target had `Source Verification Needed: high`, you conditionally dispatched `researcher-repo` for it.

Mark the task "Plan: parallel research" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-04-research-adequacy.md` now and execute Step 4.**

Do NOT continue without reading that file first.
