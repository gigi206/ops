# ops

A structured development workflow plugin for Claude Code. Plan, implement, debug, review, secure, and ship with discipline.

## What it does

ops enforces a staged workflow with explicit gates, parallel research, adversarial review, and evidence-based verification. Every claim requires proof. Every major step requires review.

### Workflow

```
/ops:plan → /ops:implement → /ops:ship
                ↑                ↑
           /ops:debug       /ops:security
         (when bugs arise)  (audit on demand)
```

- **`/ops:plan`** — Brainstorm with user, run parallel research (3 agents), write spec, decompose into tasks, adversarial critic review, user approval
- **`/ops:implement`** — Execute tasks one by one via implementer agent, validation gates, conformity checks, code review, security escalation, circuit breakers
- **`/ops:debug`** — Systematic root-cause investigation: hypothesize, test, fix, verify. Circuit breaker at 5 failed attempts
- **`/ops:review`** — Evaluate code review feedback technically before acting. No performative agreement.
- **`/ops:security`** — On-demand security review of code, infrastructure, or pipeline changes
- **`/ops:ship`** — Run all validations, summarize changes, commit, optional PR, capture learnings, propose `.claude/rules/` from recurring lessons
- **`/ops:verify`** — Behavioral skill (always active): never claim success without showing evidence

### Agents

| Agent | Model | Role |
|-------|-------|------|
| **researcher-code** | Opus | Codebase patterns, conventions, architecture, risks |
| **researcher-doc** | Sonnet | External docs via Context7 MCP (fallback: web search) |
| **git-historian** | Sonnet | Commit timeline, regressions, ownership, hotspots |
| **critic** | Opus | Adversarial plan review (4 lenses, 3 perspectives, self-audit) |
| **spec-reviewer** | Opus | Spec completeness (7 dimensions) |
| **implementer** | Opus | Task execution with TDD, validation, reporting |
| **code-reviewer** | Opus | LSP diagnostics, spec compliance, code quality, security scan |
| **security-reviewer** | Opus | Deep security analysis — code, infra, CI/CD, supply chain, runtime, policy |

## Install

### Prerequisites

The plugin system requires a **marketplace** to be configured first:

```
/plugin marketplace add gigi206/ops
```

### As a Claude Code plugin (recommended)

```
/plugin install ~/ops
```

### Manual

Symlink or copy the `ops/` directory into your Claude Code plugins path:

```bash
ln -s ~/ops ~/.claude/plugins/ops
```

Restart Claude Code after installing.

### Verify

After install, type `/ops:plan` in Claude Code. If the skill loads, you're set.

## Requirements

- **Claude Code** — required
- **Node.js** — only needed for the visual brainstorm companion (optional)
- **Git** — needed by the git-historian agent (optional, skipped if unavailable)
- **Context7 MCP** — needed by researcher-doc (optional, falls back to web search)

No npm dependencies. No database. No compiled binaries.

## Usage

### Quick start

```
/ops:plan add rate limiting to the API endpoints
```

After the plan is approved:

```
/ops:implement
```

When done:

```
/ops:ship
```

### Tips

- **Unknown library or tool?** — If ops encounters a library, tool, or external application it doesn't fully understand, it can `git clone` the source code into a temporary directory to read and analyze it directly. This is a last resort — ops will first try Context7 MCP and web search before cloning.

## Skills Reference

### `/ops:plan`

Brainstorm, research, and plan before writing code.

```
/ops:plan <description of what you want to do>
```

| Step | What happens |
|------|-------------|
| Brainstorm | Socratic-style design discussion — one question at a time |
| Context detection | Detect languages, check LSP availability, read project conventions |
| Parallel research | 3 agents in parallel: researcher-doc, researcher-code, git-historian |
| Research adequacy | Evidence table presented to user — gaps trigger follow-up research |
| Design approaches | 2-3 options with pros/cons, recommendation first |
| Spec writing | Design document written, reviewed by spec-reviewer, approved by user |
| Task decomposition | Ordered tasks with files, changes, and validation commands |
| Critic review | Adversarial review (4 lenses, 3 perspectives, self-audit) |
| User approval | Plan presented for final approval before implementation |

Agents used: **researcher-code**, **researcher-doc**, **git-historian**, **spec-reviewer**, **critic**

---

### `/ops:implement`

Execute a validated plan task by task.

```
/ops:implement
```

Prerequisite: a plan from `/ops:plan` or user-provided.

Each task goes through the full pipeline:

| Step | What happens |
|------|-------------|
| Implementer | One agent per task, TDD enforced when tests are relevant |
| Validation gate | Run validation commands, show output — no "it should work" |
| Conformity check | Diff vs. plan — no drift, no secrets, conventions preserved |
| Code review | LSP diagnostics, spec compliance, code quality, security scan |
| Security review | **Mandatory** if the task touches security-sensitive areas (see below) |
| Discovery check | Pause on significant findings, stop on major discoveries |

After all tasks: final review of the entire implementation (code-reviewer + security-reviewer if applicable).

**Security escalation triggers** — the security-reviewer is dispatched when the task touches:

- Authentication, authorization, or identity federation
- APIs or interfaces exposed beyond the trust boundary
- Secrets, credentials, keys, or tokens
- Encryption or certificate configuration
- User input handling or data validation
- Access control rules or permission models
- Network exposure, firewall rules, or traffic policies
- Infrastructure definitions (IaC)
- CI/CD pipeline configuration
- Container, VM, or runtime privileges
- Dependencies or supply chain changes
- Policy enforcement or compliance rules
- Data storage, retention, or backup configuration
- Logging, audit, or observability configuration

