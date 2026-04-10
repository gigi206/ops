You have access to ops workflow skills. Before starting any non-trivial work, check if a skill applies:

**Every skill reads `data/common_instructions.md` before executing.** Those rules (user language, one question at a time, stop-and-propose, no unsolicited changes) apply globally.

| Situation                                  | Skill                         |
| ------------------------------------------ | ----------------------------- |
| New feature, change, or task               | `/ops-plan`                   |
| Full pipeline (plan + implement + ship)    | `/ops-full`                   |
| Plan approved, ready to build              | `/ops-implement`              |
| Bug, error, or unexpected behavior         | `/ops-debug`                  |
| Add tests to existing code                 | `/ops-test`                   |
| Restructure code without changing behavior | `/ops-refactor`               |
| Something is slow, needs optimization      | `/ops-perf`                   |
| Review someone else's PR                   | `/ops-review-pr`              |
| Explore a topic or codebase area           | `/ops-research`               |
| Clarify requirements interactively         | `/ops-brainstorm`             |
| Received code review feedback              | `/ops-review`                 |
| Security audit on changes                  | `/ops-security`               |
| Full codebase audit (quality + security)   | `/ops-audit`                  |
| Analyze an external repository or library  | `/ops-clone-analyze`          |
| First use or new environment               | `/ops-init`                   |
| Work is done, ready to commit              | `/ops-ship`                   |
| Claiming something works                   | `/ops-verify` (always active) |
| Small task, already understood             | `/ops-do`                     |
| Trivial fix (typo, rename)                 | No skill needed               |

If the user describes a task that needs design or research, suggest `/ops-plan` before coding.
If the user wants to understand a codebase area or gather context, suggest `/ops-research`.
If the user wants to think through requirements before planning, suggest `/ops-brainstorm`.
If the user wants to plan, implement, and ship in one go, suggest `/ops-full`.
If the user asks to commit or ship, suggest `/ops-ship`.
If the user reports a bug, suggest `/ops-debug`.
If the user wants to add tests to existing code, suggest `/ops-test`.
If the user wants to refactor or restructure code, suggest `/ops-refactor`.
If the user reports a performance problem, suggest `/ops-perf`.
If the user wants to review a PR, suggest `/ops-review-pr`.
If the user wants to understand an external library, framework, or tool by reading its source code, suggest `/ops-clone-analyze`.
If the user wants a full codebase audit (quality, security, complexity), suggest `/ops-audit`.
If the user wants to check their environment or install tools, suggest `/ops-init`.
If the user describes a task that is well-understood and doesn't need design discussion, suggest `/ops-do` before coding.
Do NOT force skills on trivial requests (rename a variable, fix a typo, answer a question).