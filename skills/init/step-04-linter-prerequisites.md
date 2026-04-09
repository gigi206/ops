# Step 4 — Linter Prerequisites

Mark the task "Init: linter prerequisites" as `in_progress` now via `TaskUpdate`.

For each **installed** linter (from Step 3), check that its runtime dependencies are met. This covers two levels:

## Level 1: Package/dependency environment

- **Node-based linters** (eslint, prettier, biome, stylelint): check `node_modules/` exists. If `package.json` exists but no `node_modules/`, propose install based on lockfile (`npm install` / `yarn install` / `pnpm install`).
- **Python projects**: check if dependencies are installed. Read `pyproject.toml` / `requirements.txt` to find declared dependencies. Check if they are importable (`python3 -c "import <pkg>"` for key packages) or if a venv/docker is used. Propose multiple options when applicable:
  - `pip install -r requirements.txt` (global)
  - `python -m venv .venv && .venv/bin/pip install -r requirements.txt` (venv)
  - `uv sync` (if uv is available)
  - docker-based (if Makefile/compose handles deps)
- **Go projects**: check `go.sum` exists. If `go.mod` but no `go.sum`, propose `go mod tidy`.
- **Ruby projects**: check `Gemfile.lock`. If `Gemfile` but no lock, propose `bundle install`.

## Level 2: Linter plugins and type stubs

- **mypy** → check for missing type stubs by examining mypy config (`mypy.ini`, `pyproject.toml [tool.mypy]`). Common stubs: `types-requests`, `django-stubs`, `types-pyyaml`, etc.
- **eslint** → check for referenced plugins in config that aren't in `node_modules/`
- **ruff/pylint** → check if the linted project's own packages are importable (linters need to resolve imports to lint correctly)

## Stop-and-propose

If any prerequisite is missing, **stop and propose solutions**. Present **multiple installation methods** when available — let the user choose:

```
## Linter Prerequisites
| Prerequisite | For | Status | Fix options |
|---|---|---|---|
| dependencies | ruff, mypy | missing | pip / venv / uv / docker |
| node_modules | eslint, prettier | missing | npm / yarn / pnpm |
| type stubs | mypy | missing | pip install types-xxx |
```

> **A)** Install with <recommended method> (I run the commands)
> **B)** Install with <alternative method>
> **C)** I'll handle it myself
> **D)** Skip

Wait for the user's decision.

---

## ✅ End of Step 4

Before proceeding, verify:
- [ ] For each installed linter (from Step 3), you checked Level 1 (package/dependency environment).
- [ ] For applicable linters, you checked Level 2 (plugins and type stubs).
- [ ] If any prerequisite is missing: you presented the `## Linter Prerequisites` table and the A/B/C/D options, and got the user's decision.

Mark the task "Init: linter prerequisites" as `completed` via `TaskUpdate`.

**→ Next: read `skills/init/step-05-build-tools.md` now and execute Step 5.**

Do NOT continue without reading that file first.
