---
name: ops-init
description: "Diagnose environment: ops recap, qlty/semgrep, project linters, linter prerequisites, build tools, LSP. Propose installation for missing tools."
---

# /ops-init — Environment Diagnostic & Tool Setup

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Workflow

```
0. Bootstrap (language + CLI + languages + package managers) → 1. Recap (skills, agents, MCP) → 2. Ops tools (qlty, semgrep) → 3. Project linters → 4. Linter prerequisites → 5. Build tools → 6. LSP
```

**Stop-and-propose rule**: if any phase detects missing or broken tools, **stop at the end of that phase**, present findings and propose solutions (A/B/C style). Wait for the user's decision before proceeding to the next phase. Do NOT batch all issues for the end. Do NOT combine multiple phases in a single message.

If nothing is missing in a phase, proceed directly to the next.

## Task tracking

Before starting, create one task per phase. Mark each task in_progress when starting it and completed when done. **Do not skip any phase.**

---

## Phase 0: Bootstrap

Your **very first action** must be to run `echo $LANG` via Bash. This determines the language for all output. Parse the result (e.g., `fr_FR.UTF-8` → French, `en_US.UTF-8` → English). **All subsequent output — diagnostics, tables, proposals, summaries — must be in that language.** Technical terms and tool names stay in English.

Then run the following checks in parallel:

### 0a. Detect CLI

Run `ops-detect-cli.sh` (it is on PATH) and parse the output.

- If `cli=unknown`:
  ```
  ⚠ Unsupported CLI. /ops-init is compatible with Claude Code and OpenCode only.
  Other ops skills may not work correctly with an unsupported CLI.
  ```
  Stop here. Do not run any diagnostic.
- If `cli=claude-code` or `cli=opencode`: note the result and continue.

### 0b. Detect Languages

Scan the codebase to identify the primary languages and frameworks. Use a **single** Glob call with combined extensions:

```
**/*.{py,ts,tsx,js,jsx,go,rs,java,rb,yaml,yml,sh,tf}
```

Do NOT glob each extension separately — that wastes tokens.

Also check config files that indicate the stack (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `Makefile`, etc.)

**Ansible detection:** if `.yaml`/`.yml` files exist, check for Ansible markers: `ansible.cfg`, `galaxy.yml`, `playbooks/`, `roles/`, `inventory/`, or YAML files containing `hosts:` + `tasks:` patterns.

### 0c. Detect Package Managers

**System**: `which apt`, `which dnf`, `which pacman`, `which apk`, `which zypper`.
**User-installed**: `which brew`, `which nix`, `which mise`, `which pipx`.

### 0d. Summary output

```
## Environment
- CLI: <claude-code / opencode> (vX.Y)
- Languages: <list>
- Package managers: <system: apt> <user: brew, mise>
```

---

## Phase 1: Recap

Show what ops provides in this environment.

### 1a. Skills

Count available skills by scanning the skills directory. Report: "**N skills** loaded" with a collapsed list if the user wants details.

### 1b. Agents

Count registered agents by scanning the `agents/` directory in the ops plugin root (same level as `skills/`). Each `.md` file is one agent. Report: "**N agents** registered".

On OpenCode: verify agents are actually available by listing the agent names the plugin registered via `config.agent`. If the count is 0 or lower than expected, note the registration failure.

### 1c. MCP Servers

Dispatch to the CLI-specific sub-skill for MCP diagnostic only:
- If `cli=claude-code`: follow the MCP section of `skills/init/claude-code.md` (Category 2)
- If `cli=opencode`: follow the MCP section of `skills/init/opencode.md` (Category 2)

Report the status of each MCP server. **If any MCP server is missing or broken, stop and propose solutions.** Wait for the user's decision before proceeding.

---

## Phase 2: Ops Tools (strongly recommended)

These tools power the review pipeline and security gate. Without them, several ops skills run in degraded mode.

### 2a. qlty

Check if `qlty` is available: `which qlty`
- If found: check for `.qlty/qlty.toml` in the project root.
  - Config present: report version (`qlty --version`), note as "installed + configured"
  - Config absent: report version, note as "installed — no project config"
