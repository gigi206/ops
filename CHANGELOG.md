# Changelog

## 1.4.2 (2026-03-17)

- docs: fix install instructions — separate marketplace and local clone methods, remove incorrect commands

## 1.4.1 (2026-03-17)

### Fixes from session d6e7934d analysis
- fix: require risk profile (maintenance status, last release, community size) for dependencies validated conversationally during brainstorming, not just at the formal Step 5 gate
- fix: remove `--all` flag from git-historian search commands — prevents finding commits from unmerged branches, stashes, or orphaned refs that are not on the current branch lineage

## 1.4.0 (2026-03-16)

- docs: add tip about git cloning external sources for deeper understanding
- docs: add marketplace prerequisite to install instructions

## 1.3.0 (2026-03-16)

### Move code review and security review to final-only

Per-task code review and security review removed. Both now happen once at the end on the complete diff.

**Why**: Real-world cost analysis showed per-task reviews would cost ~$37 (15 code-reviewers + 10 security-reviewers) while adding no detection value — the final review catches the same bugs with better cross-task context. Two sessions confirmed: 5 bugs found in final review (session 659f), 0 bugs caught by per-task reviews that the final review missed (session 7ea1).

#### Per-task pipeline simplified
- Pipeline is now: `implementer → validation → conformity check → discovery check → task completion record`
- No code-reviewer or security-reviewer dispatched per task
- Conformity check (orchestrator-level, no agent dispatch) remains as the per-task quality gate
- Task completion record simplified: removed code review and security triage lines

#### Final review restructured
- Security triage now happens once on the complete diff with explicit output format
- Code-reviewer and security-reviewer dispatched in parallel on the full diff
- Pre-review audit simplified to count implementers vs tasks (no per-task review counts)

#### Cost impact
- Estimated review cost per session: ~$3-4 (1 final code review + 1 final security review) instead of ~$37 (15+10 per-task dispatches)

## 1.2.0 (2026-03-16)

### Orchestrator compliance enforcement — anti-skip mechanisms

Based on real-world session analysis where the orchestrator skipped code reviews (2/15 tasks reviewed), never dispatched the security-reviewer (despite network policies, access control, and identity federation), and bundled multiple tasks into single implementer agents.

#### External Dependency Validation gate (plan)
- New MANDATORY gate in Step 5: all agent-chosen dependencies must be presented to the user with alternatives before inclusion in the spec
- Distinguishes user-requested dependencies (already validated) from agent-chosen dependencies (must ask)
- Prevents the agent from silently choosing libraries, charts, tools, or services without user approval

#### Task Completion Record (implement)
- New Step 2f: mandatory structured output for every task with explicit security triage line
- Forces the orchestrator to write "Security triage: YES/NO" after evaluating the 14 triggers — no silent skipping
- Covers all pipeline steps: implementer status, validation command + exit code, conformity, code review, security triage, discovery

#### Pre-review Audit (implement)
- New mandatory audit before final review: counts implementers dispatched, code reviews completed, security reviews dispatched
- Detects discrepancies (bundled tasks, skipped reviews, missing security dispatches) and blocks final review until fixed

#### Anti-bundling post-hoc verification (implement)
- HARD-GATE now includes post-hoc count check: implementer agents dispatched must equal tasks in plan
- If fewer implementers were dispatched than tasks exist, the orchestrator must re-run the bundled tasks individually

## 1.1.1 (2026-03-16)

### Remove technology-specific examples
- Replaced all Kubernetes/infra-specific examples (Kustomize, Helm, ArgoCD, Cilium, ConfigMap, ServiceMonitor, cert-manager) with technology-agnostic equivalents across all skills and agents
- Examples now use generic patterns (Express, PostgreSQL, React, auth middleware, API routes) that apply to any stack
- Affected files: ship/SKILL.md, plan/SKILL.md, implement/SKILL.md, researcher-doc.md, spec-reviewer.md, COMPARISON-vs-SUPERPOWERS.md

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
