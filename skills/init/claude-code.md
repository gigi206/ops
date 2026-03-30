# Claude Code — LSP & MCP Diagnostic

This is the Claude Code-specific part of `/ops-init`, called when the CLI is detected as Claude Code. It is not independently invocable — it is dispatched from `skills/init/SKILL.md` after CLI detection.

It covers two diagnostic categories that depend on Claude Code's plugin/marketplace system.

## Category 1: Languages & LSP

For each language detected in the shared language detection step, work through 4 levels. Stop as soon as LSP works for that language.

### Level 1: Test LSP per language

For each detected language, pick a representative file and call `LSP documentSymbol` on it.
- **If it returns symbols** → LSP is active for this language. Move on.
- **If it returns an error** (e.g., "no server available") → this language has no working LSP. **Continue to Level 2.**

Example: project has `.py`, `.sh`, `.yaml` files → test each:
```
LSP documentSymbol on src/main.py:1:1
LSP documentSymbol on scripts/deploy.sh:1:1
LSP documentSymbol on config/app.yaml:1:1
```

### Level 2: Check marketplaces

The LSP plugins come from two marketplaces. Read `~/.claude/settings.json` → `extraKnownMarketplaces` to verify the user has the required one configured.

| Marketplace | Repo | Languages covered | Add command |
|---|---|---|---|
| `claude-plugins-official` | `anthropics/claude-plugins-official` | TypeScript, Python, Go, Rust, C/C++, Java, C#, PHP, Swift, Kotlin, Lua | `/plugin marketplace add anthropics/claude-plugins-official` |
| `claude-code-lsps` | `boostvolt/claude-code-lsps` | Ansible, Bash/Shell, YAML, Terraform, Clojure, Dart/Flutter, Elixir, Gleam, Nix, OCaml, Ruby, Zig | `/plugin marketplace add boostvolt/claude-code-lsps` |

**Marketplace priority:** if a language is covered by multiple marketplaces, prefer in this order: `claude-plugins-official` → `boostvolt/claude-code-lsps`.

If the required marketplace is missing, tell the user and continue to Level 3.

### Level 3: Check plugins

Read `~/.claude/settings.json` → `enabledPlugins` to see if the LSP plugin is installed and enabled.

| Language | Plugin | Marketplace | Install command |
|---|---|---|---|
| TypeScript/JavaScript | typescript-lsp | `claude-plugins-official` | `/plugin install typescript-lsp@claude-plugins-official` |
| Python | pyright-lsp | `claude-plugins-official` | `/plugin install pyright-lsp@claude-plugins-official` |
| Go | gopls-lsp | `claude-plugins-official` | `/plugin install gopls-lsp@claude-plugins-official` |
| Rust | rust-analyzer-lsp | `claude-plugins-official` | `/plugin install rust-analyzer-lsp@claude-plugins-official` |
| C/C++ | clangd-lsp | `claude-plugins-official` | `/plugin install clangd-lsp@claude-plugins-official` |
| Java | jdtls-lsp | `claude-plugins-official` | `/plugin install jdtls-lsp@claude-plugins-official` |
| C# | csharp-lsp | `claude-plugins-official` | `/plugin install csharp-lsp@claude-plugins-official` |
| PHP | php-lsp | `claude-plugins-official` | `/plugin install php-lsp@claude-plugins-official` |
| Swift | swift-lsp | `claude-plugins-official` | `/plugin install swift-lsp@claude-plugins-official` |
| Kotlin | kotlin-lsp | `claude-plugins-official` | `/plugin install kotlin-lsp@claude-plugins-official` |
| Lua | lua-lsp | `claude-plugins-official` | `/plugin install lua-lsp@claude-plugins-official` |
| Ansible | ansible-language-server | `claude-code-lsps` | `/plugin install ansible-language-server@claude-code-lsps` |
| Bash/Shell | bash-language-server | `claude-code-lsps` | `/plugin install bash-language-server@claude-code-lsps` |
| YAML | yaml-language-server | `claude-code-lsps` | `/plugin install yaml-language-server@claude-code-lsps` |
| Terraform | terraform-ls | `claude-code-lsps` | `/plugin install terraform-ls@claude-code-lsps` |
| Clojure | clojure-lsp | `claude-code-lsps` | `/plugin install clojure-lsp@claude-code-lsps` |
| Dart/Flutter | dart-analyzer | `claude-code-lsps` | `/plugin install dart-analyzer@claude-code-lsps` |
| Elixir | elixir-ls | `claude-code-lsps` | `/plugin install elixir-ls@claude-code-lsps` |
| Gleam | gleam | `claude-code-lsps` | `/plugin install gleam@claude-code-lsps` |
| Nix | nixd | `claude-code-lsps` | `/plugin install nixd@claude-code-lsps` |
| OCaml | ocaml-lsp | `claude-code-lsps` | `/plugin install ocaml-lsp@claude-code-lsps` |
| Ruby | solargraph | `claude-code-lsps` | `/plugin install solargraph@claude-code-lsps` |
| Zig | zls | `claude-code-lsps` | `/plugin install zls@claude-code-lsps` |