- If not found: note as **missing (strongly recommended)**

### 2b. semgrep

Check if `semgrep` is available: `which semgrep`
- If found: report version (`semgrep --version`), note as "installed"
- If not found: note as **missing (strongly recommended)**

**Do NOT create a `.semgrep.yml` file.** `ops-semgrep-scan.sh` uses `--config auto` which provides semgrep's community rules — these are comprehensive and maintained. A custom config is only useful if the project has project-specific rules, and that is the user's responsibility.

### 2c. JSON parser (for semgrep)

`ops-semgrep-scan.sh` uses jq or python3 to count findings. Check: `which jq` or `which python3`. If neither, note it (not a blocker).

### Stop-and-propose

**Always stop here** if qlty is missing, semgrep is missing, **OR** qlty lacks project configuration (`.qlty/qlty.toml` absent). qlty without project config cannot detect the right plugins — `qlty init` is needed. semgrep without local config is fine (`--config auto` is the default).

```
## Ops Tools
- qlty: <status>
- semgrep: <status>
- JSON parser: <status>
```

Present issues and propose installation. **Only show install commands for package managers the user actually has** (from Phase 0c).

| Tool | Package manager | Install command |
|---|---|---|
| qlty | curl (always) | `curl https://qlty.sh \| bash` |
| qlty | brew | `brew tap qltysh/tap && brew install qlty` |
| qlty | mise | `mise install github:qltysh/qlty` |
| semgrep | pip | `pip install semgrep` |
| semgrep | pipx | `pipx install semgrep` |
| semgrep | brew | `brew install semgrep` |
| semgrep | mise | `mise install pipx && mise install pipx:semgrep` |
| jq | system | `apt/dnf/brew/pacman install jq` |

| Tool | Condition | Init command | Effect |
|---|---|---|---|
| qlty | installed but no `.qlty/qlty.toml` | `qlty init` | Creates `.qlty/qlty.toml` with auto-detected plugins |

Options:
> **A)** Install/configure everything (I run the commands for you)
> **B)** I'll handle it myself — here are the commands
> **C)** Skip — continue without these tools (degraded review pipeline)

Wait for the user's decision. For A: show commands before executing. Do NOT auto-install without consent.

---

## Phase 3: Project Linters

Detect linters and formatters configured in the project. Scan for config files:

- `package.json` → scripts and devDependencies (eslint, prettier, biome, etc.)
- `pyproject.toml` / `setup.cfg` → ruff, black, flake8, mypy, pylint
- `.eslintrc.*`, `.prettierrc.*`, `biome.json`, `.stylelintrc.*`
- `Cargo.toml` → clippy (built into cargo)
- `go.mod` → golangci-lint (check `.golangci.yml`)
- `.rubocop.yml` → rubocop
- `Makefile` → lint/format targets

For each detected linter, verify it is installed: `which <binary>`.

### Stop-and-propose

If any configured linter is not installed:

```
## Project Linters
| Linter | Config source | Installed | Fix |
|---|---|---|---|
| eslint | package.json | ✗ | npm install |
| ruff | pyproject.toml | ✓ | — |
| prettier | .prettierrc | ✗ | npm install |
```

> **A)** Install all missing linters (I run the install commands)
> **B)** I'll handle it myself
> **C)** Skip — continue without these linters

Wait for the user's decision.

---

## Phase 4: Linter Prerequisites

For each **installed** linter (from Phase 3), check that its runtime dependencies are met. This covers two levels:

### Level 1: Package/dependency environment

- **Node-based linters** (eslint, prettier, biome, stylelint): check `node_modules/` exists. If `package.json` exists but no `node_modules/`, propose install based on lockfile (`npm install` / `yarn install` / `pnpm install`).
- **Python projects**: check if dependencies are installed. Read `pyproject.toml` / `requirements.txt` to find declared dependencies. Check if they are importable (`python3 -c "import <pkg>"` for key packages) or if a venv/docker is used. Propose multiple options when applicable:
  - `pip install -r requirements.txt` (global)
  - `python -m venv .venv && .venv/bin/pip install -r requirements.txt` (venv)
  - `uv sync` (if uv is available)
  - docker-based (if Makefile/compose handles deps)
