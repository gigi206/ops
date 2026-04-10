---
name: ops-audit
description: "Full codebase audit — code quality (qlty) + security (semgrep). Produces a unified report with triage and actionable fixes."
---

# /ops-audit — Full Codebase Audit

**Read `data/common_instructions.md` before executing this skill.**

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Purpose

Run a **full codebase** code quality and security audit. Unlike the incremental checks in the review pipeline (diff-only), this scans everything.

Use cases:
- First arrival on a project
- Pre-release audit
- Periodic health check
- After enabling new qlty plugins or semgrep rules

## Workflow

```
1. Detect tools → 2. Code quality (qlty) → 3. Security (semgrep) → 4. Cross-triage → 5. Report
```

---

## Step 1: Detect Tools

Check availability:
- `which qlty` + `.qlty/qlty.toml` exists → qlty available
- `which semgrep` → semgrep available

If **neither** is available: stop and propose `/ops-init` to install them.

If **one** is available: run what we have, note the missing tool in the report.

---

## Step 2: Code Quality (qlty)

Skip if qlty is not available.

### 2a. Lint

Run `qlty check --all` (full codebase, not just git-changed files).

- **Errors**: list by file, grouped by rule.
- **Warnings**: list separately.
- **Security findings** from qlty plugins (trivy, trufflehog, osv-scanner, bandit, checkov): set aside for Step 4 (cross-triage). Do NOT mix with lint findings.

If `qlty check` crashes or times out, log the error and continue.

### 2b. Smells

Run `qlty smells --all`.

Report:
- **Duplication**: file pairs with duplicated blocks.
- **Other smells**: high return count, long methods, etc.

If `qlty smells` crashes, skip and continue.

### 2c. Metrics

Run `qlty metrics --all --functions`.

**Only report functions exceeding thresholds:**
- Cognitive complexity > 15
- Cyclomatic complexity > 20

If no function exceeds thresholds: "all within thresholds". Do NOT dump the full table.

If `qlty metrics` crashes, skip and continue.

---

## Step 3: Security (semgrep)

Skip if semgrep is not available.

### Config detection

Same logic as `ops-semgrep-scan.sh`:
1. `.semgrep/` with `.yml`/`.yaml` files → use as config
2. `.semgrep.yml` → use as config
3. Fallback → `--config auto`

### Scan

Run `semgrep scan --config <detected> --json .` (full codebase, no `--baseline-commit`).

Parse `results[]` from the JSON output. For each finding, extract:
- `path`, `start.line`, `end.line`
- `check_id` (rule name)
- `extra.message`
- `extra.severity` (INFO / WARNING / ERROR)

Group findings by severity.

If semgrep crashes, log the error and continue.

---

## Step 4: Cross-triage

This is where the unified context pays off. Cross-reference findings from qlty and semgrep:

1. **Deduplicate**: if qlty security plugins and semgrep flag the same file:line for the same issue, merge into one finding. Prefer the more detailed description.
2. **Correlate**: a qlty complexity hotspot (Step 2c) co-located with a semgrep finding suggests a high-risk area — flag it.
3. **Classify** every finding into one of:
   - **Critical** — security vulnerability with exploitation path, hardcoded secrets, or exposed credentials
   - **High** — security finding (WARNING/ERROR) or code quality error in critical path
   - **Medium** — warnings, moderate complexity, duplication in active code
   - **Low** — info-level findings, smells in low-traffic code, style issues

---

## Step 5: Report

Output a structured report:

```
## Audit Report

### Summary
- Tools: qlty <version> / semgrep <version> / <tool> not available
- Files scanned: <N>
- Total findings: <N> (Critical: <N>, High: <N>, Medium: <N>, Low: <N>)

### Critical
<list with file:line, rule, description>

### High
<list with file:line, rule, description>

### Medium (top 10)
<list — cap at 10, note total if more>

### Low
<count only — do not list individually>

### Complexity Hotspots
<functions exceeding thresholds, if any>

### Duplication
<file pairs, if any>

### Recommended Actions
1. <most impactful fix first>
2. ...
```

**Rules:**
- Critical and High findings get full detail (file, line, rule, description, suggested fix).
- Medium findings are capped at 10 entries to keep the report readable. Note total count.
- Low findings are count-only.
- Recommended Actions are ordered by impact — fix the most dangerous or widespread issue first.
- If the report is too large, offer to write it to `docs/audit-report-YYYY-MM-DD.md`.
