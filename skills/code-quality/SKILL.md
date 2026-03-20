---
name: ops:code-quality
description: "Internal: run code formatting and linting on modified files. Activated before code review in implement and do skills."
user-invocable: false
---

# Code Quality — Format & Lint

Run formatting and linting on all modified files before code review. This ensures reviewers evaluate logic, not style.

## Step 1: Detect tools

Check the project for formatter/linter configuration:

- **Formatter**: `.prettierrc`, `pyproject.toml` (`[tool.black]` or `[tool.ruff.format]`), `rustfmt.toml`, `.clang-format`, `gofmt`/`goimports` (built-in), `.editorconfig`, `biome.json`, etc.
- **Linter**: `.eslintrc*`, `pyproject.toml` (`[tool.ruff]`, `[tool.pylint]`), `clippy` (Rust), `golangci-lint`, `.rubocop.yml`, etc.
- **Combined**: `deno fmt`/`deno lint`, `biome check`, `ruff format`/`ruff check`

Also check `package.json` scripts, `Makefile` targets, or CLAUDE.md for project-specific commands (e.g., `make lint`, `npm run format`).

If no formatter or linter is detected, skip and note it for the reviewer.

## Step 2: Format

Run the detected formatter on modified files only (use `git diff --name-only` to scope).

- Do NOT format files that were not modified by the current work.
- If the formatter changes files, stage the formatting changes separately so the diff is reviewable.

## Step 3: Lint

Run the detected linter on modified files.

- **Errors**: fix them before proceeding.
- **Warnings**: fix if trivial, otherwise note for the reviewer.
- If linting fails after formatting, the formatter and linter may conflict — note this for the user.

## Step 4: Report

Output a short summary:

```
## Code Quality
- Formatter: <tool> — <N files formatted / no changes>
- Linter: <tool> — <N errors fixed, N warnings remaining / clean>
```

If no tools were detected:
```
## Code Quality
- No formatter or linter detected in project. Skipped.
```
