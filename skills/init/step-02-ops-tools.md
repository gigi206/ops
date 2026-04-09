# Step 2 — Ops Tools (strongly recommended)

Mark the task "Init: ops tools" as `in_progress` now via `TaskUpdate`.

These tools power the review pipeline and security gate. Without them, several ops skills run in degraded mode.

## 2a. qlty

Check if `qlty` is available: `which qlty`
- If found: check for `.qlty/qlty.toml` in the project root.
  - Config present: report version (`qlty --version`), note as "installed + configured"
  - Config absent: report version, note as "installed — no project config"
- If not found: note as **missing (strongly recommended)**

## 2b. semgrep

Check if `semgrep` is available: `which semgrep`
- If found: report version (`semgrep --version`), note as "installed"
- If not found: note as **missing (strongly recommended)**

**Do NOT create a `.semgrep.yml` file.** `ops-semgrep-scan.sh` uses `--config auto` which provides semgrep's community rules — these are comprehensive and maintained. A custom config is only useful if the project has project-specific rules, and that is the user's responsibility.

## 2c. JSON parser (for semgrep)

`ops-semgrep-scan.sh` uses jq or python3 to count findings. Check: `which jq` or `which python3`. If neither, note it (not a blocker).

## Stop-and-propose

**Always stop here** if qlty is missing, semgrep is missing, **OR** qlty lacks project configuration (`.qlty/qlty.toml` absent). qlty without project config cannot detect the right plugins — `qlty init` is needed. semgrep without local config is fine (`--config auto` is the default).

```
## Ops Tools
- qlty: <status>
- semgrep: <status>
- JSON parser: <status>
```

Present issues and propose installation. **Only show install commands for package managers the user actually has** (from Step 0c).

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

## ✅ End of Step 2

Before proceeding, verify:
- [ ] You ran `which qlty` and checked for `.qlty/qlty.toml`.
- [ ] You ran `which semgrep`.
- [ ] You ran `which jq` or `which python3`.
- [ ] You output the `## Ops Tools` summary block.
- [ ] If qlty is missing OR lacks `.qlty/qlty.toml`, OR semgrep is missing: you presented the A/B/C options to the user and got their decision.
- [ ] You did NOT create a `.semgrep.yml` file.
- [ ] You only showed install commands for package managers detected in Step 0c.

Mark the task "Init: ops tools" as `completed` via `TaskUpdate`.

**→ Next: read `skills/init/step-03-project-linters.md` now and execute Step 3.**

Do NOT continue without reading that file first.
