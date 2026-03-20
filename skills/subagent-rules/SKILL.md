---
name: ops:subagent-rules
description: "Internal: context rules for dispatching subagents. Activated when any ops skill dispatches research, review, or implementation agents."
user-invocable: false
---

# Subagent Context Rules

When dispatching any subagent:

- **Provide content inline.** If you already read a file, paste the relevant content into the agent prompt. Do NOT ask the agent to re-read the same file.
- **Scope the context.** Give the agent only what it needs for its task — not the entire plan, not every file you've read. A researcher-code analyzing conventions needs the task area files, not the brainstorm transcript.
- **Name what you provide.** Always label pasted content with its source: `[From src/auth/middleware.ts:15-42]`. The agent needs to know where the content comes from to cite it.
- **Let the agent explore beyond.** Providing context doesn't mean restricting the agent. It can and should read additional files it discovers during exploration — the goal is to avoid redundant reads, not to limit scope.
