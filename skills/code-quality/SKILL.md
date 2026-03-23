---
name: ops:code-quality
description: "Internal: run code formatting and linting on modified files (qlty or project tools). Activated before code review in implement and do skills."
user-invocable: false
---

# Code Quality — Format & Lint

Run formatting and linting on all modified files before code review. This ensures reviewers evaluate logic, not style.

## Step 1: Detect tools

### Unified tool (priority)

Check if `qlty` is available (`which qlty`) AND the project has a `.qlty/qlty.toml` config:
- If both present: use qlty for formatting and linting (Steps 2-3). Skip individual tool detection.
- If qlty is in PATH but no `.qlty/qlty.toml`: skip qlty (it needs project-level init). Fall through to individual tools.
- If qlty is not in PATH: fall through to individual tools.

### Individual tools (fallback)

Check the project for formatter/linter configuration:

- **Formatter**: `.prettierrc`, `pyproject.toml` (`[tool.black]` or `[tool.ruff.format]`), `rustfmt.toml`, `.clang-format`, `gofmt`/`goimports` (built-in), `.editorconfig`, `biome.json`, etc.
- **Linter**: `.eslintrc*`, `pyproject.toml` (`[tool.ruff]`, `[tool.pylint]`), `clippy` (Rust), `golangci-lint`, `.rubocop.yml`, etc.
- **Combined**: `deno fmt`/`deno lint`, `biome check`, `ruff format`/`ruff check`

Also check `package.json` scripts, `Makefile` targets, or CLAUDE.md for project-specific commands (e.g., `make lint`, `npm run format`).

If no tools are detected (neither qlty nor individual), skip and note it for the reviewer.

## Step 2: Format

If qlty: run `qlty fmt` on modified files (qlty defaults to git-changed files, no explicit file list needed).

Otherwise: run the detected formatter on modified files only (use `git diff --name-only` to scope).

- Do NOT format files that were not modified by the current work.
- If the formatter changes files, stage the formatting changes separately so the diff is reviewable.

If qlty or the formatter crashes or times out, log the error and continue — the tool is optional.

## Step 3: Lint

If qlty: run `qlty check` on modified files (qlty defaults to git-changed files).

Otherwise: run the detected linter on modified files.

- **Errors**: fix them before proceeding.
- **Warnings**: fix if trivial, otherwise note for the reviewer.
- If linting fails after formatting, the formatter and linter may conflict — note this for the user.

If qlty or the linter crashes or times out, log the error and continue — the tool is optional.

## Step 4: Report

Output a short summary:

If qlty was used:
```
## Code Quality
- Formatter: qlty fmt — <N files formatted / no changes>
- Linter: qlty check — <N errors fixed, N warnings remaining / clean>
```

If individual tools were used:
```
## Code Quality
- Formatter: <tool> — <N files formatted / no changes>
- Linter: <tool> — <N errors fixed, N warnings remaining / clean>
```

If no tools were detected:
```
## Code Quality
- No code quality tools detected. Run `/ops:setup` for diagnostic.
```
