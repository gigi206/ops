# OpenCode Compatibility + Skill Renaming — Design Spec

**Version**: 3.0.0
**Date**: 2026-03-30
**Status**: Implemented

## Objective

Make the ops plugin fully compatible with OpenCode while maintaining Claude Code support. Shared content directories with thin per-platform adapters. Rename all skills from `ops:*` to `ops-*` for cross-platform filename compatibility. Extract a shared review pipeline to eliminate duplication across workflow skills. Decouple `ops-plan` from `ops-init`.

## Architecture

Content (skills, agents, scripts) lives in shared root-level directories. Each platform gets a thin adapter (1-3 files) that bridges the shared content to its mechanisms.

```
ops/
├── agents/              # 11 agents — shared, read by skills
├── skills/              # 26 skills — shared
├── scripts/             # Deterministic logic — shared
├── hooks/               # Hook session-start — shared (used by Claude Code)
├── data/                # Shared data files (new)
│   └── bootstrap-context.md   # Skill routing table — single source of truth
│
├── .claude-plugin/      # Claude Code adapter (existing)
│   ├── plugin.json
│   └── marketplace.json
│
├── skills/review-pipeline/ # Shared review sequence (new — internal skill)
│
├── .opencode/           # OpenCode adapter (new)
│   ├── plugins/ops.js   #   ESM plugin: registers skills, commands + injects bootstrap
│   └── INSTALL.md       #   User installation instructions + troubleshooting
├── docs/
│   └── opencode/
│       └── README.md    #   Detailed OpenCode guide (usage, tool mapping, etc.)
│
├── package.json         # OpenCode entry point (new)
├── AGENTS.md            # Project instructions — source of truth (new)
└── CLAUDE.md            # Points to AGENTS.md via @AGENTS.md (simplified)
```

### Principles

- Zero content duplication between platforms
- Skill/agent frontmatter stays in current format — platforms ignore unknown fields
- Deterministic logic (command generation, model mapping) in `scripts/`
- Adaptive logic (bootstrap, prompt injection) in plugin JS or skills markdown
- Shared data files (routing table) read by all platform adapters

## Review Pipeline Extraction (`skills/review-pipeline/`)

The final review sequence — code quality → security gate → code review → project instruction check — was duplicated across `do`, `perf`, `refactor`, and `test`. It is now extracted into a single internal skill `ops-review-pipeline` (`user-invocable: false`).

Each calling skill references the pipeline and passes skill-specific **code-reviewer context** (e.g., performance measurements for `perf`, behavior preservation for `refactor`). The pipeline handles the rest identically:

1. **Code Quality** — run `ops-code-quality` on modified files
2. **Security Gate + Code Review** — run `ops-security-gate`, dispatch code-reviewer (and security-reviewer if triggered), one fix cycle max
3. **Check Project Instructions** — verify all applicable rules were followed

### Impact on workflow skills

| Skill      | Before (steps)                                                    | After (steps)                           |
| ---------- | ----------------------------------------------------------------- | --------------------------------------- |
| `do`       | …→ Verify + Code Quality → Security Gate + Code Review → Check PI | …→ Verify → Review Pipeline → Run Tests |
| `perf`     | …→ Code Quality → Code Review → Check PI                          | …→ Review Pipeline                      |
| `refactor` | …→ Code Quality → Code Review → Check PI                          | …→ Review Pipeline                      |
| `test`     | …→ Code Quality → Code Review → Check PI                          | …→ Review Pipeline                      |

Net result: ~76 lines of duplication eliminated, single source of truth for the review sequence.

## Plan/Init Decoupling

`ops-plan` Step 0 no longer runs the full `ops-init` diagnostic (LSP, MCP, plugins). It is now limited to discovering the project's build/test/lint commands. If environment issues exist, the user can run `/ops-init` separately.

`ops-init` is simplified to a single mode (user-invoked only). The previous dual-mode behavior (user-invoked vs. called-from-plan) is removed.

