# Changelog

## 1.1.0 (2026-03-16)

### New skill: `/ops:security`
- On-demand security review — invoke directly without going through `/ops:implement` or `/ops:debug`
- Supports multiple scopes: staged changes, specific files, directories, branch diff, specific commit
- Triages security domains before dispatching, skips review when nothing sensitive is found
- Optional fix-and-verify loop: apply fixes, re-dispatch security-reviewer to confirm

### Security reviewer rewritten — fully technology-agnostic
- Covers the full spectrum: application code, infrastructure as code, CI/CD pipelines, container/runtime, supply chain, policy enforcement
- 9 analysis categories (was 5): added CI/CD & Build Pipeline, Supply Chain & Dependencies, Policy Enforcement & Compliance, expanded Infrastructure & Runtime
- Broader trust boundaries: `build → deploy`, `human → machine` in addition to classic user/service boundaries
- Broader attacker profiles: CI/CD attacker, supply chain attacker, insider
- No technology names anywhere — principles over vendors
- Explicit constraint: "Technology-agnostic. Name the principle, not the vendor."

### Security escalation triggers expanded (implement, debug)
- 8 triggers → 14 triggers covering full DevSecOps spectrum
- Added: IaC, CI/CD pipelines, runtime privileges, dependency/supply chain, policy enforcement, data storage/retention, logging/audit/observability
- Removed technology-specific references (OIDC, OAuth2, Kyverno, OPA) — replaced with agnostic equivalents

### SessionStart hook updated
- Added `/ops:security` to skill routing table

## 1.0.1 (2026-03-16)

Enforcement fixes based on real-world session analysis. Addresses orchestrator compliance gaps where steps were skipped or shortcuts taken.

### Enforce per-task code review (`implement/SKILL.md`)
- Add HARD-GATE: every task must complete full pipeline (implementer → validation → conformity → code review) before next task starts
- One task = one implementer agent — no bundling multiple tasks into a single dispatch
- Parallelization rules: max 3 parallel tasks, each with its own complete pipeline
- Code review made MANDATORY with strict trivial-task exception (≤1 file, pure rename/comment/config, no logic)
- Conformity check (2c) made MANDATORY with explicit diff-vs-plan verification

### Enforce security-reviewer dispatch (`implement/SKILL.md`, `debug/SKILL.md`)
- Security escalation is now a gate, not a suggestion — "you have FAILED this skill" if skipped
- Added OIDC/SSO/OAuth2 and Kyverno/OPA to security-sensitive areas list
- Final review: security-reviewer mandatory when any task touched security areas
- "When in doubt, dispatch" — false positives are cheap, missed vulns are not

### Enforce critic and spec-reviewer re-dispatch (`plan/SKILL.md`)
- Critic re-dispatch after REJECT is now MANDATORY — "you have FAILED this skill" if skipped
- Spec-reviewer re-dispatch after fixes is now MANDATORY

### Enforce context detection and research adequacy (`plan/SKILL.md`)
- Context detection (Step 2) cannot be skipped — "Do NOT skip this step"
- LSP Level 1 test is now mandatory (takes seconds)
- Research adequacy check must present an explicit OK/GAP table to the user

### Enforce brainstorm discipline (`plan/SKILL.md`)
- "One question at a time" reinforced: ONE question per message, not 2-3 grouped
- Anti-pattern: "If you catch yourself writing Question 4:, Question 5: — STOP"
- Explicit user approval question added at Step 9

### Enforce TaskList verification (`implement/SKILL.md`)
- TaskList call at completion is now MANDATORY — must be called and shown

### Remove hardcoded model references (all SKILL.md files)
- Removed all `(Sonnet)` and `(Opus)` model annotations from skill files
- Model is defined in agent frontmatter, not in the skill — avoids inconsistency

### Agents upgraded to Opus
- **spec-reviewer** — Sonnet → Opus
- **implementer** — Sonnet → Opus
- **code-reviewer** — Sonnet → Opus
- **security-reviewer** — Sonnet → Opus

### Align debug/SKILL.md
- Same security escalation enforcement as implement
- Same trivial-task exception for code review
- Removed model references

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
- **spec-reviewer** (Opus) — Spec completeness validation (7 dimensions)
- **implementer** (Opus) — Task execution with TDD (Red/Green/Refactor), deletion rule, anti-rationalization
- **code-reviewer** (Opus) — LSP diagnostics, spec compliance, code quality, security scan, TDD adherence
- **security-reviewer** (Opus) — Threat analysis, attack scenarios, evidence-based findings

### TDD
- Full TDD reference with code examples, deep arguments, and troubleshooting
- Testing anti-patterns guide (mock behavior, test-only methods, incomplete mocks)

### Hooks
- SessionStart hook injects skill routing context

### Visual
- Browser-based brainstorm companion with WebSocket server (from superpowers, MIT)
