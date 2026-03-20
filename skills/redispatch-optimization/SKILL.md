---
name: ops:redispatch-optimization
description: "Internal: optimize re-dispatch prompts for review agents. Activated when re-dispatching spec-reviewer, critic, code-reviewer, or security-reviewer after fixes."
user-invocable: false
---

# Re-dispatch Prompt Optimization

When re-dispatching any review agent (spec-reviewer, critic, code-reviewer, security-reviewer) after applying fixes, the re-dispatch prompt must be optimized.

## Rules

1. **Do NOT re-include full context.** The agent can re-read files at their paths. Do not paste the full spec, plan, diff, or CLAUDE.md into the re-dispatch prompt.

2. **Include only:**
   - The reviewer's previous findings (the issues list verbatim)
   - The corrections applied and the rationale for each
   - The path to the updated file/spec (so the agent re-reads it fresh)
   - A request to produce the full standard verdict (e.g., `Status: Approved` / `Status: Issues Found`, or `Verdict: APPROVE` / `Verdict: REJECT` with confidence levels)

3. **Cap iterations.** Maximum 3 re-dispatch iterations per review agent. If still not approved after 3 rounds, surface the remaining issues to the user for guidance.

4. **Mandatory re-dispatch.** If you fix a reviewer's concerns but do not re-dispatch the reviewer, you have FAILED the skill. The whole point of review is adversarial validation — bypassing the re-check defeats the purpose.
