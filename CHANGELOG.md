# Changelog

## 1.0.0 (2026-03-15)

Initial public release.

### Skills
- `/ops:plan` — Brainstorm, parallel research (3 agents), spec writing, adversarial critic review, user approval
- `/ops:implement` — Task-by-task execution with validation gates, conformity checks, code review, security escalation, circuit breakers, TaskCreate/TaskUpdate tracking
- `/ops:debug` — Systematic root-cause investigation with hypothesis testing and circuit breaker
- `/ops:review` — Evaluate code review feedback technically before acting
- `/ops:ship` — Validate, commit, optional PR, capture learnings, propose `.claude/rules/` from recurring lessons
- `/ops:verify` — Behavioral skill (always active): evidence before claims

### Agents
- **critic** (Opus) — Adversarial plan review with 4 lenses, 3 perspectives, self-audit
- **researcher-code** (Opus) — Codebase patterns, conventions, architecture mapping, risk flagging
- **researcher-doc** (Sonnet) — External docs via Context7 MCP with version validation and source priority
- **git-historian** (Sonnet) — Commit timeline, regressions, ownership, hotspots
- **spec-reviewer** (Sonnet) — Spec completeness validation (7 dimensions)
- **implementer** (Sonnet) — Task execution with TDD (Red/Green/Refactor), deletion rule, anti-rationalization
- **code-reviewer** (Sonnet) — LSP diagnostics, spec compliance, code quality, security scan, TDD adherence
- **security-reviewer** (Sonnet) — Threat analysis, attack scenarios, evidence-based findings

### TDD
- Full TDD reference with code examples, deep arguments, and troubleshooting
- Testing anti-patterns guide (mock behavior, test-only methods, incomplete mocks)

### Hooks
- SessionStart hook injects skill routing context

### Visual
- Browser-based brainstorm companion with WebSocket server (from superpowers, MIT)
