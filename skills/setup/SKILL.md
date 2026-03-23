---
name: ops:setup
description: "Diagnose environment: languages, LSP, code quality tools (qlty), security analysis (semgrep). Propose installation for missing tools."
---

# /ops:setup — Environment Diagnostic & Tool Setup

## Two entry modes

1. **User-invoked** (`/ops:setup`): full diagnostic with installation proposals for all categories
2. **Called by `/ops:plan`** (Step 0): full diagnostic, but Categories 2-3 are **informational only** — report status without proposing installation. Category 1 retains full interactive behavior (A/B/C/D options).

## Step 0: Detect Package Managers

Before running diagnostics, detect available package managers. This determines which install commands to propose.

### Primary (system)

Check which system package manager is available: `which apt`, `which dnf`, `which pacman`, `which apk`, `which zypper`.

### Secondary (user-installed)

Check for additional package managers: `which brew`, `which nix`, `which mise`.

Note the results for the Recommendations section.

## Category 1: Languages & LSP

### Step 1: Detect Languages

Scan the codebase to identify the primary languages and frameworks:

- Use Glob to check for file extensions (e.g., `**/*.py`, `**/*.ts`, `**/*.go`, `**/*.rs`, `**/*.java`, `**/*.rb`, `**/*.yaml`, `**/*.sh`, `**/*.tf`, `**/*.clj`, `**/*.dart`, `**/*.ex`, `**/*.gleam`, `**/*.nix`, `**/*.ml`, `**/*.zig`, `**/*.html`, `**/*.css`, `**/*.vue`, `**/*.scala`, `**/*.ps1`, `**/*.jl`, `**/*.tex`, `**/*.adb`, `**/*.ads`, `**/*.sol`)
- **Ansible detection:** if `.yaml`/`.yml` files exist, check for Ansible markers: `ansible.cfg`, `galaxy.yml`, `playbooks/`, `roles/`, `inventory/`, or YAML files containing `hosts:` + `tasks:` patterns. If Ansible is detected, list it as a separate language from YAML.
- Read config files that indicate the stack (`package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `Gemfile`, `Makefile`, etc.)

Present the detected languages to the user (one line is enough, e.g., "Languages detected: Python, TypeScript, YAML").

### Step 2: Check LSP Availability

LSP (Language Server Protocol) gives the agent real diagnostics (type errors, missing imports, syntax issues) instead of guessing. It makes every agent in the pipeline smarter.

For each language detected in Step 1, work through 4 levels. Stop as soon as LSP works for that language.

#### Level 1: Test LSP per language

For each detected language, pick a representative file and call `LSP documentSymbol` on it.
- **If it returns symbols** → LSP is active for this language. Move on.
- **If it returns an error** (e.g., "no server available") → this language has no working LSP. **Continue to Level 2.**

Example: project has `.py`, `.sh`, `.yaml` files → test each:
```
LSP documentSymbol on src/main.py:1:1
LSP documentSymbol on scripts/deploy.sh:1:1
LSP documentSymbol on config/app.yaml:1:1
```

#### Level 2: Check marketplaces

The LSP plugins come from three marketplaces. Read `~/.claude/settings.json` → `extraKnownMarketplaces` to verify the user has the required one configured.

| Marketplace               | Repo                                  | Languages covered                                                                                    | Add command                                                  |
|---------------------------|---------------------------------------|------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `claude-plugins-official` | `anthropics/claude-plugins-official`  | TypeScript, Python, Go, Rust, C/C++, Java, C#, PHP, Swift, Kotlin, Lua                              | `/plugin marketplace add anthropics/claude-plugins-official` |
| `claude-code-lsps`        | `boostvolt/claude-code-lsps`          | Ansible, Bash/Shell, YAML, Terraform, Clojure, Dart/Flutter, Elixir, Gleam, Nix, OCaml, Ruby, Zig   | `/plugin marketplace add boostvolt/claude-code-lsps`         |
| `claude-code-lsps`        | `Piebald-AI/claude-code-lsps`        | HTML/CSS, Vue, Scala, PowerShell, Julia, LaTeX, Ada, Solidity                                        | `/plugin marketplace add Piebald-AI/claude-code-lsps`        |

> **Note:** `Piebald-AI/claude-code-lsps` is a community repository (Piebald LLC). It is not affiliated with Anthropic or boostvolt. Inform the user before suggesting its installation.

**Marketplace priority:** if a language is covered by multiple marketplaces, prefer in this order: `claude-plugins-official` → `boostvolt/claude-code-lsps` → `Piebald-AI/claude-code-lsps`.

If the required marketplace is missing, tell the user and continue to Level 3.

#### Level 3: Check plugins

Read `~/.claude/settings.json` → `enabledPlugins` to see if the LSP plugin is installed and enabled.

| Language              | Plugin                     | Marketplace                    | Install command                                                           |
|-----------------------|----------------------------|--------------------------------|---------------------------------------------------------------------------|
| TypeScript/JavaScript | typescript-lsp             | `claude-plugins-official`      | `/plugin install typescript-lsp@claude-plugins-official`                  |
| Python                | pyright-lsp                | `claude-plugins-official`      | `/plugin install pyright-lsp@claude-plugins-official`                     |
| Go                    | gopls-lsp                  | `claude-plugins-official`      | `/plugin install gopls-lsp@claude-plugins-official`                       |
| Rust                  | rust-analyzer-lsp          | `claude-plugins-official`      | `/plugin install rust-analyzer-lsp@claude-plugins-official`               |
| C/C++                 | clangd-lsp                 | `claude-plugins-official`      | `/plugin install clangd-lsp@claude-plugins-official`                      |
| Java                  | jdtls-lsp                  | `claude-plugins-official`      | `/plugin install jdtls-lsp@claude-plugins-official`                       |
| C#                    | csharp-lsp                 | `claude-plugins-official`      | `/plugin install csharp-lsp@claude-plugins-official`                      |
| PHP                   | php-lsp                    | `claude-plugins-official`      | `/plugin install php-lsp@claude-plugins-official`                         |
| Swift                 | swift-lsp                  | `claude-plugins-official`      | `/plugin install swift-lsp@claude-plugins-official`                       |
| Kotlin                | kotlin-lsp                 | `claude-plugins-official`      | `/plugin install kotlin-lsp@claude-plugins-official`                      |
| Lua                   | lua-lsp                    | `claude-plugins-official`      | `/plugin install lua-lsp@claude-plugins-official`                         |
| Ansible               | ansible-language-server    | `claude-code-lsps`             | `/plugin install ansible-language-server@claude-code-lsps`                |
| Bash/Shell            | bash-language-server       | `claude-code-lsps`             | `/plugin install bash-language-server@claude-code-lsps`                   |
| YAML                  | yaml-language-server       | `claude-code-lsps`             | `/plugin install yaml-language-server@claude-code-lsps`                   |
| Terraform             | terraform-ls               | `claude-code-lsps`             | `/plugin install terraform-ls@claude-code-lsps`                           |
| Clojure               | clojure-lsp                | `claude-code-lsps`             | `/plugin install clojure-lsp@claude-code-lsps`                            |
| Dart/Flutter          | dart-analyzer              | `claude-code-lsps`             | `/plugin install dart-analyzer@claude-code-lsps`                          |
| Elixir                | elixir-ls                  | `claude-code-lsps`             | `/plugin install elixir-ls@claude-code-lsps`                              |
| Gleam                 | gleam                      | `claude-code-lsps`             | `/plugin install gleam@claude-code-lsps`                                  |
| Nix                   | nixd                       | `claude-code-lsps`             | `/plugin install nixd@claude-code-lsps`                                   |
| OCaml                 | ocaml-lsp                  | `claude-code-lsps`             | `/plugin install ocaml-lsp@claude-code-lsps`                              |
| Ruby                  | solargraph                 | `claude-code-lsps`             | `/plugin install solargraph@claude-code-lsps`                             |
| Zig                   | zls                        | `claude-code-lsps`             | `/plugin install zls@claude-code-lsps`                                    |
| HTML/CSS              | vscode-langservers         | `Piebald-AI/claude-code-lsps`  | `/plugin install vscode-langservers@Piebald-AI/claude-code-lsps`          |
| Vue                   | vue-volar                  | `Piebald-AI/claude-code-lsps`  | `/plugin install vue-volar@Piebald-AI/claude-code-lsps`                   |
| Scala                 | metals                     | `Piebald-AI/claude-code-lsps`  | `/plugin install metals@Piebald-AI/claude-code-lsps`                      |
| PowerShell            | powershell-editor-services | `Piebald-AI/claude-code-lsps`  | `/plugin install powershell-editor-services@Piebald-AI/claude-code-lsps`  |
| Julia                 | julia-lsp                  | `Piebald-AI/claude-code-lsps`  | `/plugin install julia-lsp@Piebald-AI/claude-code-lsps`                   |
| LaTeX                 | texlab                     | `Piebald-AI/claude-code-lsps`  | `/plugin install texlab@Piebald-AI/claude-code-lsps`                      |
| Ada                   | ada-language-server        | `Piebald-AI/claude-code-lsps`  | `/plugin install ada-language-server@Piebald-AI/claude-code-lsps`         |
| Solidity              | solidity-language-server   | `Piebald-AI/claude-code-lsps`  | `/plugin install solidity-language-server@Piebald-AI/claude-code-lsps`    |

- If the plugin is **not installed** → note it in the diagnostic table. Do NOT install it yet.
- If the plugin is **installed but disabled** (`false` in `enabledPlugins`) → note it in the diagnostic table. Do NOT enable it yet.

**Do NOT fix anything at this stage.** Levels 1-4 are diagnostic only. Fixes happen after the user chooses option C in the "After the diagnostic table" section.

#### Level 4: Check LSP binary

**Always run this level** for any language where Level 1 failed, regardless of the plugin state. The binary is required for LSP to work — if the plugin is fixable (Level 3) but the binary is missing, enabling the plugin alone won't help.

| Plugin                     | Binary                        | Check command                       |
|----------------------------|-------------------------------|-------------------------------------|
| typescript-lsp             | `typescript-language-server`  | `which typescript-language-server`  |
| pyright-lsp                | `pyright`                     | `which pyright`                     |
| gopls-lsp                  | `gopls`                       | `which gopls`                       |
| rust-analyzer-lsp          | `rust-analyzer`               | `which rust-analyzer`               |
| clangd-lsp                 | `clangd`                      | `which clangd`                      |
| jdtls-lsp                  | `jdtls`                       | `which jdtls`                       |
| csharp-lsp                 | `OmniSharp`                   | `which OmniSharp`                   |
| php-lsp                    | `phpactor`                    | `which phpactor`                    |
| swift-lsp                  | `sourcekit-lsp`               | `which sourcekit-lsp`               |
| kotlin-lsp                 | `kotlin-language-server`      | `which kotlin-language-server`      |
| lua-lsp                    | `lua-language-server`         | `which lua-language-server`         |
| ansible-language-server    | `ansible-language-server`     | `which ansible-language-server`     |
| bash-language-server       | `bash-language-server`        | `which bash-language-server`        |
| yaml-language-server       | `yaml-language-server`        | `which yaml-language-server`        |
| terraform-ls               | `terraform-ls`                | `which terraform-ls`                |
| clojure-lsp                | `clojure-lsp`                 | `which clojure-lsp`                 |
| dart-analyzer              | `dart`                        | `which dart`                        |
| elixir-ls                  | `elixir-ls`                   | `which elixir-ls`                   |
| gleam                      | `gleam`                       | `which gleam`                       |
| nixd                       | `nixd`                        | `which nixd`                        |
| ocaml-lsp                  | `ocamllsp`                    | `which ocamllsp`                    |
| solargraph                 | `solargraph`                  | `which solargraph`                  |
| zls                        | `zls`                         | `which zls`                         |
| vscode-langservers         | `vscode-html-language-server` | `which vscode-html-language-server` |
| vue-volar                  | `vue-language-server`         | `which vue-language-server`         |
| metals                     | `metals`                      | `which metals`                      |
| powershell-editor-services | `pwsh`                        | `which pwsh`                        |
| julia-lsp                  | `julia`                       | `which julia`                       |
| texlab                     | `texlab`                      | `which texlab`                      |
| ada-language-server        | `ada_language_server`         | `which ada_language_server`         |
| solidity-language-server   | `solidity-language-server`    | `which solidity-language-server`    |

If the binary is missing, tell the user how to install it (e.g., `npm i -g typescript-language-server`, `pip install pyright`, `go install golang.org/x/tools/gopls@latest`). A restart of Claude Code is required after installing the binary.

### Category 1 Rules

- Only check languages actually found in the project. Do NOT list the entire table.
- Levels 1-4 are **diagnostic only**. Do NOT install, enable, or fix anything during the diagnostic. The user decides what to do in the next step.

### Mandatory output

You MUST present this table for each language where Level 1 failed:

| Language | Level 1   | Level 2 (marketplace) | Level 3 (plugin) | Level 4 (binary) | Fix |
|----------|-----------|-----------------------|------------------|------------------|-----|
| Python   | No server | ?                     | ?                | ?                | ?   |

Fill in every column. If you say "LSP unavailable" without showing this table with all levels checked, you have FAILED this skill.

### After the diagnostic table

If nothing needed fixing (all LSP working) → proceed directly.

If fixes are needed, present the fix commands and options **in the user's language** (match the language they used in their message).

First, list ALL the commands grouped by category:
- **Plugin commands**: `claude plugin enable/install ...`
- **Binary commands** (if missing): `pip install pyright`, `npm i -g typescript-language-server typescript`, etc.

Then present the options. Only show the options that are relevant to the diagnostic:
- Always show **A** and **B**.
- Show **C** only if there are plugin fixes (enable/install).
- Show **D** only if there are BOTH plugin fixes AND missing binaries.

Example in English:

> Here are the commands to fix LSP:
>
> Plugins:
> ```
> claude plugin enable pyright-lsp@claude-plugins-official
> claude plugin enable typescript-lsp@claude-plugins-official
> ```
> Binaries:
> ```
> pip install pyright
> npm i -g typescript-language-server typescript
> ```
>
> What do you prefer?
> **A)** Continue without LSP
> **B)** I'll handle it myself — here are the commands above
> **C)** Install/enable plugins only (I run the plugin commands for you)
> **D)** Install everything (I run all commands — plugins + binaries)

**Wait for the user's answer.** Do NOT proceed until the user has responded.
- **A** → proceed without LSP.
- **B** → stop here, the user will fix and relaunch.
- **C** → list the exact commands you are about to run, then execute only the `claude plugin enable/install` commands via Bash. After execution, ask the user to type `/reload-plugins` in the prompt. Wait for confirmation, re-run Level 1 LSP tests, then proceed.
- **D** → list the exact commands you are about to run (both binary installs and plugin commands), then execute them all via Bash. After execution, ask the user to type `/reload-plugins`. Wait for confirmation, re-run Level 1 LSP tests, then proceed.

For C and D: always show the user what you will run BEFORE running it. Transparency is mandatory.

## Category 2: Code Quality Tools

Check for code quality tools available in the environment:

### qlty (unified tool)

Check if `qlty` is available: `which qlty`
- If found: check for `.qlty/qlty.toml` in the project root.
  - If config present: report version (`qlty --version`), note as "installed + configured"
  - If config absent: report version, note as "installed — no project config (run `qlty init` to configure)"
- If not found: note as missing

### Project-specific tools

Check the project for formatter/linter configuration (same detection as `ops:code-quality` Step 1):
- **Formatter**: `.prettierrc`, `pyproject.toml` (`[tool.black]` or `[tool.ruff.format]`), `rustfmt.toml`, `.clang-format`, `gofmt`/`goimports` (built-in), `.editorconfig`, `biome.json`, etc.
- **Linter**: `.eslintrc*`, `pyproject.toml` (`[tool.ruff]`, `[tool.pylint]`), `clippy` (Rust), `golangci-lint`, `.rubocop.yml`, etc.
- **Combined**: `deno fmt`/`deno lint`, `biome check`, `ruff format`/`ruff check`

Also check `package.json` scripts, `Makefile` targets, or CLAUDE.md for project-specific commands.

## Category 3: Security Analysis Tools

### semgrep (SAST)

Check if `semgrep` is available: `which semgrep`
- If found: report version (`semgrep --version`), check for local config (`.semgrep/` or `.semgrep.yml`), note as available
- If not found: note as missing

## Output format

Present the diagnostic results:

```
## Environment Diagnostic

### Package Managers
- System: <apt / dnf / pacman / apk / zypper / none detected>
- Secondary: <brew, mise, nix / none detected>

### Languages & LSP
- Languages detected: <list>
- LSP: [diagnostic table if issues, or "all working"]

### Code Quality Tools
- qlty: installed + configured (vX.Y) / installed — no project config (run `qlty init`) / not found
- Project tools: <list> / none detected

### Security Analysis Tools
- semgrep: installed (vX.Y) + local config / installed (vX.Y) — no local config / not found
```

## Recommendations (user-invoked mode only)

When called directly by the user (not from `/ops:plan`), propose installation for missing tools using the package managers detected in Step 0.

**Only show install commands for package managers the user actually has.** Do not propose `brew install` if brew is not detected. Do not propose `mise install` if mise is not detected.

### Tool installation

| Tool    | Package manager | Install command                                   |
|---------|-----------------|---------------------------------------------------|
| qlty    | curl (always)   | `curl https://qlty.sh \| bash`                    |
| qlty    | brew            | `brew tap qltysh/tap && brew install qlty`         |
| qlty    | mise            | `mise install github:qltysh/qlty`                  |
| semgrep | pip             | `pip install semgrep`                              |
| semgrep | pipx            | `pipx install semgrep`                             |
| semgrep | brew            | `brew install semgrep`                             |
| semgrep | mise            | `mise install pipx && mise install pipx:semgrep`   |

### Project initialization

If a tool is installed but not configured for the current project, propose initialization:

| Tool    | Condition                                        | Init command                | Effect                                                    |
|---------|--------------------------------------------------|-----------------------------|-----------------------------------------------------------|
| qlty    | `qlty` in PATH but no `.qlty/qlty.toml`         | `qlty init`                 | Creates `.qlty/qlty.toml` with auto-detected plugins      |
| semgrep | `semgrep` in PATH but no `.semgrep/` or `.semgrep.yml` | `semgrep ci --dry-run` | Tests rules without local config; or create `.semgrep.yml` |

For qlty init: inform the user that `qlty init` scans the project and generates a `.qlty/qlty.toml` with formatters and linters matching the detected languages. The generated config can be committed to the repo.

### LSP installation

| Component    | Source      | Install command                              |
|--------------|-------------|----------------------------------------------|
| LSP binaries | per-language | see Category 1 Level 4 table                |
| LSP plugins  | Claude Code | `/plugin install ...` (see Category 1 Level 3 table) |

Present only the relevant commands and wait for the user's decision. Do NOT auto-install without consent.

When called from `/ops:plan` Step 0, Categories 2-3 are informational only — report status without proposing installation. The goal of plan Step 0 is to catch LSP issues that require a restart, not to onboard the full toolchain.

## Rules

- Only check languages actually found in the project (Category 1). Do NOT list the entire table.
- Categories 2-3 are quick checks (`which` commands) — they do not need the 4-level depth of LSP diagnostics.
- Tools detected here are reported to the user but NOT passed to downstream skills. `ops:code-quality` and `ops:security-gate` re-detect independently — each skill must work standalone without prior setup.
- If nothing is missing, report "all tools available" and proceed.