### Rationale

Running full environment diagnostics before every plan was heavyweight and often unnecessary. Discovering build commands is the only part actually needed for planning.

## Breaking Change: Skill Renaming `ops:*` → `ops-*`

All skill names change from colon to hyphen separator for cross-platform filename compatibility (colons are invalid in Windows filenames).

### Scope

- **38 files modified** with `ops:` → `ops-` rename (24 skills + 11 agents + 1 hook + 1 script + 1 README)
- **4 additional files modified** for other changes (2 config JSONs, CLAUDE.md, CHANGELOG.md)
- **CHANGELOG.md**: historical entries keep original naming; only a new 3.0.0 section is added
- **README.md**: all `ops:` → `ops-` references updated
- Pure mechanical find-and-replace of `ops:` followed by a skill name (e.g., `ops:plan` → `ops-plan`)
- All occurrences in the codebase are skill name references — no false positives from prose colons
- No logic changes

### Affected patterns

| Pattern                  | Before                                      | After                                       |
| ------------------------ | ------------------------------------------- | ------------------------------------------- |
| Skill frontmatter `name` | `name: ops:plan`                            | `name: ops-plan`                            |
| Skill cross-references   | `Follow the ops:instruction-priority rules` | `Follow the ops-instruction-priority rules` |
| Skill invocations        | `invoke /ops:implement`                     | `invoke /ops-implement`                     |
| Agent descriptions       | `Dispatched during /ops:plan`               | `Dispatched during /ops-plan`               |
| Hook routing table       | `/ops:plan`                                 | `/ops-plan`                                 |
| Script comments          | `ops:security-gate`                         | `ops-security-gate`                         |

## Bootstrap Routing Table (`data/bootstrap-context.md`)

The skill routing table — the content that tells the LLM when to suggest which ops skill — is extracted into a shared file `data/bootstrap-context.md`. This is the single source of truth read by both platform adapters:

- **Claude Code**: `hooks/session-start` reads the file with `cat` and wraps it in the `hookSpecificOutput` JSON format
- **OpenCode**: `.opencode/plugins/ops.js` reads the file with `fs.readFileSync` and appends it to the system prompt

The `hooks/session-start` script loses its hardcoded HEREDOC and reads `data/bootstrap-context.md` instead.

When adding or removing a skill, this file must be updated (enforced by the versioning rule in AGENTS.md).

## OpenCode Plugin (`.opencode/plugins/ops.js`)

ESM module with 3 hooks:

### 1. Skills registration (`config` hook)

```javascript
config: async (config) => {
  config.skills = config.skills || {};
  config.skills.paths = config.skills.paths || [];
  if (!config.skills.paths.includes(opsSkillsDir)) {
    config.skills.paths.push(opsSkillsDir);
  }
};
```

Registers the shared `skills/` directory so OpenCode discovers all 26 skills natively.

### 2. Bootstrap injection (`experimental.chat.system.transform` hook)

Reads `data/bootstrap-context.md` and appends its content to the system prompt. The LLM then knows when to suggest `/ops-plan`, `/ops-debug`, etc.

```javascript
'experimental.chat.system.transform': async (_input, output) => {
  const bootstrap = fs.readFileSync(
    path.join(opsRoot, 'data', 'bootstrap-context.md'), 'utf8'
  );
  (output.system ||= []).push(bootstrap);
}
```

### 3. PATH setup (`shell.env` hook)

```javascript
'shell.env': async (_input, output) => {
  output.env.PATH = `${opsScriptsDir}:${output.env.PATH || process.env.PATH}`;
}
```

Makes `ops-semgrep-scan.sh` available in bash commands.

### Plugin root discovery

Uses `import.meta.url` (ESM standard) to derive its own location, then resolves up to the plugin root.

### Dependencies

None. Pure JS, no npm packages required at runtime.

## OpenCode Commands (dynamic registration)