- If the plugin is **not installed** → note it in the diagnostic table. Do NOT install it yet.
- If the plugin is **installed but disabled** (`false` in `enabledPlugins`) → note it in the diagnostic table. Do NOT enable it yet.

**Do NOT fix anything at this stage.** Levels 1-4 are diagnostic only. Fixes happen after the user chooses option C in the "After the diagnostic table" section.

### Level 4: Check LSP binary

**Always run this level** for any language where Level 1 failed, regardless of the plugin state. The binary is required for LSP to work — if the plugin is fixable (Level 3) but the binary is missing, enabling the plugin alone won't help.

| Plugin | Binary | Check command |
|---|---|---|
| typescript-lsp | `typescript-language-server` | `which typescript-language-server` |
| pyright-lsp | `pyright` | `which pyright` |
| gopls-lsp | `gopls` | `which gopls` |
| rust-analyzer-lsp | `rust-analyzer` | `which rust-analyzer` |
| clangd-lsp | `clangd` | `which clangd` |
| jdtls-lsp | `jdtls` | `which jdtls` |
| csharp-lsp | `OmniSharp` | `which OmniSharp` |
| php-lsp | `phpactor` | `which phpactor` |
| swift-lsp | `sourcekit-lsp` | `which sourcekit-lsp` |
| kotlin-lsp | `kotlin-language-server` | `which kotlin-language-server` |
| lua-lsp | `lua-language-server` | `which lua-language-server` |
| ansible-language-server | `ansible-language-server` | `which ansible-language-server` |
| bash-language-server | `bash-language-server` | `which bash-language-server` |
| yaml-language-server | `yaml-language-server` | `which yaml-language-server` |
| terraform-ls | `terraform-ls` | `which terraform-ls` |
| clojure-lsp | `clojure-lsp` | `which clojure-lsp` |
| dart-analyzer | `dart` | `which dart` |
| elixir-ls | `elixir-ls` | `which elixir-ls` |
| gleam | `gleam` | `which gleam` |
| nixd | `nixd` | `which nixd` |
| ocaml-lsp | `ocamllsp` | `which ocamllsp` |
| solargraph | `solargraph` | `which solargraph` |
| zls | `zls` | `which zls` |

If the binary is missing, tell the user how to install it (e.g., `npm i -g typescript-language-server`, `pip install pyright`, `go install golang.org/x/tools/gopls@latest`). A restart of Claude Code is required after installing the binary.

### Category 1 Rules

- Only check languages actually found in the project. Do NOT list the entire table.
- Levels 1-4 are **diagnostic only**. Do NOT install, enable, or fix anything during the diagnostic. The user decides what to do in the next step.

