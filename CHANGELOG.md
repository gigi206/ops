# Changelog

## 2.1.0 (2026-03-23)

### New agent: researcher-repo

- feat: new `researcher-repo` agent (Opus) — clones and analyzes external repositories (libraries, frameworks, applications, tools) when documentation and web research are insufficient
- Protocol: locate repo → detect version → shallow clone (version used) → analyze → optionally clone HEAD for comparison → structured report → cleanup
- Version-aware: clones the tag matching the project's dependency version, then optionally compares with HEAD/main
- Mandatory cleanup of cloned directories on completion (success or failure)

### New skill: /ops:clone-analyze

- feat: standalone skill for direct repository analysis — user invokes `/ops:clone-analyze <target>` to analyze an external repo
- 3-step workflow: Clarify → Dispatch researcher-repo → Present findings

### Conditional dispatch in /ops:research

- feat: `researcher-doc` now returns a `Source Verification Needed` list (per target: `high | low | none`) — signals which libraries/tools need source code analysis
- feat: `/ops:research` conditionally dispatches one or more `researcher-repo` agents in parallel for targets with `Needed: high`
- Workflow expanded from 4 steps to 6: Clarify → Parallel Research → Synthesize → Conditional Clone → Final Synthesize → Present

### Security

- fix: `--config core.hooksPath=/dev/null` on all `git clone` commands in researcher-repo — prevents execution of hooks from cloned repositories
- fix: `--config core.fsmonitor=false` on all `git clone` commands — prevents fsmonitor hook execution (CVE-2022-24765 vector)
- feat: post-clone `.gitattributes` filter audit — flags unknown filter drivers in the report

### Robustness

- feat: tag resolution via single `git ls-remote --tags --refs` call instead of 6 sequential clone attempts
- feat: pre-clone size guard via GitHub/GitLab API — abandons clone if repo exceeds 500 MB
- feat: added `pkg/v<version>` to tag resolution order for Go module repos

### Cross-cutting updates

- hooks/session-start: added `/ops:clone-analyze` to routing table
- skills/plan/SKILL.md: updated research delegation to mention parallel multi-target researcher-repo dispatch
- README.md: added researcher-repo agent, clone-analyze skill, updated counts (11 agents, 16 skills), added clone-analyze to Mermaid diagram
- agents/researcher-doc.md: documented that `Source Verification Needed` is consumed by `/ops:research` only

### Stats
- Agents: 10 → 11 (+researcher-repo)
- Skills: 15 → 16 user-facing (+clone-analyze)

## 2.0.1 (2026-03-21)

### Fixes from session 615af0fa analysis

#### Parallel dispatch enforcement (11 skills)
- fix: explicit "single message, multiple Agent tool_use blocks" rule in `ops:subagent-rules` — models were dispatching agents in separate messages (sequential) despite "in parallel" instructions
- fix: inline reminders at every parallel dispatch site (research, implement, do, test, perf, refactor, circuit-breaker, review-pr, debug)
- fix: `ops:subagent-rules` heading and description updated to reflect new parallelism scope

#### Spec commit sequencing (plan)
- fix: move spec git commit from Step 6b (before review) to Step 6d (after review loop) — previously, the committed version was stale if the spec-reviewer found issues
- fix: explicit `git add && git commit` instruction with guard: "Do NOT say committed unless git commit succeeded"

#### Visual Companion gate (plan)
- fix: add visual companion check to brainstorm gate — model must evaluate whether the topic involves visual questions before proceeding to context detection

#### Security transparency in spec review (plan)
- fix: security-related issues found by spec-reviewer must be presented to user before fixing — security decisions should be transparent, not silently resolved

#### Cross-reference and numbering fixes
- fix: `debug/SKILL.md` cross-reference corrected from `/ops:implement Step 2d` (Discovery Check) to `Step 4` (Final Review)
- fix: `implement/SKILL.md` Step 5 final validation marked MANDATORY with justification
- fix: `implement/SKILL.md` Step 5 duplicate numbering (two `3.`) corrected to sequential 1-2-3-4-5

## 2.0.0 (2026-03-20)

### Composable phases architecture

Extracted ~400 lines of duplicated content from 8 skills into 8 reusable internal phases. Skills now reference phases instead of inlining shared content.

