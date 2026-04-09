# Step 3 — Project Linters

Mark the task "Init: project linters" as `in_progress` now via `TaskUpdate`.

Detect linters and formatters configured in the project. Scan for config files:

- `package.json` → scripts and devDependencies (eslint, prettier, biome, etc.)
- `pyproject.toml` / `setup.cfg` → ruff, black, flake8, mypy, pylint
- `.eslintrc.*`, `.prettierrc.*`, `biome.json`, `.stylelintrc.*`
- `Cargo.toml` → clippy (built into cargo)
- `go.mod` → golangci-lint (check `.golangci.yml`)
- `.rubocop.yml` → rubocop
- `Makefile` → lint/format targets

For each detected linter, verify it is installed: `which <binary>`.

## Stop-and-propose

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

## ✅ End of Step 3

Before proceeding, verify:
- [ ] You scanned for linter config files (package.json, pyproject.toml, .eslintrc, etc.).
- [ ] For each detected linter, you verified it is installed via `which <binary>`.
- [ ] If any configured linter is not installed: you presented the `## Project Linters` table and the A/B/C options, and got the user's decision.
- [ ] You only checked linters relevant to the languages detected in Step 0b.

Mark the task "Init: project linters" as `completed` via `TaskUpdate`.

**→ Next: read `skills/init/step-04-linter-prerequisites.md` now and execute Step 4.**

Do NOT continue without reading that file first.