### Mandatory output

You MUST present this table for each language where Level 1 failed:

| Language | Level 1 | Level 2 (marketplace) | Level 3 (plugin) | Level 4 (binary) | Fix |
|---|---|---|---|---|---|
| Python | No server | ? | ? | ? | ? |

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

## Category 2: MCP Servers

Check plugins that provide MCP servers used by ops skills/agents.

| Plugin | Marketplace | Used by | Impact if missing |
|---|---|---|---|
| `context7` | `claude-plugins-official` (`anthropics/claude-plugins-official`) | `ops-researcher-doc` (dispatched by `plan`, `do`, `research`, `test`, `perf`, `refactor`) | researcher-doc falls back to WebSearch/WebFetch (slower, less precise) |
| `chrome-devtools-mcp` | `chrome-devtools-plugins` (`ChromeDevTools/chrome-devtools-mcp`) | `ops-debug` (web debugging), accessibility audits, LCP optimization | No browser debugging or DevTools integration |

### Check availability

For each plugin, read `~/.claude/settings.json` → `enabledPlugins`:

| Plugin key in `enabledPlugins` | Marketplace to check in `extraKnownMarketplaces` |
|---|---|
| `context7@claude-plugins-official` | `claude-plugins-official` |
| `chrome-devtools-mcp@chrome-devtools-plugins` | `chrome-devtools-plugins` |

For each plugin:
- If value is `true` → note as "enabled"
- If value is `false` → note as "disabled"
- If key absent → note as "not installed"

Also check that the required marketplace is present in `extraKnownMarketplaces`. If the marketplace itself is missing, note it — the plugin cannot be installed without it.

### Mandatory output

```
| Plugin | Marketplace | Status | Impact if missing |
|---|---|---|---|
| context7 | claude-plugins-official | <enabled / disabled / not installed> | researcher-doc falls back to WebSearch |
| chrome-devtools-mcp | chrome-devtools-plugins | <enabled / disabled / not installed> | No browser debugging via DevTools |
```

### After the diagnostic

For each plugin that is **not installed**:

1. Check if its marketplace is configured. If missing, include the marketplace add command.
2. Present the installation commands **in the user's language**.

Group all missing plugins into a single prompt:

> The following MCP plugins are not installed:
>
> | Plugin | Needed for | Marketplace |
> |---|---|---|
> | context7 | Documentation research (`researcher-doc`) | `claude-plugins-official` |
> | chrome-devtools-mcp | Browser debugging (`ops-debug`) | `chrome-devtools-plugins` |
>
> Installation commands:
> ```
> # Marketplaces (if missing)
> /plugin marketplace add anthropics/claude-plugins-official
> /plugin marketplace add ChromeDevTools/chrome-devtools-mcp
>
> # Plugins
> /plugin install context7@claude-plugins-official
> /plugin install chrome-devtools-mcp@chrome-devtools-plugins
> ```
>
> **A)** Install everything (I run all commands for you)
> **B)** I'll handle it myself — here are the commands above
> **C)** Skip — continue without these plugins

Only show the commands relevant to what is actually missing. If only one plugin is missing, show only that one.

**Wait for the user's answer.** Do NOT proceed until the user has responded.
- **A** → list the exact commands you are about to run, then execute them via Bash. After execution, ask the user to type `/reload-plugins`. Wait for confirmation, then proceed.
- **B** → stop here, the user will fix and relaunch.
- **C** → proceed without the missing plugins. Note degraded capabilities.

For each plugin that is **disabled** (installed but `false` in `enabledPlugins`):

> The following plugins are installed but disabled:
> ```
> /plugin enable context7@claude-plugins-official
> /plugin enable chrome-devtools-mcp@chrome-devtools-plugins
> ```
> **A)** Enable them (I run the commands for you)
> **B)** Skip — continue without these plugins

Always show the user what you will run BEFORE running it. Transparency is mandatory.