Commands are dynamically generated by the plugin's `loadCommands()` function in `.opencode/plugins/ops.js`. It scans `skills/*/SKILL.md`, reads each frontmatter, and registers one `/ops-<name>` command per user-invocable skill. No static `.opencode/commands/*.md` files needed.

This replaces the original approach of 17 static wrapper files. The dynamic loader:

- Reads `skills/` directory entries
- Parses SKILL.md frontmatter for `name`, `description`, and `user-invocable`
- Skips skills with `user-invocable: false`
- Registers commands via the `config.command` hook

Descriptions are taken from the `description` field in each skill's frontmatter.

## CLI-Agnostic Content Cleanup

All hardcoded `CLAUDE.md` and Claude Code-specific references in skills, agents, and README have been replaced with CLI-agnostic equivalents. Task management tool references (Claude Code-specific `TaskCreate`/`TaskUpdate`) have been replaced with natural language instructions. Error messages have been unified to English.

### Replacement patterns

| Context                        | Before                                          | After                                                                                     |
| ------------------------------ | ----------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Read instruction (agents)      | `Read CLAUDE.md at the project root`            | `Read the project instruction file (...CLAUDE.md, AGENTS.md, or GEMINI.md...)`            |
| Read instruction (skills)      | `Read CLAUDE.md and .claude/CLAUDE.md`          | `Read the project instruction files (...whichever exist) and their subdirectory variants` |
| Subdirectory variants (agents) | `.claude/CLAUDE.md`, `.claude/rules/`           | `.claude/`, `.opencode/`, etc.                                                            |
| Reviewer dispatch context      | `The project's CLAUDE.md rules`                 | `The project instruction rules — CLAUDE.md, AGENTS.md, or GEMINI.md`                      |
| Compliance/conventions         | `CLAUDE.md compliance`, `CLAUDE.md conventions` | `project instruction compliance`, `project conventions`                                   |
| Priority hierarchy             | `user > CLAUDE.md > ops > system`               | `user > project instructions > ops > system`                                              |
| Fallback behavior              | `If no CLAUDE.md exists`                        | `If no project instruction file exists`                                                   |
| Rule proposals                 | Step 6 in ship skill                            | Removed (CLI-specific concept)                                                            |
| Task tracking (implement)      | `TaskCreate(...)` / `TaskUpdate(...)`           | Natural language: create a task entry, mark as in_progress/completed/cancelled            |
| Unsupported CLI message        | French                                          | English                                                                                   |

### Files affected

- **3 agents**: critic, implementer, test-writer (subdirectory variants)
- **8 skills**: do, plan, test, perf, refactor, implement, review-pr, ship (instruction references, task management)
- **2 sub-skills**: init/claude-code, init/opencode (category numbering)
- **1 data file**: data/bootstrap-context.md (whitespace)
- **1 doc**: README.md (all references above)

### Instruction file locations per CLI

| CLI         | Root file   | Subdirectory variant                  | Global                         |
| ----------- | ----------- | ------------------------------------- | ------------------------------ |
| Claude Code | `CLAUDE.md` | `.claude/CLAUDE.md`, `.claude/rules/` | `~/.claude/CLAUDE.md`          |
| OpenCode    | `AGENTS.md` | —                                     | `~/.config/opencode/AGENTS.md` |
| Gemini CLI  | `GEMINI.md` | —                                     | `~/.gemini/GEMINI.md`          |

## Project Instructions Files

### AGENTS.md (new — source of truth)

Contains current CLAUDE.md content with updated versioning rule:

```markdown
# ops — Project Instructions

## Architecture: scripts vs. prompts

Logic with complex deterministic branching (config detection, baseline selection,
structured parsing) lives in `scripts/`. Scripts are prefixed `ops-` to avoid PATH
namespace collisions.

Logic that requires judgment, contextual interpretation, or adaptation to unforeseen
cases stays in skills markdown files.

When in doubt: if the logic can be expressed as a pure function of inputs (files, env
vars, git state) with no need for LLM reasoning, it belongs in a script.

## Versioning

Every change must update the version in:

1. `.claude-plugin/plugin.json` (`version` field)
2. `.claude-plugin/marketplace.json` (`version` field)
3. `package.json` (`version` field)
4. `CHANGELOG.md` (new section at the top)

When adding or removing a skill, also update: 5. `data/bootstrap-context.md` (skill routing table)
```

### CLAUDE.md (simplified)

```markdown
@AGENTS.md
```

Claude Code reads CLAUDE.md, which includes AGENTS.md via `@` syntax. OpenCode reads AGENTS.md directly (native).

## package.json (new)

```json
{
  "name": "ops",
  "version": "3.0.0",
  "description": "Structured dev workflow plugin — plan, implement, debug, test, refactor, review, ship.",
  "type": "module",
  "main": ".opencode/plugins/ops.js",
  "repository": "https://github.com/gigi206/ops",
  "license": "MIT",
  "author": "Ghislain LE MEUR"
}
```

No npm dependencies. `"type": "module"` enables ESM imports. `"main"` points to the OpenCode plugin entry point.

### User installation

Users add to their `opencode.json`:

```json
{ "plugin": ["ops@git+https://github.com/gigi206/ops.git"] }
```

Version pinning:

```json
{ "plugin": ["ops@git+https://github.com/gigi206/ops.git#v3.0.0"] }
```

## .opencode/INSTALL.md (new)

User-facing installation instructions for OpenCode users. Contains the `opencode.json` plugin configuration, version pinning, usage examples, troubleshooting, and tool mapping (Claude Code → OpenCode).

## docs/opencode/README.md (new)

Detailed OpenCode guide with complete command reference, skill discovery, updating, architecture explanation (how the plugin works), tool mapping table, and troubleshooting.

## Versioning

### Version bump: 2.3.4 → 3.0.0

Breaking change (all command names change). Updated in:

1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `package.json` (new)
4. `CHANGELOG.md`

### CHANGELOG.md entry

New section at the top documenting the breaking change, OpenCode support, and all new files. Historical entries keep original `ops:*` naming.

## Files Summary

### Created (11 files)

| File                              | Purpose                                                |
| --------------------------------- | ------------------------------------------------------ |
| `AGENTS.md`                       | Project instructions — source of truth                 |
| `package.json`                    | OpenCode entry point                                   |
| `data/bootstrap-context.md`       | Skill routing table — shared by all platform adapters  |
| `.opencode/plugins/ops.js`        | OpenCode ESM plugin (skills + commands + bootstrap)    |
| `.opencode/INSTALL.md`            | Installation instructions + troubleshooting            |
| `docs/opencode/README.md`         | Detailed OpenCode guide                                |
| `scripts/ops-detect-cli.sh`       | CLI detection script (env vars + process tree)         |
| `skills/init/claude-code.md`      | Claude Code-specific diagnostic sub-skill              |
| `skills/init/opencode.md`         | OpenCode-specific diagnostic sub-skill                 |
| `skills/review-pipeline/SKILL.md` | Shared review sequence (internal skill)                |
| `skills/audit/SKILL.md`           | Full codebase audit — qlty + semgrep with cross-triage |

### Modified (42+ files)