- **Go projects**: check `go.sum` exists. If `go.mod` but no `go.sum`, propose `go mod tidy`.
- **Ruby projects**: check `Gemfile.lock`. If `Gemfile` but no lock, propose `bundle install`.

### Level 2: Linter plugins and type stubs

- **mypy** → check for missing type stubs by examining mypy config (`mypy.ini`, `pyproject.toml [tool.mypy]`). Common stubs: `types-requests`, `django-stubs`, `types-pyyaml`, etc.
- **eslint** → check for referenced plugins in config that aren't in `node_modules/`
- **ruff/pylint** → check if the linted project's own packages are importable (linters need to resolve imports to lint correctly)

### Stop-and-propose

If any prerequisite is missing, **stop and propose solutions**. Present **multiple installation methods** when available — let the user choose:

```
## Linter Prerequisites
| Prerequisite | For | Status | Fix options |
|---|---|---|---|
| dependencies | ruff, mypy | missing | pip / venv / uv / docker |
| node_modules | eslint, prettier | missing | npm / yarn / pnpm |
| type stubs | mypy | missing | pip install types-xxx |
```

> **A)** Install with <recommended method> (I run the commands)
> **B)** Install with <alternative method>
> **C)** I'll handle it myself
> **D)** Skip

Wait for the user's decision.

---

## Phase 5: Build Tools

Detect build tools expected by the project and verify they are installed.

### Detection

Scan for project indicators:

| Indicator | Expected tool | Check |
|---|---|---|
| `tsconfig.json` | `tsc` (TypeScript compiler) | `which tsc` |
| `babel.config.*` / `.babelrc` | `babel` | `which babel` or in node_modules |
| `webpack.config.*` | `webpack` | in node_modules |
| `vite.config.*` | `vite` | in node_modules |
| `Makefile` | `make` | `which make` |
| `CMakeLists.txt` | `cmake` | `which cmake` |
| `Cargo.toml` | `cargo` | `which cargo` |
| `go.mod` | `go` | `which go` |
| `build.gradle*` | `gradle` / `./gradlew` | `which gradle` or `./gradlew` |
| `pom.xml` | `mvn` | `which mvn` |
| `Dockerfile` | `docker` | `which docker` |
| `docker-compose.*` | `docker compose` | `which docker` |

### Stop-and-propose

If any expected build tool is missing:

```
## Build Tools
| Tool | Expected by | Installed | Fix |
|---|---|---|---|
| tsc | tsconfig.json | ✗ | npm install -g typescript |
| make | Makefile | ✓ | — |
```

> **A)** Install all missing tools
> **B)** I'll handle it myself
> **C)** Skip

Wait for the user's decision.

---

## Phase 6: LSP

Dispatch to the CLI-specific sub-skill for LSP diagnostic:
- If `cli=claude-code`: follow the LSP section of `skills/init/claude-code.md` (Category 1)
- If `cli=opencode`: follow the LSP section of `skills/init/opencode.md` (Category 1)

The sub-skill handles diagnostic, table output, and interactive fix proposals (A/B/C/D). Follow its process entirely.

---

## Final Summary

After all phases are complete, present a final recap:

```
## Init Complete

| Phase | Status |
|---|---|
| Recap | N skills, N agents, N MCP |
| Ops tools | qlty ✓, semgrep ✓ |
| Project linters | N/N installed |
| Prerequisites | all met |
| Build tools | N/N installed |
| LSP | N/N languages working |
```

---

## Rules

- Only check languages actually found in the project (Phase 0b). Do NOT list the entire table.
- **Only show install commands for package managers the user actually has** (Phase 0c).
- Tools detected here are reported to the user but NOT passed to downstream skills. `ops-code-quality` and `ops-security-gate` re-detect independently — each skill must work standalone without prior setup.
- If nothing is missing across all phases, report "all tools available" and show only the final summary.
- Do NOT auto-install without consent. Always show commands before executing.
