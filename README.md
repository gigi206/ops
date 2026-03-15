# ops

A structured development workflow plugin for Claude Code. Plan, implement, debug, review, and ship with discipline.

## What it does

ops enforces a staged workflow with explicit gates, parallel research, adversarial review, and evidence-based verification. Every claim requires proof. Every major step requires review.

### Workflow

```
/ops:plan → /ops:implement → /ops:ship
                ↑
           /ops:debug (when bugs arise)
```

- **`/ops:plan`** — Brainstorm with user, run parallel research (3 agents), write spec, decompose into tasks, adversarial critic review, user approval
- **`/ops:implement`** — Execute tasks one by one via implementer agent, validation gates, conformity checks, code review, security escalation, circuit breakers
- **`/ops:debug`** — Systematic root-cause investigation: hypothesize, test, fix, verify. Circuit breaker at 5 failed attempts
- **`/ops:review`** — Evaluate code review feedback technically before acting. No performative agreement.
- **`/ops:ship`** — Run all validations, summarize changes, commit, optional PR, capture learnings, propose `.claude/rules/` from recurring lessons
- **`/ops:verify`** — Behavioral skill (always active): never claim success without showing evidence

### Agents

| Agent | Model | Role |
|-------|-------|------|
| **researcher-code** | Opus | Codebase patterns, conventions, architecture, risks |
| **researcher-doc** | Sonnet | External docs via Context7 MCP (fallback: web search) |
| **git-historian** | Sonnet | Commit timeline, regressions, ownership, hotspots |
| **critic** | Opus | Adversarial plan review (4 lenses, 3 perspectives, self-audit) |
| **spec-reviewer** | Sonnet | Spec completeness (7 dimensions) |
| **implementer** | Sonnet | Task execution with TDD, validation, reporting |
| **code-reviewer** | Sonnet | LSP diagnostics, spec compliance, code quality, security scan |
| **security-reviewer** | Sonnet | Deep security analysis for auth/API/secrets/TLS code |

## Install

### As a Claude Code plugin (recommended)

```bash
# From any project directory
claude /plugin install ~/ops
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

### Plan before coding

```
/ops:plan add rate limiting to the API endpoints
```

This will:
1. Brainstorm the design with you (Socratic-style, one question at a time)
2. Detect project languages and check LSP availability
3. Spawn 3 research agents in parallel (docs, codebase, git history)
4. Propose 2-3 approaches with tradeoffs
5. Write and review a spec document
6. Decompose into ordered tasks with validation commands
7. Run adversarial critic review
8. Wait for your approval

### Implement the plan

```
/ops:implement
```

For each task:
1. Implementer agent executes the task (with TDD if tests are relevant)
2. Validation gate (run commands, show output)
3. Conformity check (no drift, no secrets, conventions preserved)
4. Code review (LSP + spec compliance + security scan)
5. Discovery check (pause on significant findings)

Circuit breaker: 3+ consecutive failures triggers diagnostic agents and presents options.

### Debug a problem

```
/ops:debug the webhook handler returns 500 on empty payloads
```

Systematic investigation: reproduce, instrument, hypothesize (max 3), test, fix, code review, verify.

### Ship the work

```
/ops:ship
```

Run all validations, summarize changes, propose commit message, optional PR, capture learnings. Si un learning est récurrent et ciblable par glob, propose de le transformer en `.claude/rules/` (avec validation utilisateur).

### Handle code review feedback

```
/ops:review
```

Evaluate feedback technically. If correct, fix with evidence. If incorrect, push back with evidence.

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
├── commands/                    # 6 slash commands
│   ├── debug.md
│   ├── implement.md
│   ├── plan.md
│   ├── review.md
│   ├── ship.md
│   └── verify.md
├── hooks/
│   ├── hooks.json               # SessionStart hook config
│   └── session-start            # Injects skill routing context
├── skills/                      # 6 workflow skills
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
│   ├── ship/SKILL.md
│   └── verify/SKILL.md
└── LICENSE
```

## License

MIT — Ghislain LE MEUR. Incorporates code from [superpowers](https://github.com/obra/superpowers) (Jesse Vincent, MIT).