| Category      | Files                                            | Change                                                                           |
| ------------- | ------------------------------------------------ | -------------------------------------------------------------------------------- |
| Skills (24)   | `skills/*/SKILL.md`                              | Frontmatter `name` + cross-references `ops:` → `ops-`                            |
| Skills (4)    | `do`, `perf`, `refactor`, `test`                 | Replace duplicated review steps with `ops-review-pipeline` reference             |
| Skills (1)    | `plan`                                           | Step 0: replace full `ops-init` with project command discovery                   |
| Skills (1)    | `init`                                           | Remove dual mode (plan/user-invoked), simplify to user-invoked only              |
| Skills (1)    | `instruction-priority`                           | Add "project root" clarification for instruction file locations                  |
| Skills (2)    | `review-pr`, `security`                          | Clarify instruction file locations as "at the project root"                      |
| Skills (1)    | `plan`                                           | Add "Reuse" criterion to Step 5 (Design Approaches)                              |
| Agents (1)    | `critic`                                         | Add code duplication check to Lens 1 (Missing Steps)                             |
| Skills (1)    | `review-pipeline`                                | Add build verification step before code quality                                  |
| Skills (1)    | `subagent-rules`                                 | Add LSP usage guidance for all agents                                            |
| Skills (1)    | `init`                                           | 6-phase restructure + `echo $LANG` + task tracking + no `.semgrep.yml` creation  |
| Project (1)   | `AGENTS.md`                                      | Add English-only language rule                                                   |
| Agents (11)   | `agents/*.md`                                    | `ops:` → `ops-` in descriptions                                                  |
| Hook (1)      | `hooks/session-start`                            | Remove HEREDOC, read `data/bootstrap-context.md` instead; update `ops:` → `ops-` |
| Script (1)    | `scripts/ops-semgrep-scan.sh`                    | Comment `ops:` → `ops-`                                                          |
| Config (2)    | `.claude-plugin/plugin.json`, `marketplace.json` | Version → 3.0.0                                                                  |
| Docs (1)      | `README.md`                                      | `ops:` → `ops-` + add OpenCode section                                           |
| Project (1)   | `CLAUDE.md`                                      | Replaced with `@AGENTS.md`                                                       |
| Changelog (1) | `CHANGELOG.md`                                   | New 3.0.0 entry (historical entries unchanged)                                   |

### Not modified

| File                                        | Reason                                 |
| ------------------------------------------- | -------------------------------------- |
| `skills/plan/visual-companion.md`           | No `ops:` references                   |
| `skills/plan/scripts/*`                     | No `ops:` references                   |
| `skills/implement/tdd-reference.md`         | No `ops:` references                   |
| `skills/implement/testing-anti-patterns.md` | No `ops:` references                   |
| `mise.toml`                                 | No `ops:` references, no version field |
| `.gitignore`                                | No changes needed                      |

## Risks

| Risk                                                    | Severity | Mitigation                                                                                               |
| ------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| `experimental.chat.system.transform` hook may change    | Medium   | If API changes, only `ops.js` needs updating                                                             |
| OpenCode has no programmatic agent registration         | Low      | Agents are dispatched by skills reading files, not by platform registration                              |
| `skills/init/SKILL.md` references Claude Code specifics | Low      | Out of scope — init skill is inherently platform-specific; OpenCode adaptation deferred to a future spec |
| Rename breaks existing user muscle memory               | Medium   | Justified by cross-platform compatibility; documented in CHANGELOG                                       |
| `data/bootstrap-context.md` could go stale              | Low      | Enforced by versioning rule in AGENTS.md                                                                 |

## Testing Strategy

1. **Claude Code**: Install plugin, verify all `/ops-*` commands work, verify `@AGENTS.md` inclusion, verify `hooks/session-start` reads `data/bootstrap-context.md` correctly
2. **OpenCode**: Install via git URL, verify skills are discovered, verify `/ops-*` commands work, verify bootstrap injection
3. **Rename completeness**: `grep -r 'ops:' --include='*.md' --include='*.sh' --include='*.js' --include='*.json' . && grep 'ops:' hooks/session-start` — should only match `CHANGELOG.md` historical entries

---

## ops-init CLI-Agnostic Redesign

**Status**: Implemented

## Objective

Make `/ops-init` fully functional on both Claude Code and OpenCode with feature parity. Currently the skill is 100% Claude Code-specific (plugins, marketplaces, `~/.claude/settings.json`, LSP tool, `/reload-plugins`). The redesign introduces CLI detection, shared diagnostic logic, and per-CLI sub-skills.

