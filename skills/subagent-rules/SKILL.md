---
name: ops:subagent-rules
description: "Internal: dispatch rules for subagents (parallelism, context). Activated when any ops skill dispatches research, review, or implementation agents."
user-invocable: false
---

# Subagent Dispatch Rules

When dispatching any subagent:

- **"In parallel" means one message, multiple Agent tool_use blocks.** When a skill says to dispatch agents "in parallel", you MUST include all Agent tool calls in a **single assistant message**. Dispatching each agent in a separate message is sequential, not parallel — even if the messages are seconds apart. If your message contains only one Agent tool_use when the skill asked for N in parallel, you are NOT running in parallel.
- **Provide content inline.** If you already read a file, paste the relevant content into the agent prompt. Do NOT ask the agent to re-read the same file.
- **Scope the context.** Give the agent only what it needs for its task — not the entire plan, not every file you've read. A researcher-code analyzing conventions needs the task area files, not the brainstorm transcript.
- **Name what you provide.** Always label pasted content with its source: `[From src/auth/middleware.ts:15-42]`. The agent needs to know where the content comes from to cite it.
- **Let the agent explore beyond.** Providing context doesn't mean restricting the agent. It can and should read additional files it discovers during exploration — the goal is to avoid redundant reads, not to limit scope.
