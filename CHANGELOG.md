# Changelog

## 3.1.0 (2026-04-02)

### Targeted persuasion mechanisms for LLM compliance

- feat: add hybrid Red Flags / Rationalization tables to 6 core files — `implementer`, `critic`, `verify`, `plan`, `implement`, `debug`
- feat: elevate `verify` "The Gate" to named Iron Law with code-block preamble and letter/spirit inoculation
- feat: elevate `debug` "Philosophy" to named Iron Law with code-block preamble and letter/spirit inoculation
- feat: add letter/spirit inoculation to `implementer` TDD Iron Rule
- feat: add non-TDD Red Flags table to `implementer` agent (validation skip, scope creep, report honesty)
- feat: add anti-complacency Red Flags table to `critic` agent (rubber-stamping, premature approval)
- feat: CSO-optimized skill descriptions — 7 skills rewritten from process-focused to trigger-focused (`plan`, `implement`, `debug`, `do`, `refactor`, `ship`, `full`)
- docs: design spec at `docs/specs/2026-04-02-persuasion-mechanisms-design.md`

## 3.0.0 (2026-03-30)

### OpenCode compatibility + skill renaming + internal refactoring

- **BREAKING**: all skill names renamed from `ops:*` to `ops-*` for cross-platform filename compatibility (e.g., `/ops:plan` → `/ops-plan`)
- feat: OpenCode support via `.opencode/plugins/ops.js` (plugin ESM) with dynamic slash command registration
- feat: `package.json` added for OpenCode git-based plugin installation
- feat: `AGENTS.md` as primary project instructions (OpenCode native), `CLAUDE.md` now points to it via `@AGENTS.md`
- refactor: CLI-agnostic project instruction references — all skills and agents now reference `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (whichever exists) instead of hardcoded `CLAUDE.md`
- feat: `data/bootstrap-context.md` — shared skill routing table read by both Claude Code and OpenCode adapters
- feat: `.opencode/INSTALL.md` with installation instructions
- refactor: `hooks/session-start` reads `data/bootstrap-context.md` instead of hardcoded HEREDOC
- refactor: all cross-references, hook routing table, agent descriptions, README updated from `ops:*` to `ops-*`
- deleted: `COMPARISON-vs-SUPERPOWERS.md` (removed)
- refactor: `ops-init` CLI-agnostic redesign — CLI detection script, shared entry point, per-CLI sub-skills (Claude Code + OpenCode)
- refactor: extract shared review sequence (code quality → security gate → code review → project instruction check) into `ops-review-pipeline` internal skill — eliminates duplication across `do`, `perf`, `refactor`, and `test`
- refactor: `ops-plan` Step 0 no longer runs full `ops-init` — limited to project command discovery (build/test/lint), with environment health check that proposes `/ops-init` if issues detected
- refactor: `ops-init` simplified to single mode (user-invoked only), removed dual plan/user-invoked mode
- fix: clarify project instruction file locations as "at the project root" in `instruction-priority`, `review-pr`, `security`, and `review-pipeline` — prevents agents from searching user-level directories
- feat: `/ops-audit` — full codebase audit (qlty + semgrep), unified report with cross-triage and severity classification
- feat: duplication checks in `ops-plan` Step 5 (Reuse criterion) and critic Lens 1
- fix: remove dead semgrep baseline scan from `ops-init` (`.semgrep/baseline.json` was generated but never consumed)
- feat: `ops-init` restructured into 6 phases with stop-and-propose — recap (skills/agents/MCP), ops tools (qlty/semgrep), project linters, linter prerequisites, build tools, LSP
- feat: language rule in `ops-instruction-priority` — respond in the user's language
- feat: spec status lifecycle (`Draft` → `Approved` → `Implemented`) across `ops-plan` and `ops-implement`
- feat: `ops-do` scope guard redirects to `/ops-brainstorm` instead of `/ops-plan`
- feat: OpenCode agent registration via plugin `config.agent` hook — all 11 ops agents available as subagents
- feat: build verification step in `ops-review-pipeline` — propose compile/build before code review
- feat: LSP usage guidance in `ops-subagent-rules` — all agents prefer LSP over grep for code navigation
- fix: semgrep config — do not create `.semgrep.yml` (`--config auto` provides community rules)
- feat: English-only rule in `AGENTS.md` for the ops repository

## 2.3.4 (2026-03-30)

### Reasoning effort baselines for all agents

- feat: added `effort` frontmatter to all 11 agent definitions — opus agents default to `high`, sonnet agents (researcher-doc, git-historian) default to `medium`
- feat: added effort baseline rule to `ops:subagent-rules` — respect agent defaults, prefer lowering for mechanical subtasks
- docs: README agents table now includes Model and Effort columns

## 2.3.3 (2026-03-30)

### ops:plan — Lightweight intent clarification replaces built-in brainstorm

- refactor: replaced Step 1 full brainstorm process (~120 lines, 9 sub-steps) with lightweight intent clarification (~40 lines, 3 sub-steps: clarity check, scope check, offer `/ops:brainstorm`)
- removed: embedded brainstorm checklist, visual companion offer, YAGNI filter, design-by-sections, approach proposals — all now exclusive to `/ops:brainstorm`
- added: explicit suggestion to invoke `/ops:brainstorm` when the problem space is ambiguous
- renamed: gate block from "Brainstorm Complete" to "Intent Confirmed"
- updated: all internal references (workflow summary, hard gates, overview, research scoping) from "brainstorm" to "clarify intent"

## 2.3.2 (2026-03-30)

### ops:plan — Prompt consolidation (545 → 473 lines, -13%)

- refactor: removed graphviz diagram from Step 1 (-52 lines) — fully redundant with checklist + prose
- refactor: condensed "Proposing 2-3 approaches" in Step 1 to 2 lines (detail lives in Step 5)
- refactor: condensed "Presenting design by sections" in Step 1 to 2 lines (detail lives in Step 6a)
- refactor: merged duplicate dependency gates in Step 5 into single gate preserving content constraint, workflow sequencing, and consequence language
- refactor: condensed verbose prose in Step 1 — clarity check, clarifying questions, working in codebases
- refactor: removed 3 doubly-enforced emphasis instances (already covered by HARD-GATE tags or consequence language)

## 2.3.1 (2026-03-30)

### ops:plan — No-placeholders rule + TDD granularity

- feat: "No Placeholders" section — explicit list of plan anti-patterns (TBD, "similar to Task N", "add appropriate error handling", etc.)
- feat: TDD granularity rule — tasks should follow micro-cycle (write failing test → run → implement → run → commit) when applicable

### ops:implement — Model selection guidance

- feat: model selection guidance for implementer agents — mechanical tasks use fast models (sonnet/haiku), integration tasks use sonnet, architecture/judgment tasks use the default model
- Reduces cost and increases speed for well-specified tasks

## 2.3.0 (2026-03-30)

### ops:brainstorm — Richer brainstorming process (inspired by superpowers analysis)

- feat: new Step 7 "Propose 2-3 approaches" — present trade-offs and recommendation, wait for user choice before proceeding
- feat: new Step 8 "Present design by sections" — each section validated individually by the user before moving to the next
- feat: task tracking throughout brainstorming — 9 tasks created and tracked for progress visibility
- feat: Step 11 transition — direct offer to launch `/ops:plan`, skipping redundant re-brainstorming
- refactor: workflow expanded from 7 steps to 11

### ops:plan — Brainstorm phase alignment + validation improvements

- feat: Step 1 checklist expanded with "Propose 2-3 approaches" and "Present design by sections"
- feat: Step 1 detects if `/ops:brainstorm` was already run and skips to Step 2 with recap
- feat: Step 6a changed to section-by-section design validation with user approval per section
- feat: Brainstorm Complete gate block now tracks approach chosen and design sections validated
- fix: process flow (graphviz) updated with approach proposal and section validation loops
- fix: LSP diagnostics added to validation gate table in implement skill (Step 2b)
- fix: new Step 0b discovers project test/build commands (Makefile, bin/, package.json) for task validation
- fix: critic REJECT loop requires updating task breakdown to reflect spec changes from review loops

## 2.2.5 (2026-03-30)

### ops:plan — Hardened workflow gates (7 improvements)

- fix: new `HARD-GATE-HANDOFF` at Step 9 — `/ops:plan` NEVER implements code inline; user's "implemente" triggers `/ops:implement` as a separate skill invocation
- fix: critic REJECT now requires structured `## Critic Re-verification` output block before re-dispatch — prevents silent bypass of mandatory re-dispatch
- fix: `HARD-GATE-1` now forbids ALL agent types after Step 0 (was "research agent" only — Explore agents slipped through)
- feat: new Step 0b with mandatory `## Discovered Commands` output — task validation commands must use real project commands, not generic ones
- feat: mandatory `## Brainstorm Complete` exit summary before Step 2 — enforces visual companion evaluation and YAGNI check completion
- fix: Step 6a simplified — removed section-by-section approval requirement (redundant with spec-reviewer loop), keeps design presentation conversational
- fix: Step 9 now presents 3 explicit options (launch implement / review first / implement later) instead of open-ended question