## Architecture

```
scripts/ops-detect-cli.sh       → Deterministic CLI detection (env vars + process tree)
skills/init/SKILL.md            → Entry point: shared logic + dispatch to sub-skill
skills/init/claude-code.md      → Claude Code sub-skill (plugins, marketplaces, LSP, MCP)
skills/init/opencode.md         → OpenCode sub-skill (LSP, MCP, formatters)
.opencode/plugins/ops.js        → Modified: inject OPENCODE=1 via shell.env hook
```

### Boundary: shared vs. CLI-specific

| Shared (SKILL.md)                         | CLI-specific (sub-skills)                        |
| ----------------------------------------- | ------------------------------------------------ |
| CLI detection (calls `ops-detect-cli.sh`) | LSP diagnostic + installation                    |
| Package manager detection                 | MCP server diagnostic + configuration            |
| Language detection via Glob               | Plugin/marketplace system (Claude Code only)     |
| qlty detection                            | Formatter diagnostic (OpenCode only)             |
| semgrep detection                         | Reload mechanism (`/reload-plugins` vs. restart) |
| jq/python3 detection                      |                                                  |
| Output format (final summary table)       |                                                  |

### Principles

- Deterministic logic (CLI detection) in `scripts/`, adaptive logic in skill markdown
- Sub-skills co-located in `skills/init/` (follows precedent: `skills/implement/tdd-reference.md`)
- Zero duplication between sub-skills — shared content stays in SKILL.md
- Adding a new CLI = new sub-skill file + detection case in script

### Unsupported CLI behavior

If the CLI cannot be detected, the skill displays:

```
  ⚠ Unsupported CLI. /ops-init is compatible with Claude Code and OpenCode only.
  Other ops skills may not work correctly with an unsupported CLI.
```

And stops. No diagnostic is run.

## Script: `ops-detect-cli.sh`

### Output format

Single line (same key=value convention as `ops-semgrep-scan.sh`):

```
cli=claude-code|opencode|unknown
```

### Detection strategy (cascade)

1. **Environment variables** (most reliable):
   - `CLAUDECODE=1` → `cli=claude-code`
   - `OPENCODE=1` (injected by plugin) → `cli=opencode`

2. **Process tree** (fallback):
   - Walk ancestors of `$$` via `/proc/<pid>/cmdline` or `ps`
   - Match `claude` or `opencode` in process names

3. **Unknown** (no match):
   - `cli=unknown`

### Conventions

- Shebang: `#!/usr/bin/env bash`
- Flags: `set -euo pipefail`
- Debug: `[[ "${DEBUG:-}" == "1" ]] && set -x`
- Exit code: always 0 (informational, not a gate)
- Naming: `ops-` prefix per AGENTS.md rule

## Plugin modification: `.opencode/plugins/ops.js`

Add `OPENCODE=1` injection in the existing `shell.env` hook. This requires a small refactor: the `output.env` guard moves outside the `if` block (it was previously only needed for PATH, but now also for the unconditional `OPENCODE` assignment):

```javascript
// Before (current code):
'shell.env': async (_input, output) => {
  const currentPath = output.env?.PATH || process.env.PATH || '';
  if (!currentPath.includes(opsScriptsDir)) {
    output.env = output.env || {};
    output.env.PATH = `${opsScriptsDir}:${currentPath}`;
  }
},

// After:
'shell.env': async (_input, output) => {
  const currentPath = output.env?.PATH || process.env.PATH || '';
  output.env = output.env || {};
  if (!currentPath.includes(opsScriptsDir)) {
    output.env.PATH = `${opsScriptsDir}:${currentPath}`;
  }
  output.env.OPENCODE = '1';
},
```

Two changes: guard line moved outside `if`, plus `OPENCODE=1` line added.

## SKILL.md (entry point) — New flow

