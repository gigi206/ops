# Installing ops for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add the `plugin` field to your **global** OpenCode config at `~/.config/opencode/opencode.json`:

```json
{
  "plugin": ["ops@git+https://github.com/gigi206/ops.git"]
}
```

If the file already exists, add the `"plugin"` key to the existing JSON object (do not overwrite the file).

Restart OpenCode. Verify by running: `/ops-init`

> **Note:** You can also install per-project by adding the same config to `opencode.json` at the project root, but global install is recommended so ops is available in all your projects.

## Usage

Use OpenCode's native `skill` tool or slash commands:

```
/ops-plan add rate limiting to the API
/ops-do fix the typo in the header
/ops-debug the login page returns a 500 error
```

Or use the skill tool directly:

```
use skill tool to list skills
use skill tool to load ops-plan
```

## What you get

- Slash commands dynamically registered from skills (one per user-invocable skill)
- 26 skills (18 user-invocable + 8 internal phases) automatically registered
- Bootstrap context injected into every session (skill routing suggestions)
- `scripts/` added to PATH (security analysis tools)

## Updating

ops updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugin": ["ops@git+https://github.com/gigi206/ops.git#v3.0.0"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -i ops`
2. Verify the plugin line in your `opencode.json`
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use `skill` tool to list what's discovered
2. Check that the plugin is loading (see above)

### Tool mapping

When skills reference Claude Code tools:

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

## Getting Help

- Report issues: https://github.com/gigi206/ops/issues
- Full documentation: https://github.com/gigi206/ops