## 2.2.4 (2026-03-24)

### ops:do — Workflow hardening

- fix: Step 1 restatement is now a gate (waits for user approval), with option to escalate to `/ops:brainstorm`
- fix: Step 4 task format requires executable shell validation commands, not prose descriptions
- fix: Step 6 code-quality now explicitly references skill file Steps 1–6 and handles missing tools gracefully (no brute-force retries)
- fix: Step 7 security-gate references `ops-semgrep-scan.sh` and its key=value output format (aligns with v2.2.3 script extraction)
- fix: Step 7 re-dispatch now includes both code-reviewer and security-reviewer when both found issues

## 2.2.3 (2026-03-24)

### Architecture — Script extraction

- feat: new `scripts/ops-semgrep-scan.sh` — encapsulates SAST scanning logic (config detection, diff-aware baseline, JSON parsing, error handling) previously described as LLM prompt prose
- feat: `hooks/session-start` derives `CLAUDE_PLUGIN_ROOT` and adds `scripts/` to PATH for direct script access (scripts prefixed `ops-` to avoid namespace collisions)
- dropped: `scripts/detect-tools.sh` concept — formatter/linter detection delegated to the LLM instead of a finite script; qlty/semgrep binary checks remain in respective skills

### ops:implement — Prose tightening

- chore: tightened implement skill prose (no semantic change)
- fix: `PROJECT_ROOT` in `ops-semgrep-scan.sh` now uses `git rev-parse --show-toplevel` instead of defaulting to CWD
- fix: file list detection in `ops-semgrep-scan.sh` now includes untracked files via `git ls-files --others --exclude-standard`

