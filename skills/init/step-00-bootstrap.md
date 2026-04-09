# Step 0 — Bootstrap

This is the first step of `/ops-init`. Before doing any diagnostic work, you must (a) detect the output language, (b) create the 7-task progress checklist, and (c) run the bootstrap diagnostics.

## Preamble 1 — Language detection (CRITICAL, runs FIRST)

Your **very first action** must be to run `echo $LANG` via Bash. This determines the language for all output. Parse the result (e.g., `fr_FR.UTF-8` → French, `en_US.UTF-8` → English). **All subsequent output — diagnostics, tables, proposals, summaries — must be in that language.** Technical terms and tool names stay in English.

If you start producing diagnostic output without having first detected the language, you have FAILED this skill (per the `<HARD-GATE-LANGUAGE>` block in `SKILL.md`).

## Preamble 2 — Create the task checklist

Create a task for each step of the init process (all at once, in a single `TaskCreate` call):

1. "Init: bootstrap"
2. "Init: recap"
3. "Init: ops tools"
4. "Init: project linters"
5. "Init: linter prerequisites"
6. "Init: build tools"
7. "Init: LSP"

Each task will be marked as `in_progress` at the start of the corresponding step file, and as `completed` at its end.

Immediately after creating the checklist, mark the task "Init: bootstrap" as `in_progress` via `TaskUpdate`.

## 0a. Detect CLI

Run `ops-detect-cli.sh` (it is on PATH) and parse the output.

- If `cli=unknown`:
  ```
  ⚠ Unsupported CLI. /ops-init is compatible with Claude Code and OpenCode only.
  Other ops skills may not work correctly with an unsupported CLI.
  ```
  Stop here. Do not run any diagnostic.
- If `cli=claude-code` or `cli=opencode`: note the result and continue.

## 0b. Detect Languages

Scan the codebase to identify the primary languages and frameworks. Use a **single** Glob call with combined extensions:

```
**/*.{py,ts,tsx,js,jsx,go,rs,java,rb,yaml,yml,sh,tf}
```

Do NOT glob each extension separately — that wastes tokens.

Also check config files that indicate the stack (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `Makefile`, etc.)

**Ansible detection:** if `.yaml`/`.yml` files exist, check for Ansible markers: `ansible.cfg`, `galaxy.yml`, `playbooks/`, `roles/`, `inventory/`, or YAML files containing `hosts:` + `tasks:` patterns.

## 0c. Detect Package Managers

**System**: `which apt`, `which dnf`, `which pacman`, `which apk`, `which zypper`.
**User-installed**: `which brew`, `which nix`, `which mise`, `which pipx`.

## 0d. Summary output

```
## Environment
- CLI: <claude-code / opencode> (vX.Y)
- Languages: <list>
- Package managers: <system: apt> <user: brew, mise>
```

---

## ✅ End of Step 0

Before proceeding, verify:
- [ ] You ran `echo $LANG` as your very first action and chose the output language accordingly.
- [ ] The 7 tasks above exist in the task list (created via a single `TaskCreate` call).
- [ ] You ran `ops-detect-cli.sh` and confirmed `cli=claude-code` or `cli=opencode` (if `cli=unknown`, you already stopped with the warning message).
- [ ] You scanned the codebase using a SINGLE glob call with combined extensions.
- [ ] You detected package managers (system + user-installed).
- [ ] You output the `## Environment` summary block in the correct language.

Mark the task "Init: bootstrap" as `completed` via `TaskUpdate`.

**→ Next: read `skills/init/step-01-recap.md` now and execute Step 1.**

Do NOT continue without reading that file first.
