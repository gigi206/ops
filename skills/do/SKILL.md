---
name: ops:do
description: "Lightweight structured workflow: research, execute, verify, review."
---

# /ops:do — Lightweight structured workflow

<HARD-GATE-0>
STOP. Your VERY FIRST action must be Step 0: Environment Setup. Do NOT start executing changes yet. Do NOT dispatch research agents yet.

Your first tool calls must be exactly:
1. `Glob` to detect file extensions (e.g., `**/*.py`, `**/*.ts`, `**/*.go`)
2. `ToolSearch` to fetch the LSP tool
3. `LSP documentSymbol` on one representative file per detected language

If your first tool call is anything other than Glob for language detection, you have FAILED this skill.
</HARD-GATE-0>

## Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority. If the user says "skip TDD", skip it.
2. **CLAUDE.md project rules** — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

If a CLAUDE.md rule contradicts an ops skill instruction, follow CLAUDE.md. If the user contradicts CLAUDE.md, follow the user. When in doubt, ask.

## Subagent Context Rules

When dispatching any subagent (researcher-code, researcher-doc, code-reviewer):

- **Provide content inline.** If you already read a file, paste the relevant content into the agent prompt. Do NOT ask the agent to re-read the same file.
- **Scope the context.** Give the agent only what it needs for its task — not the entire plan, not every file you've read. A researcher-code analyzing conventions needs the task area files, not the brainstorm transcript.
- **Name what you provide.** Always label pasted content with its source: `[From src/auth/middleware.ts:15-42]`. The agent needs to know where the content comes from to cite it.
- **Let the agent explore beyond.** Providing context doesn't mean restricting the agent. It can and should read additional files it discovers during exploration — the goal is to avoid redundant reads, not to limit scope.

## Workflow

```
0. Environment Setup → 1. Restatement → 2. Research (2 agents) → 3. Scope Guard → 4. Tasks (optional) → 5. Execute → 6. Verify → 7. Code Review → 8. Update Documentation → 9. Run Tests → 10. Check CLAUDE.md
```

---

## Step 0: Environment Setup (MANDATORY — runs FIRST)

This step runs BEFORE any work. If LSP needs fixing, the user may need to restart Claude Code — better to catch this before investing time in execution.

### 0a. Detect languages

