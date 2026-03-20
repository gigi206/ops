---
name: ops:instruction-priority
description: "Internal: instruction priority hierarchy when conflicts arise between user, CLAUDE.md, ops skills, and system prompt."
user-invocable: false
---

# Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority. If the user says "skip TDD", skip it.
2. **CLAUDE.md project rules** — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

If a CLAUDE.md rule contradicts an ops skill instruction, follow CLAUDE.md. If the user contradicts CLAUDE.md, follow the user. When in doubt, ask.
