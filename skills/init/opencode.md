# OpenCode — LSP, MCP & Formatter Diagnostic

This is the OpenCode-specific part of `/ops-init`, called when the CLI is detected as OpenCode. It is not independently invocable — it is dispatched from `skills/init/SKILL.md` after CLI detection.

It covers three diagnostic categories: LSP servers, MCP servers, and formatters.

## Category 1: Languages & LSP

OpenCode has 37 built-in LSP servers with auto-detection by file extension and auto-download.

For each language detected in the shared language detection step, check the binary and the config.

### Check 1: Binary presence

Run `which <binary>` for the expected server per language. Only check languages found in the project — do NOT check the entire table.

| Language | Binary | Install method |
|---|---|---|
| Go | `gopls` | `go install golang.org/x/tools/gopls@latest` |
| Python | `pyright-langserver` | auto-download (bun) or `npm i -g pyright` |
| TypeScript/JS | `typescript-language-server` | auto-download (bun) or `npm i -g typescript-language-server typescript` |
| Rust | `rust-analyzer` | manual (ships with rustup) |
| C/C++ | `clangd` | auto-download (GitHub binary) |
| Java | `jdtls` | auto-download (GitHub binary) |
| Ruby | `rubocop` | `gem install ruby-lsp` |
| Bash/Shell | `bash-language-server` | auto-download (bun) or `npm i -g bash-language-server` |
| YAML | `yaml-language-server` | auto-download (bun) or `npm i -g yaml-language-server` |
| Terraform | `terraform-ls` | auto-download (GitHub binary) |
| Zig | `zls` | auto-download (GitHub binary) |
| Lua | `lua-language-server` | auto-download (GitHub binary) |
| Kotlin | `kotlin-language-server` | auto-download (GitHub binary) |
| PHP | `intelephense` | auto-download (bun) |
| Dart | `dart` | manual (ships with Dart SDK) |
| Elixir | `elixir-ls` | auto-download (build from source) |
| Vue | `vue-language-server` | auto-download (bun) |
| Svelte | `svelte-language-server` | auto-download (bun) |
| C# | `OmniSharp` | `dotnet tool install csharp-ls` |

If the binary is absent:
- **Auto-download not disabled** → inform: "Server will be auto-downloaded on next use"
- **`OPENCODE_DISABLE_LSP_DOWNLOAD=true` is set** → signal manual installation needed

### Check 2: Config

Read `./opencode.json` and `~/.config/opencode/opencode.json` → `lsp` key.

- Check for servers explicitly `disabled: true`
- Check for conflicts (e.g., `ty` enabled auto-disables `pyright`)

If a server is disabled in config, note it — this overrides auto-download behavior.

### Mandatory output

You MUST present this table for each detected language (fill in every column):

```
| Language   | Binary           | Config        | Fix                              |
|------------|------------------|---------------|----------------------------------|
| Python     | pyright ✓ / ✗    | ?             | ?                                |
| TypeScript | ts-lang-server ? | ?             | ?                                |
```

Example:

```
| Language   | Binary           | Config        | Fix                              |
|------------|------------------|---------------|----------------------------------|
| Python     | pyright ✓        | not disabled  | —                                |
| Go         | gopls ✓          | —             | —                                |
| TypeScript | ts-lang-server ✗ | disabled:true | Remove disabled in opencode.json |
```

Fill in every column. Only include languages detected in the project.

### After the diagnostic table

If nothing needed fixing (all LSP working) → proceed directly.

If fixes are needed, present options:
- Always show **A** and **C**.
- Show **B** only if there are servers that need manual installation.

> **A)** Continue — missing servers will be auto-installed on next use
> **B)** Force install now (I run the download/install commands for you)
> **C)** Continue without LSP

**Wait for the user's answer.** Do NOT proceed until the user has responded.

After config changes or manual install: **OpenCode restart required** (no hot-reload mechanism).

## Category 2: MCP Servers

Check MCP servers used by ops skills/agents.

| Plugin | Used by | Impact if missing |
|---|---|---|
| `context7` | `ops-researcher-doc` (dispatched by `plan`, `do`, `research`, `test`, `perf`, `refactor`) | researcher-doc falls back to WebSearch/WebFetch (slower, less precise) |
| `chrome-devtools-mcp` | `ops-debug` (web debugging), accessibility audits, LCP optimization | No browser debugging or DevTools integration |

### Check 1: Config

Read `./opencode.json` and `~/.config/opencode/opencode.json` → `mcp` key.

For each server:
- If present and `enabled: true` → note as "configured"
- If present and `enabled: false` → note as "disabled"
- If absent → note as "not configured"

### Check 2: Connection status

Run `opencode mcp list` via Bash to get the live connection status of all MCP servers. This shows which servers are connected and which have errors.

For each server, report the status as shown by the command (e.g., "Connected", "MCP error -32000: Connection closed", etc.).

- **chrome-devtools-mcp** with "Connection closed" → not a config issue, Chrome is simply not running with remote debugging. Note this as expected.
- Any other error → report as a real issue.

### Mandatory output

```
| Plugin              | Config  | Connection | Status                                      |
|---------------------|---------|------------|---------------------------------------------|
| context7            | ?       | ✓ / ✗      | <Connected / error detail / not configured> |
| chrome-devtools-mcp | ?       | ✓ / ✗      | <Connected / error detail / not configured> |
```

### After the diagnostic

If all servers are present, enabled, and working → proceed directly.

For `chrome-devtools-mcp` with a connection error: note that this is expected when Chrome is not open with remote debugging. Not a config issue.

For each server that is absent, propose the JSON block AND the target file:

```json
"context7": {
  "type": "local",
  "command": ["npx", "-y", "@upstash/context7-mcp@latest"],
  "enabled": true
},
"chrome-devtools-mcp": {
  "type": "local",
  "command": ["npx", "-y", "chrome-devtools-mcp@latest"],
  "enabled": true
}
```

> **A)** I add the config to `opencode.json` for you
> **B)** I'll handle it myself — here's the JSON above
> **C)** Skip — continue without these servers

Only show the blocks relevant to what is actually missing.

**Wait for the user's answer.** Do NOT proceed until the user has responded.
- **A** → edit `opencode.json` to add the MCP config under the `"mcp"` key. After editing, inform: "OpenCode restart required."
- **B** → stop, user handles it.
- **C** → proceed without the missing servers. Note degraded capabilities.

## Formatters (informational only)

OpenCode has 30+ built-in formatters that auto-run after every file write/edit. They are auto-detected if the binary is on PATH. This section is informational — no automatic action is taken.

### Project tools

Check for project-level config files: `.prettierrc`, `.editorconfig`, `rustfmt.toml`, `biome.json`, `.eslintrc.*`, `pyproject.toml` (with formatter/linter config), etc.

If a project tool is referenced in config files (e.g., `ruff` in `pyproject.toml`, `prettier` in `package.json`), **verify it is actually installed** by running `which <tool>`. If the tool is configured but not installed, flag it as a problem — the project expects it but it won't work.

### OpenCode formatter overrides

Read `opencode.json` → `formatter` key for any overrides or disabled formatters.

### Conflict detection

If a conflict exists between an OpenCode built-in formatter and a project-level tool config → flag it to the user.

Report any conflicts found but do NOT take automatic action. The user decides how to resolve formatter conflicts.
