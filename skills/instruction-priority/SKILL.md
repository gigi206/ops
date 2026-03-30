---
name: ops-instruction-priority
description: "Internal: instruction priority hierarchy when conflicts arise between user, project instructions, ops skills, and system prompt."
user-invocable: false
---

# Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority. If the user says "skip TDD", skip it.
2. **Project instruction rules** (`CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`) — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

If a project instruction rule contradicts an ops skill instruction, follow the project instructions. If the user contradicts the project instructions, follow the user. When in doubt, ask.

## Where to find project instructions

Project instruction files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) are located **at the project root** and its subdirectories. Never search outside the project directory — do not glob or read `~`, `~/.claude/`, or other user-level directories to find project instructions.

## Language

Respond in the same language as the user's messages. If the user writes in French, respond in French. If in English, respond in English. Technical terms and code identifiers remain in their original form.