### ops:code-quality — Simplified tool detection

- refactor: tool detection (Step 1) now relies on LLM examination of project config files instead of a hardcoded tool list

### ops:security-gate — Script-based SAST

- refactor: semgrep invocation delegated to `ops-semgrep-scan.sh`, called directly from PATH
- feat: new `status=findings_unknown` when no JSON parser available — LLM parses raw JSON instead of relying on lossy grep fallback

### ops:setup — JSON parser diagnostic

- feat: Category 3 now detects `jq` / `python3` availability for semgrep result parsing

### Bug fixes (ops-semgrep-scan.sh)

- fix: paths with spaces handled correctly (array-based command construction)
- fix: semgrep stderr captured to temp file for diagnostics instead of being silently suppressed

## 2.2.2 (2026-03-23)

### ops:code-quality — Structural analysis (smells + metrics)

- feat: new Step 4 "Smells" — runs `qlty smells` on modified files to detect duplication, high cyclomatic complexity, and other structural issues
- Distinguishes new vs pre-existing smells: only flags issues introduced by the current work
- feat: new Step 5 "Metrics" — runs `qlty metrics --functions` on modified files, reports only functions exceeding thresholds (cognitive > 15, cyclomatic > 20)
- feat: security findings passthrough — qlty security plugin findings (trivy, trufflehog, osv-scanner, bandit, checkov) are forwarded to `ops:security-gate` instead of being handled in code-quality
- Steps renumbered: Report is now Step 6
- Report output updated with Smells, Metrics, and Security findings lines

### ops:security-gate — Diff-aware SAST + qlty integration

- feat: diff-aware semgrep scanning via `--baseline-commit` — only reports new findings, not pre-existing ones
- feat: baseline detection logic: feature branch → `git merge-base HEAD main`, main branch → `HEAD~1`, fallback documented
- fix: empty semgrep config handling — `.semgrep.yml` with `rules: []` now falls back to `--config auto`
- feat: new Step 1c — incorporates security findings from qlty into triage decision
- Dispatch decision now considers three signal sources: trigger triage + semgrep + qlty

### ops:implement — Traceable validation pipeline

- fix: Task Completion Record (Step 2e) now lists multiple validation commands instead of a single line
- fix: added explicit note linking per-task validation commands to final validation aggregation
- fix: Final validation (Step 5) expanded from one-liner to structured 5-step process: scan → deduplicate → expand scope → execute → report
- feat: Final Validation Checklist template with task attribution per command
- Security triage output now includes SAST and qlty security findings lines

### ops:debug — Aligned review pipeline

- fix: Step 5 restructured to follow the same sequence as ops:implement: Code Quality → Security Gate → Code Review

## 2.2.1 (2026-03-23)

### /ops:setup — Piebald-AI marketplace removal

- fix: removed `Piebald-AI/claude-code-lsps` third-party marketplace and all associated plugins (HTML/CSS, Vue, Scala, PowerShell, Julia, LaTeX, Ada, Solidity)
- Marketplace count reduced from 3 to 2 (`claude-plugins-official` + `boostvolt/claude-code-lsps`)
- Glob file extension list trimmed to match remaining marketplace coverage