**Circuit breaker**: 3+ consecutive failures triggers diagnostic agents (researcher-code + git-historian) and presents options to the user.

Agents used: **implementer**, **code-reviewer**, **security-reviewer** (when applicable)

---

### `/ops:debug`

Systematic debugging: investigate, hypothesize, fix.

```
/ops:debug <description of the problem>
```

| Step | What happens |
|------|-------------|
| Investigate | Read errors, reproduce, dispatch git-historian for recent changes |
| Instrument | Add temporary logging at component boundaries (multi-component bugs only) |
| Hypothesize | Max 3 hypotheses with supporting evidence and disproof criteria |
| Test | Confirm or refute each hypothesis with minimal tests |
| Fix | Minimal fix addressing root cause, not symptoms |
| Code review | Same pipeline as `/ops:implement` including security escalation |
| Discovery check | Pause if the bug is broader than diagnosed |
| Verify | Original failing command passes, no regressions — show proof |

**Circuit breaker**: 5+ failed fix attempts triggers diagnostic agents and presents options.

Agents used: **git-historian**, **code-reviewer**, **security-reviewer** (when applicable), **researcher-code** (circuit breaker)

---

### `/ops:security`

On-demand security review of code, infrastructure, or pipeline changes.

```
/ops:security                     # staged + unstaged changes
/ops:security path/to/file        # specific file or directory
/ops:security --branch            # current branch vs. base branch
/ops:security --commit <ref>      # specific commit
```

| Step | What happens |
|------|-------------|
| Scope | Determine what to review based on arguments |
| Triage | Identify which security domains are touched |
| Review | Dispatch security-reviewer with scoped diff and context |
| Report | Present findings with attack scenarios and fix recommendations |
| Fix (optional) | Apply fixes if requested, re-verify with security-reviewer |

If no security-sensitive areas are found, reports that and offers to run anyway.

Agents used: **security-reviewer**

---

### `/ops:review`

Evaluate code review feedback technically before acting.

```
/ops:review
```

Use when you receive feedback from a human reviewer, CI check, or code-reviewer agent.

| Feedback type | Response |
|---------------|----------|
| Factual ("bug on line 42") | Reproduce, confirm or refute with evidence |
| Style ("use X pattern") | Check project conventions first, then evaluate on merit |
| Architectural ("restructure this") | Evaluate against spec, discuss before changing |
| Security ("vulnerable to X") | Always take seriously, verify attack vector, fix if confirmed |

Rules: no performative agreement, no silent ignoring, no unverified changes. Push back with evidence when feedback is incorrect.

---

### `/ops:ship`

Commit, PR, and capture learnings.

```
/ops:ship
```

| Step | What happens |
|------|-------------|
| Verify | Run all validation commands, linters, tests |
| Summarize | Files modified/created, what was done, deviations from plan |
| Commit | Stage specific files, propose message, wait for approval |
| PR (optional) | Push and create PR if requested |
| Learnings | Problems solved, decisions made, gotchas, patterns that worked |
| Rule proposals | Recurring learnings proposed as `.claude/rules/` (with user approval) |

Rules: never commit secrets, never push without approval, never skip validation.

---

### `/ops:verify`

Evidence before claims. Always active — not a workflow, a behavioral rule.

This skill is **always on** across all other skills and outside of ops. It enforces one rule: **never claim a result without showing the evidence.**

| Claim | Required evidence |
|-------|-------------------|
| "Tests pass" | Test command output showing 0 failures |
| "Build succeeds" | Build command output with exit code 0 |
| "No lint errors" | Linter output showing 0 warnings/errors |
| "Fix works" | Original failing command now succeeds |
| "Deploy succeeded" | Status command showing healthy state |

Red flags: "should", "probably", "seems to", "I believe" — if these appear instead of command output, the claim is unverified.

## Design Principles

- **Evidence before claims** — `verify` is always active. No "it should work".
- **Parallel research** — 3 agents run simultaneously during planning.
- **Adversarial review** — the critic agent tries to break your plan before you build it.
- **Circuit breakers** — repeated failures escalate to diagnostics, not infinite retries.
- **Instruction priority** — user > CLAUDE.md > ops > system defaults. Conflicts resolved explicitly.
- **TDD enforced** — the implementer follows Red-Green-Refactor with anti-rationalization gates and a deletion rule for code written before tests.
- **Minimal hooks** — one SessionStart hook injects skill awareness. No keyword detection, no prompt interception, no hidden automation.
- **Lightweight** — 240 KB, pure documentation + a small brainstorm server. No npm deps, no database, no compiled code.

## Structure

```
ops/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/                      # 8 specialized agents
│   ├── code-reviewer.md
│   ├── critic.md
│   ├── git-historian.md
│   ├── implementer.md
│   ├── researcher-code.md
│   ├── researcher-doc.md
│   ├── security-reviewer.md
│   └── spec-reviewer.md
├── hooks/
│   ├── hooks.json               # SessionStart hook config
│   └── session-start            # Injects skill routing context
├── skills/                      # 7 workflow skills
│   ├── debug/SKILL.md
│   ├── implement/
│   │   ├── SKILL.md
│   │   ├── tdd-reference.md         # Full TDD methodology
│   │   └── testing-anti-patterns.md  # Mock anti-patterns
│   ├── plan/
│   │   ├── SKILL.md
│   │   ├── visual-companion.md
│   │   └── scripts/            # Brainstorm WebSocket server
│   ├── review/SKILL.md
│   ├── security/SKILL.md
│   ├── ship/SKILL.md
│   └── verify/SKILL.md
└── LICENSE
```

## License

MIT — Ghislain LE MEUR. Incorporates code from [superpowers](https://github.com/obra/superpowers) (Jesse Vincent, MIT).
