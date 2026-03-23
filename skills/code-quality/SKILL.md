---
name: ops:code-quality
description: "Internal: run code formatting, linting, and structural analysis on modified files (qlty or project tools). Activated before code review in implement, do, and other skills."
user-invocable: false
---

# Code Quality — Format, Lint & Structural Analysis

Run formatting, linting, and structural analysis on all modified files before code review. This ensures reviewers evaluate logic, not style.

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
- **Security findings**: qlty may include security plugins (trivy, trufflehog, osv-scanner, bandit, checkov). If `qlty check` reports findings from these plugins, do NOT fix them here — note them in the report under a `Security findings from qlty` line. The `ops:security-gate` process will use this information when deciding whether to dispatch the security-reviewer.
- If linting fails after formatting, the formatter and linter may conflict — note this for the user.

If qlty or the linter crashes or times out, log the error and continue — the tool is optional.

## Step 4: Smells (structural analysis)

If qlty is available (detected in Step 1): run `qlty smells` (defaults to git-changed files, no explicit file list needed).

This detects code smells that formatting and linting miss: duplication across files, high cyclomatic complexity, functions with too many returns, etc.

To compare against a specific base branch: `qlty smells --upstream <base-ref>`. Use `--no-snippets` to reduce output verbosity if needed.

- **New smells** (introduced by the current work): fix if trivial (extract function/constant, inline duplicate). If the fix requires structural refactoring, do not fix — flag with file locations for the reviewer.
- **Pre-existing smells** (both locations existed before the current work): do not touch. Mention in the report only.
- If `qlty smells` is not available or crashes, skip and continue.

## Step 5: Metrics (complexity hotspots)

If qlty is available (detected in Step 1): run `qlty metrics --functions <modified files>` on the modified files.

This provides per-function metrics: cyclomatic complexity, cognitive complexity, LOC, fields, and LCOM (cohesion).

The output lists ALL functions in the modified files — most will be fine. **Only report functions that exceed a threshold:**
- **Cognitive complexity > 15** — hard to understand, error-prone.
- **Cyclomatic complexity > 20** — too many branches.

In the report, list only the functions above these thresholds with their values. If no function exceeds the thresholds, report "all within thresholds". Do NOT dump the full metrics table — it's noise.

Do NOT fix complexity issues here — they are informational for the reviewer.
If `qlty metrics` is not available or crashes, skip and continue.

## Step 6: Report

Output a short summary:

If qlty was used:
```
## Code Quality
- Formatter: qlty fmt — <N files formatted / no changes>
- Linter: qlty check — <N errors fixed, N warnings remaining / clean>
- Security findings from qlty: <list> / none
- Smells: qlty smells — <N issues found (N new, N pre-existing) / clean>
- Metrics: <N functions with high complexity> / all within thresholds
```

If individual tools were used:
```
## Code Quality
- Formatter: <tool> — <N files formatted / no changes>
- Linter: <tool> — <N errors fixed, N warnings remaining / clean>
- Smells: skipped (qlty not available)
- Metrics: skipped (qlty not available)
```

If no tools were detected:
```
## Code Quality
- No code quality tools detected. Run `/ops:setup` for diagnostic.
```
