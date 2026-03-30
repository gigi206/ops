# ops for OpenCode

Complete guide for using ops with [OpenCode.ai](https://opencode.ai).

## Installation

Add the `plugin` field to your **global** OpenCode config at `~/.config/opencode/opencode.json`:

```json
{
  "plugin": ["ops@git+https://github.com/gigi206/ops.git"]
}
```

If the file already exists, add the `"plugin"` key to the existing JSON object (do not overwrite the file).

Restart OpenCode. The plugin auto-installs via Bun and registers all skills and slash commands automatically.

Verify by running: `/ops-init`

## Usage

### Slash commands

```
/ops-plan add rate limiting to the API
/ops-do fix the typo in the header
/ops-debug the login page returns a 500 error
```

### Finding skills

Use OpenCode's native `skill` tool to list all available skills:

```
use skill tool to list skills
```

### Loading a skill

```
use skill tool to load ops-plan
```

### Available commands

| Command              | Description                                                        |
| -------------------- | ------------------------------------------------------------------ |
| `/ops-plan`          | Clarify intent, research, and plan before writing code             |
| `/ops-implement`     | Execute a validated plan task by task                              |
| `/ops-ship`          | Commit, PR, and capture learnings                                  |
| `/ops-full`          | Full pipeline: plan, implement, and ship in a single session       |
| `/ops-do`            | Lightweight structured workflow: research, execute, verify, review |
| `/ops-debug`         | Systematic debugging: investigate, hypothesize, fix                |
| `/ops-test`          | Add tests to existing untested code                                |
| `/ops-refactor`      | Restructure code without changing behavior                         |
| `/ops-perf`          | Performance investigation and optimization                         |
| `/ops-review-pr`     | Review an external PR                                              |
| `/ops-research`      | Autonomous codebase and documentation exploration                  |
| `/ops-brainstorm`    | Interactive brainstorming to clarify needs                         |
| `/ops-review`        | Receive and evaluate code review feedback                          |
| `/ops-security`      | On-demand security review                                          |
| `/ops-audit`         | Full codebase audit — code quality (qlty) + security (semgrep)     |
| `/ops-clone-analyze` | Clone and analyze an external repository                           |
| `/ops-init`          | Detect CLI, diagnose environment and available tools               |
| `/ops-verify`        | Evidence before claims                                             |

## Updating

ops updates automatically when you restart OpenCode. The plugin is re-installed from the git repository on each launch.

To pin a specific version:

```json
{
  "plugin": ["ops@git+https://github.com/gigi206/ops.git#v3.0.0"]
}
```

## How it works

The plugin (`.opencode/plugins/ops.js`) does three things:

1. **Registers the skills directory** via the `config` hook, so OpenCode discovers all 26 ops skills without symlinks or manual config.
2. **Registers the 11 ops agents** via `config.agent`, making them available as subagent types in the Task tool.
3. **Injects bootstrap context** via the `experimental.chat.system.transform` hook, adding skill routing awareness to every conversation.
4. **Adds `scripts/` to PATH** via the `shell.env` hook, making security analysis tools available.

### Tool mapping

Skills written for Claude Code are adapted for OpenCode:

| Claude Code               | OpenCode    |
| ------------------------- | ----------- |
| `Agent`                   | `task`      |
| `Bash`                    | `bash`      |
| `Read`                    | `read`      |
| `Write`                   | `write`     |
| `Edit`                    | `edit`      |
| `Glob`                    | `glob`      |
| `Grep`                    | `grep`      |
| `Skill`                   | `skill`     |
| `WebFetch`                | `webfetch`  |
| `WebSearch`               | `websearch` |
| `TaskCreate`/`TaskUpdate` | `todowrite` |

## Troubleshooting

### Plugin not loading

1. Check OpenCode logs: `opencode run --print-logs "hello" 2>&1 | grep -i ops`
2. Verify the plugin line in your `opencode.json` is correct
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use OpenCode's `skill` tool to list available skills
2. Check that the plugin is loading (see above)
3. Each skill needs a `SKILL.md` file with valid YAML frontmatter

### Bootstrap not appearing

1. Check OpenCode version supports `experimental.chat.system.transform` hook
2. Restart OpenCode after config changes

## Getting help

- Report issues: https://github.com/gigi206/ops/issues
- Main documentation: https://github.com/gigi206/ops
- OpenCode docs: https://opencode.ai/docs/