Scan the codebase to identify the primary languages and frameworks:
- Use Glob to check for file extensions (e.g., `**/*.py`, `**/*.ts`, `**/*.go`, `**/*.rs`, `**/*.java`, `**/*.rb`, `**/*.yaml`, `**/*.sh`, `**/*.tf`, `**/*.clj`, `**/*.dart`, `**/*.ex`, `**/*.gleam`, `**/*.nix`, `**/*.ml`, `**/*.zig`, `**/*.html`, `**/*.css`, `**/*.vue`, `**/*.scala`, `**/*.ps1`, `**/*.jl`, `**/*.tex`, `**/*.adb`, `**/*.ads`, `**/*.sol`)
- Read config files that indicate the stack (`package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `Gemfile`, `Makefile`, etc.)

Present the detected languages to the user (one line is enough, e.g., "Languages detected: Python, TypeScript, YAML").

### 0b. Check LSP availability

LSP (Language Server Protocol) gives the agent real diagnostics (type errors, missing imports, syntax issues) instead of guessing. It makes every agent in the pipeline smarter.

For each language detected in Step 0a, work through 4 levels. Stop as soon as LSP works for that language.

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

| Marketplace               | Repo                                 | Languages covered                                                                        | Add command                                                  |
|---------------------------|--------------------------------------|------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `claude-plugins-official` | `anthropics/claude-plugins-official` | TypeScript, Python, Go, Rust, C/C++, Java, C#, PHP, Swift, Kotlin, Lua                   | `/plugin marketplace add anthropics/claude-plugins-official` |
| `claude-code-lsps`        | `boostvolt/claude-code-lsps`         | Bash/Shell, YAML, Terraform, Clojure, Dart/Flutter, Elixir, Gleam, Nix, OCaml, Ruby, Zig | `/plugin marketplace add boostvolt/claude-code-lsps`         |
| `claude-code-lsps`        | `Piebald-AI/claude-code-lsps`        | HTML/CSS, Vue, Scala, PowerShell, Julia, LaTeX, Ada, Solidity                            | `/plugin marketplace add Piebald-AI/claude-code-lsps`        |

> **Note :** `Piebald-AI/claude-code-lsps` est un dépôt communautaire (Piebald LLC). Il n'est pas affilié à Anthropic ni à boostvolt. Informer l'utilisateur avant de proposer son installation.

**Priorité des marketplaces :** si un langage est couvert par plusieurs marketplaces, préférer dans cet ordre : `claude-plugins-official` → `boostvolt/claude-code-lsps` → `Piebald-AI/claude-code-lsps`.

If the required marketplace is missing, tell the user and continue to Level 3.

#### Level 3: Check plugins

Read `~/.claude/settings.json` → `enabledPlugins` to see if the LSP plugin is installed and enabled.

| Language              | Plugin                     | Marketplace                   | Install command                                                          |
|-----------------------|----------------------------|-------------------------------|--------------------------------------------------------------------------|
| TypeScript/JavaScript | typescript-lsp             | `claude-plugins-official`     | `/plugin install typescript-lsp@claude-plugins-official`                 |
| Python                | pyright-lsp                | `claude-plugins-official`     | `/plugin install pyright-lsp@claude-plugins-official`                    |
| Go                    | gopls-lsp                  | `claude-plugins-official`     | `/plugin install gopls-lsp@claude-plugins-official`                      |
| Rust                  | rust-analyzer-lsp          | `claude-plugins-official`     | `/plugin install rust-analyzer-lsp@claude-plugins-official`              |
| C/C++                 | clangd-lsp                 | `claude-plugins-official`     | `/plugin install clangd-lsp@claude-plugins-official`                     |
| Java                  | jdtls-lsp                  | `claude-plugins-official`     | `/plugin install jdtls-lsp@claude-plugins-official`                      |
| C#                    | csharp-lsp                 | `claude-plugins-official`     | `/plugin install csharp-lsp@claude-plugins-official`                     |
| PHP                   | php-lsp                    | `claude-plugins-official`     | `/plugin install php-lsp@claude-plugins-official`                        |
| Swift                 | swift-lsp                  | `claude-plugins-official`     | `/plugin install swift-lsp@claude-plugins-official`                      |
| Kotlin                | kotlin-lsp                 | `claude-plugins-official`     | `/plugin install kotlin-lsp@claude-plugins-official`                     |
| Lua                   | lua-lsp                    | `claude-plugins-official`     | `/plugin install lua-lsp@claude-plugins-official`                        |
| Bash/Shell            | bash-language-server       | `claude-code-lsps`            | `/plugin install bash-language-server@claude-code-lsps`                  |
| YAML                  | yaml-language-server       | `claude-code-lsps`            | `/plugin install yaml-language-server@claude-code-lsps`                  |
| Terraform             | terraform-ls               | `claude-code-lsps`            | `/plugin install terraform-ls@claude-code-lsps`                          |
| Clojure               | clojure-lsp                | `claude-code-lsps`            | `/plugin install clojure-lsp@claude-code-lsps`                           |
| Dart/Flutter          | dart-analyzer              | `claude-code-lsps`            | `/plugin install dart-analyzer@claude-code-lsps`                         |
| Elixir                | elixir-ls                  | `claude-code-lsps`            | `/plugin install elixir-ls@claude-code-lsps`                             |
| Gleam                 | gleam                      | `claude-code-lsps`            | `/plugin install gleam@claude-code-lsps`                                 |
| Nix                   | nixd                       | `claude-code-lsps`            | `/plugin install nixd@claude-code-lsps`                                  |
| OCaml                 | ocaml-lsp                  | `claude-code-lsps`            | `/plugin install ocaml-lsp@claude-code-lsps`                             |
| Ruby                  | solargraph                 | `claude-code-lsps`            | `/plugin install solargraph@claude-code-lsps`                            |
| Zig                   | zls                        | `claude-code-lsps`            | `/plugin install zls@claude-code-lsps`                                   |
| HTML/CSS              | vscode-langservers         | `Piebald-AI/claude-code-lsps` | `/plugin install vscode-langservers@Piebald-AI/claude-code-lsps`         |
| Vue                   | vue-volar                  | `Piebald-AI/claude-code-lsps` | `/plugin install vue-volar@Piebald-AI/claude-code-lsps`                  |
| Scala                 | metals                     | `Piebald-AI/claude-code-lsps` | `/plugin install metals@Piebald-AI/claude-code-lsps`                     |
| PowerShell            | powershell-editor-services | `Piebald-AI/claude-code-lsps` | `/plugin install powershell-editor-services@Piebald-AI/claude-code-lsps` |
| Julia                 | julia-lsp                  | `Piebald-AI/claude-code-lsps` | `/plugin install julia-lsp@Piebald-AI/claude-code-lsps`                  |
| LaTeX                 | texlab                     | `Piebald-AI/claude-code-lsps` | `/plugin install texlab@Piebald-AI/claude-code-lsps`                     |
| Ada                   | ada-language-server        | `Piebald-AI/claude-code-lsps` | `/plugin install ada-language-server@Piebald-AI/claude-code-lsps`        |
| Solidity              | solidity-language-server   | `Piebald-AI/claude-code-lsps` | `/plugin install solidity-language-server@Piebald-AI/claude-code-lsps`   |

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

#### Rules

- Only check languages actually found in the project. Do NOT list the entire table.
- Levels 1-4 are **diagnostic only**. Do NOT install, enable, or fix anything during the diagnostic. The user decides what to do in the next step.

#### Mandatory output

You MUST present this table for each language where Level 1 failed:

| Language | Level 1   | Level 2 (marketplace) | Level 3 (plugin) | Level 4 (binary) | Fix |
|----------|-----------|-----------------------|------------------|------------------|-----|
| Python   | No server | ?                     | ?                | ?                | ?   |

Fill in every column. If you say "LSP unavailable" without showing this table with all levels checked, you have FAILED this skill.

#### After the diagnostic table

If nothing needed fixing (all LSP working) → proceed to Step 1 directly.

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

**Wait for the user's answer.** Do NOT proceed to Step 1 (Restatement) until the user has responded.
- **A** → proceed to Step 1 without LSP.
- **B** → stop here, the user will fix and relaunch.
- **C** → list the exact commands you are about to run, then execute only the `claude plugin enable/install` commands via Bash. After execution, ask the user to type `/reload-plugins` in the prompt. Wait for confirmation, re-run Level 1 LSP tests, then proceed to Step 1.
- **D** → list the exact commands you are about to run (both binary installs and plugin commands), then execute them all via Bash. After execution, ask the user to type `/reload-plugins`. Wait for confirmation, re-run Level 1 LSP tests, then proceed to Step 1.

For C and D: always show the user what you will run BEFORE running it. Transparency is mandatory.

---

## Step 1: Restatement

Reformulate the user's intent in one sentence to confirm understanding. No Socratic questions, no brainstorming, no YAGNI filter.

This is NOT a gate — no user approval required. State what you understood and proceed to Step 2. If the user corrects the restatement, acknowledge the correction, restate again, and continue.

---

## Step 2: Research (2 agents in parallel)

Dispatch two agents **in parallel** using the Agent tool:

### researcher-code
- Explore the codebase for patterns, conventions, existing implementations, integration points, and risks relevant to the task.

### researcher-doc
- Query Context7 MCP (fallback: web search) for relevant library/tool documentation.

**Wait for both agents to return before proceeding.**

---

## Step 3: Scope Guard

After research returns, evaluate whether the task is actually simple enough for `/ops:do`:

- If research reveals **non-obvious design choices** (multiple valid approaches, conflicting patterns, architectural implications) → suggest escalating to `/ops:plan`.
- If research reveals the change is **far larger than expected** (touching many independent subsystems) → suggest escalating to `/ops:plan`.

This is a safety valve, not a gate. The user can override.

---

## Step 4: Tasks (optional)

Based on the complexity of the **decision**, not the volume of files:

- **No tasks**: mechanical/evident change — proceed directly to Step 5.
- **Grouped tasks**: few logically distinct steps. Format: `description → validation command`.

---

## Step 5: Execute

Implement the changes directly (no implementer agent). If tasks were defined in Step 4, follow them in order.

---

## Step 6: Verify (build/compile)

Run build/compile commands, validation commands, dry-runs. This is "it compiles and runs" — not the full test suite.

`/ops:verify` behavioral rule applies: **never claim a result without showing the evidence.** Run the command, read the output, verify it confirms the claim. If any step fails, say what happened instead of what you expected.

---

## Step 7: Code Review (light)

Dispatch the **code-reviewer** agent with:

- The complete diff (`git diff`)
- The user's original intent (restatement from Step 1)
- The task list from Step 4 (if any)
- The project's CLAUDE.md rules (if applicable)
- Explicit instruction: **skip spec compliance check** (no spec exists — use user intent and task list as reference)

Scope: LSP diagnostics, code quality, CLAUDE.md conventions. No spec compliance.

**One cycle maximum**: fix issues, re-run review once. If still failing → escalate to user.

No security triage unless changes obviously touch security-sensitive areas. Use judgment.

---

## Step 8: Update Documentation

If the project has documentation affected by the change, update it. Skip if none exists or none is affected.

---

## Step 9: Run Tests

If the project has a test suite, run it. Max 2 fix attempts if tests fail, then escalate to user. Skip if no test infrastructure.

---

## Step 10: Check CLAUDE.md (always last)

Read `CLAUDE.md` and `.claude/CLAUDE.md`. Verify all applicable rules were followed. Fix violations before completing. Mandatory, always last.