#### New internal phases (`user-invocable: false`)
- `ops:instruction-priority` — instruction hierarchy (user > CLAUDE.md > ops skill > system prompt)
- `ops:subagent-rules` — context rules for dispatching subagents
- `ops:environment-setup` — language/framework detection + 4-level LSP diagnostic (test, marketplace, plugin, binary)
- `ops:code-quality` — format + lint modified files before code review
- `ops:discovery-checks` — Minor/Significant/Major discovery categorization
- `ops:circuit-breaker` — repeated failure diagnostic (researcher-code + git-historian)
- `ops:security-gate` — triage (14 triggers) + dispatch security-reviewer + re-verification loop (cap 3)
- `ops:redispatch-optimization` — generic re-dispatch prompt optimization pattern

#### New skills
- `/ops:research` — autonomous exploration: dispatches researcher-code + researcher-doc + git-historian in parallel
- `/ops:brainstorm` — interactive Socratic brainstorming extracted from /ops:plan Step 1
- `/ops:full` — meta-pipeline: chains /ops:plan → user approval → /ops:implement → /ops:ship
- `/ops:test` — add tests to existing untested code (dispatches test-writer agent)
- `/ops:refactor` — restructure code without changing behavior (coverage gate → incremental steps → verify)
- `/ops:perf` — performance investigation and optimization (baseline → profile → optimize → measure)
- `/ops:review-pr` — review external PRs (dispatches pr-reviewer agent + security-gate)

#### New agents
- `test-writer` — analyzes existing code and writes meaningful tests (behavior, not implementation)
- `pr-reviewer` — reviews external PRs with structured actionable comments

#### Refactored skills
- `/ops:plan` — removed inline instruction-priority, subagent-rules, environment-setup, lsp-setup, redispatch-optimization
- `/ops:implement` — removed inline instruction-priority, subagent-rules, discovery-checks, circuit-breaker, security-triage, security-redispatch, redispatch-optimization
- `/ops:do` — removed inline instruction-priority, subagent-rules, environment-setup, lsp-setup
- `/ops:debug` — removed inline instruction-priority, subagent-rules, discovery-checks, circuit-breaker
- `/ops:security` — removed inline instruction-priority, security-triage, security-redispatch
- `/ops:verify` — removed inline instruction-priority
- `/ops:review` — removed inline instruction-priority
- `/ops:ship` — removed inline instruction-priority

#### Harmonization
- Ansible detection added to `ops:environment-setup` (previously only in `/ops:plan` inline)
- Ansible LSP entry added to boostvolt marketplace table in `ops:environment-setup`
- Instruction-priority extracted into `ops:instruction-priority` phase and referenced from all 11 user-facing skills

#### Hook updated
- SessionStart routing table expanded: 15 entries (was 8) — added research, brainstorm, full, test, refactor, perf, review-pr

#### Stats
- Skills: 8 → 15 user-facing + 8 internal phases = 23 total
- Agents: 8 → 10 (+test-writer, +pr-reviewer)

## 1.6.1 (2026-03-20)

- feat: add Ansible LSP support (ansible-language-server via boostvolt/claude-code-lsps)
- feat: add Ansible-specific detection in Step 0a (ansible.cfg, galaxy.yml, roles/, playbooks/ markers)

## 1.6.0 (2026-03-19)

- feat: add `/ops:do` skill — lightweight structured workflow (research, execute, verify, review) for well-understood tasks

## 1.5.2 (2026-03-19)

- feat: optimize review agent re-dispatch prompts — re-dispatches now include previous findings + corrections instead of full context
- feat: standardize circuit breaker caps to 3 iterations — spec-reviewer stays at 3, critic 2→3, security-reviewer loops capped at 3
- feat: add re-dispatch loop for security-reviewer in implement and security skills (previously single conditional re-dispatch)

## 1.5.1 (2026-03-19)

- feat: add Terraform, Clojure, Dart, Elixir, Gleam, Nix, OCaml, Ruby, Zig LSP support (boostvolt/claude-code-lsps)
- feat: add Piebald-AI/claude-code-lsps as third marketplace (community) for HTML/CSS, Vue, Scala, PowerShell, Julia, LaTeX, Ada, Solidity
- fix: clarify HARD-GATE-0 wording — "do not ask design questions" instead of "do not talk to user"

## 1.5.0 (2026-03-18)

- feat: move language detection and LSP diagnostic to Step 0 (runs before brainstorming to catch restart-requiring issues early)

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
