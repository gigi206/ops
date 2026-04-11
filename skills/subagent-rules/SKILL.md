---
name: ops-subagent-rules
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
- **Respect effort baselines.** Each agent defines a default `effort` level in its frontmatter. Do not override it unless the task clearly warrants a different level. When overriding, prefer lowering effort for mechanical subtasks (e.g., a researcher-code doing a single targeted lookup) rather than raising it.
<HARD-GATE-LSP>

- **LSP-first for symbol queries.** Before dispatching `researcher-code`, `researcher-doc`, `git-historian`, or any grep-heavy exploration for a **symbol-oriented** question, you MUST first attempt the appropriate LSP operation. The symbol-oriented questions are:
  - "Where is `<symbol>` defined?" → `goToDefinition`
  - "Who calls / references `<symbol>`?" → `findReferences`
  - "What symbols does this file export or contain?" → `documentSymbol`
  - "Is `<symbol>` defined anywhere in this workspace?" → `workspaceSymbol`
  - "What is the type / signature / docstring of `<symbol>`?" → `hover`

  LSP is more precise than grep — it resolves types, follows imports, and understands scope. It is also **orders of magnitude cheaper** than an LLM dispatch: an LSP query returns in milliseconds with deterministic output, while a `researcher-code` dispatch burns thousands of tokens and is non-deterministic. Burning tokens on questions LSP answers in milliseconds is a FAILURE.

- **Dispatch is allowed when**:
  - LSP is not available for the target language (no server configured, or the skill's init diagnostic flagged LSP as missing).
  - The LSP query fails, errors, or returns empty results AND you have a reasonable fallback hypothesis to justify the dispatch.
  - The question is genuinely **semantic** rather than symbol-oriented: "how is this pattern used across the codebase?", "what conventions does this module follow?", "why is this code structured this way?" — these require reasoning, not symbol lookup.
  - The question is genuinely **structural** and falls outside LSP's symbol model: "find all functions with this body shape", "find duplicated logic across tasks", "find all HTTP handlers matching this pattern" — these are ast-grep territory (see `/ops-plan` Step 7 Duplication Scan) or LLM territory, not LSP.

- **Fallback protocol** when LSP is unavailable:
  1. Note the LSP absence once in your output (e.g., "LSP not available for language X — falling back to grep/dispatch").
  2. Use grep/dispatch as the replacement path.
  3. Do NOT retry LSP repeatedly — one attempt is enough to decide.

- **Explicit tool-name guidance**:
  - Before changing a function or method **signature**: `findReferences` is MANDATORY (not optional). You cannot assess the blast radius of a signature change without knowing every caller.
  - Before tracing a stack-trace symbol during debugging: `goToDefinition` is the first probe — do not grep for the symbol name until LSP has returned nothing useful.
  - Before generating a duplication inventory on a file: `documentSymbol` is the first probe — it gives the symbol list for free, then ast-grep compares bodies.

- **LSP is available when** the init diagnostic (`/ops-init` Step 6) reported the LSP server as present and responsive for the target file's language. If the init was never run, try the LSP operation anyway and fall back on failure — the tool environment may still have LSP configured.

</HARD-GATE-LSP>