```
Step 0: Detect CLI (calls ops-detect-cli.sh)
  → unknown: warning + stop
  → claude-code/opencode: continue

Step 1: Package managers (shared — unchanged)
Step 2: Language detection (shared — unchanged)
Step 3: CLI-specific diagnostic (dispatch to sub-skill)
  → Read and follow skills/init/claude-code.md
  → Read and follow skills/init/opencode.md
  → Sub-skill receives: detected languages
Step 4: Code quality tools (shared — unchanged: qlty + project tools)
Step 5: Security analysis tools (shared — unchanged: semgrep + jq/python3)
Step 6: Output format (shared — final summary table)
Step 7: Recommendations — propose actions for every issue found
```

### Single mode (user-invoked only)

The skill is always user-invoked (`/ops-init`): full diagnostic + installation proposals. The previous dual-mode behavior (user-invoked vs. called-from-plan) has been removed — `ops-plan` no longer calls `ops-init`.

## Sub-skill: Claude Code (`skills/init/claude-code.md`)

Extracted from current SKILL.md with no functional changes.

### Category 1 — LSP

- **Level 1**: test via `LSP documentSymbol` on a representative file per language
- **Level 2**: check marketplaces in `~/.claude/settings.json` → `extraKnownMarketplaces`
- **Level 3**: check plugins in `~/.claude/settings.json` → `enabledPlugins`
- **Level 4**: check binaries via `which`

Mandatory diagnostic table (unchanged):

```
| Language | Level 1 | Level 2 (marketplace) | Level 3 (plugin) | Level 4 (binary) | Fix |
```

Options A/B/C/D with `/reload-plugins` (unchanged).

### Category 2 — MCP Servers

Checks both `context7` and `chrome-devtools-mcp`:

- Read `~/.claude/settings.json` → `enabledPlugins` for `context7@claude-plugins-official` and `chrome-devtools-mcp@chrome-devtools-plugins`
- Check `extraKnownMarketplaces` for required marketplaces
- Options A/B/C for installation (unchanged from current SKILL.md)

## Sub-skill: OpenCode (`skills/init/opencode.md`)

### Category 1 — LSP

OpenCode has 37 built-in LSP servers with auto-detection by file extension and auto-download (3 strategies: bun install, GitHub binary, native package manager — plus 14 servers requiring manual install). Source: `packages/opencode/src/lsp/server.ts`.

The diagnostic flow is inverted compared to Claude Code: OpenCode auto-detects and auto-installs, so the diagnostic verifies that it **works**, not that it's **configured**.

- **Level 1**: test LSP via the `diagnostics` tool
  - OpenCode exposes a `diagnostics` tool (not `LSP documentSymbol` like Claude Code) that returns LSP diagnostics for a file. It is only available when at least one LSP client is running.
  - Call `diagnostics` with `file_path` set to a representative file per detected language
  - If results (even empty diagnostics) → LSP server is running for this language
  - If error or tool unavailable → skip to Level 2 (binary check)

- **Level 2**: check binary
  - `which <binary>` for the expected server
  - If absent and auto-download not disabled → server will be auto-downloaded on next use, inform user
  - If absent and `OPENCODE_DISABLE_LSP_DOWNLOAD=true` → signal manual installation needed

- **Level 3**: check config
  - Read `./opencode.json` and `~/.config/opencode/opencode.json` → `lsp` key
  - Check for servers explicitly `disabled: true`
  - Check for conflicts (e.g., `ty` enabled auto-disables `pyright`)

Mandatory diagnostic table:

```
| Language   | LSP test | Binary     | Config        | Fix                                   |
|------------|----------|------------|---------------|---------------------------------------|
| Python     | ✗        | pyright ✗  | not disabled  | Auto-download on next use             |
| Go         | ✓        | gopls ✓    | —             | —                                     |
| TypeScript | ✗        | ts-ls ✗    | disabled:true | Remove disabled in opencode.json      |
```

Options:

- **A)** Continue — missing servers will be auto-installed on next use
- **B)** Force install now (run download commands)
- **C)** Continue without LSP

After config changes or manual install: OpenCode restart required (no equivalent to `/reload-plugins`).

### Category 2 — MCP Servers

Checks `context7` and `chrome-devtools-mcp` (both are standard MCP servers configurable on any CLI):

- Primary method: read `./opencode.json` and `~/.config/opencode/opencode.json` → `mcp` key
- Fallback: run `opencode mcp list` if config files don't exist or are unreadable
- Check for `context7` and `chrome-devtools-mcp` presence
- If absent, propose the JSON blocks and target file (`opencode.json`)

Options: A (I edit `opencode.json`) / B (I'll handle it) / C (skip)

### Bonus — Formatters

OpenCode has 30+ built-in formatters (auto-detected if binary is on PATH).

- **Project tools take priority**: if `.prettierrc`, `.editorconfig`, `rustfmt.toml`, `biome.json`, etc. exist, report them as source of truth
- Read `opencode.json` → `formatter` key for overrides
- If conflict between OpenCode built-in formatter and project tool → flag it
- Informational only — no automatic action

## Files Summary

### Created (3 files)

| File                         | Purpose                                        |
| ---------------------------- | ---------------------------------------------- |
| `scripts/ops-detect-cli.sh`  | CLI detection script (env vars + process tree) |
| `skills/init/claude-code.md` | Claude Code-specific diagnostic sub-skill      |
| `skills/init/opencode.md`    | OpenCode-specific diagnostic sub-skill         |

### Modified (2 files)

| File                       | Change                                                                                      |
| -------------------------- | ------------------------------------------------------------------------------------------- |
| `skills/init/SKILL.md`     | Rewrite: keep shared logic, add CLI dispatch to sub-skills, single mode (user-invoked only) |
| `.opencode/plugins/ops.js` | Add `OPENCODE=1` env var injection in `shell.env` hook                                      |

### Not modified

| File                                                             | Reason                                                                                                                                                 |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `hooks/session-start`                                            | `CLAUDECODE=1` observed in child shell env at runtime (set by Claude Code, not by ops). If absent in older versions, process tree fallback handles it. |
| `data/bootstrap-context.md`                                      | No skill added or removed                                                                                                                              |
| `.claude-plugin/plugin.json`, `marketplace.json`, `package.json` | No version bump — changes amend the 3.0.0 release (user override of AGENTS.md versioning rule)                                                         |

## Risks

| Risk                                                     | Severity | Mitigation                                                                   |
| -------------------------------------------------------- | -------- | ---------------------------------------------------------------------------- |
| `CLAUDECODE` env var not set in all Claude Code versions | Low      | Fallback to process tree detection                                           |
| `OPENCODE=1` injection requires plugin update            | Low      | Two-line change in existing `shell.env` hook (guard relocation + assignment) |
| OpenCode LSP tool is experimental                        | Medium   | Fallback to `which` binary check if LSP tool unavailable                     |
| `opencode mcp list` output format may change             | Low      | Parse defensively, fall back to reading `opencode.json` directly             |
| OpenCode repo archived (moved to charmbracelet/crush)    | Medium   | Current OpenCode version (1.3.9) works; monitor Crush for breaking changes   |
| Process tree detection fragile across OS/container       | Low      | Only used as fallback; env var detection is primary                          |

## Testing Strategy

1. **Claude Code**: run `/ops-init`, verify detection (`cli=claude-code`), verify all 4 categories work as before
2. **OpenCode**: run `/ops-init`, verify detection (`cli=opencode`), verify LSP/MCP/formatter diagnostics
3. **Unknown CLI**: unset `CLAUDECODE` and `OPENCODE` env vars, run script directly, verify `cli=unknown` + warning message
4. **Detection script**: `bash scripts/ops-detect-cli.sh` standalone — verify output format and all 3 detection paths