### /ops:setup — MCP Servers diagnostic (Category 4)

- feat: new Category 4 "MCP Servers" in `/ops:setup` — checks `context7` and `chrome-devtools-mcp` plugin availability
- Verifies `enabledPlugins` and `extraKnownMarketplaces` in `~/.claude/settings.json`
- Grouped installation prompt (marketplace + plugin) with A/B/C options
- All "Categories 2-3" references updated to "Categories 2-4" across setup, plan, README

### /ops:debug — Browser Bug Triage (Step 0)

- feat: new Step 0 "Browser Bug Triage" in `/ops:debug` — routes to `chrome-devtools-mcp` skills for browser/frontend bugs

### /ops:plan — Spec no longer auto-committed

- fix: `/ops:plan` no longer commits the spec automatically — the user decides when to commit (via `/ops:ship` or manually)

### Cross-cutting updates

- README.md: updated setup description, requirements (added chrome-devtools-mcp), setup detail table, mermaid diagram

## 2.2.0 (2026-03-23)

### New skill: /ops:setup

- feat: new `/ops:setup` skill — diagnose environment (languages, LSP, code quality tools, security analysis tools) and propose installation for missing tools
- Absorbs `ops:environment-setup` internal phase — all language detection, 4-level LSP diagnostic, marketplace/plugin/binary tables migrated
- Two entry modes: user-invoked (full diagnostic + install proposals) or called by `/ops:plan` Step 0 (Categories 2-3 informational only)
- Detects qlty (unified code quality), semgrep (SAST), and project-specific formatters/linters

### qlty integration in code-quality

- feat: `ops:code-quality` now detects qlty as a priority unified tool — if `qlty` is in PATH and `.qlty/qlty.toml` exists, uses `qlty fmt` and `qlty check` instead of individual formatters/linters
- Two-stage detection: qlty in PATH + `.qlty/qlty.toml` present → use qlty; otherwise → fallback to individual tools
- Crash/timeout resilience: if qlty fails, logs error and continues with fallback
- Report now mentions `/ops:setup` when no tools are detected

### Semgrep integration in security-gate

- feat: new Step 1b in `ops:security-gate` — optional SAST scan with `semgrep scan --config auto --json` on modified files
- Gate-level triage of semgrep findings: LLM evaluates each finding in context of the diff before dispatching — obvious false positives are dismissed without consuming a security-reviewer cycle
- Security Triage output now includes SAST line (findings count / clean / not found / error)
- Crash/timeout/network resilience: if semgrep fails, logs error and continues with LLM triage only

### New file: mise.toml

- feat: `mise.toml` at repo root declares pipx, qlty (`github:qltysh/qlty`), and semgrep (`pipx:semgrep`) as development dependencies for ops contributors

### Cross-cutting updates

- skills/plan/SKILL.md: HARD-GATE-0 updated to reference `ops:setup` instead of prescriptive Glob/ToolSearch/LSP sequence; Step 0a reference changed from `ops:environment-setup` to `ops:setup`
- hooks/session-start: added `/ops:setup` to routing table and routing hints
- README.md: added `/ops:setup` to quick use, workflow diagram, standalone skills table, skills reference; updated code-quality and security-gate descriptions; added qlty and semgrep to requirements; updated structure tree
- .claude-plugin/plugin.json: version bump 2.1.1 → 2.2.0, added setup to description

### Removed

- `ops:environment-setup` internal phase — absorbed into `/ops:setup`

### Stats
- Skills: 17 user-facing + 7 internal phases = 24 total (was 16 + 8 = 24)
- Agents: 11 (unchanged)

## 2.1.1 (2026-03-23)

### Documentation

- docs: workflow and agent dispatch diagrams in README — global workflow diagram, per-skill agent dispatch map (LR layout with agents grouped by role), and individual mermaid diagrams for each skill showing the complete pipeline with agents as hexagonal nodes

### Skill hardening

- fix(implement): add hard gate for validation ownership — orchestrator must run validation commands, not rely on implementer's report
- fix(implement): add hard gate for code-quality ordering — must run before dispatching reviewers
- fix(implement): require structured security triage output (14-trigger checklist) before dispatch decision
- fix(implement): add hard gate for final validation — all commands from all tasks, explicit gap reporting
- fix(implement): strengthen TaskList consistency check — flag anomalies instead of silently proceeding
- fix(plan): require YAGNI assessment block in output before proceeding to research
- fix(plan): add hard gate for research dispatch — enforce exactly 3 typed agents in a single message

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
