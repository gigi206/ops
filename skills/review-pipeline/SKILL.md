---
name: ops-review-pipeline
description: "Internal: build verification → code quality → security gate → code review → project instruction check. Shared final review sequence used by do, perf, refactor, test."
user-invocable: false
---

# Review Pipeline

Shared final review sequence. The calling skill specifies the **code-reviewer context** — skill-specific items to pass to the code-reviewer alongside the diff.

## Step 1: Build Verification

If the project has a build/compile step (detected from `Makefile`, `package.json` scripts, `tsconfig.json`, `Cargo.toml`, `go.mod`, etc.), propose to the user:

> "Do you want to build/compile before code review?"
> **A)** Yes — run `<detected build command>`
> **B)** No — skip to code review

If the user chooses A, run the build command. If it fails, fix compilation errors before proceeding. If no build step is detected, skip silently.

## Step 2: Code Quality

Run the `ops-code-quality` process on all modified/created files. Fix any issues before dispatching reviewers.

Do NOT brute-force tool execution (e.g., retrying a missing linter multiple times). If no tools are detected, produce the "no tools detected" report variant.

<HARD-GATE-SECURITY>

## Step 3: Security Gate + Code Review

### Security Gate (MANDATORY — do NOT skip)

You MUST read the `ops-security-gate` skill file and follow its process on the complete diff BEFORE dispatching the code-reviewer. If you dispatch the code-reviewer without having run the security gate, you have FAILED this pipeline.

<HARD-GATE-SEMGREP>

Run SAST via `ops-semgrep-scan.sh`. This is the only sanctioned path.

1. **Check the script first, not semgrep**: run `command -v ops-semgrep-scan.sh`. If it prints a path, the script is available — use it. Do NOT run `which semgrep` or any other probe before this check. Do NOT assume the script is absent without running the check.
2. **If the script is available**: run `ops-semgrep-scan.sh [--config <path>] <modified files>` and parse its key=value output. The script already handles the "semgrep not installed", "no files", "error", and "no findings" cases — you do not need to pre-check any of these. Never re-implement diff-aware baseline selection or JSON parsing yourself.
3. **If and only if `command -v ops-semgrep-scan.sh` fails**: then (and only then) fall back to `semgrep --config=auto <modified files>`. State in your triage: "fallback: ops-semgrep-scan.sh not on PATH".

Calling raw `semgrep` while the script is available is a HARD-GATE violation: it bypasses diff-aware baseline selection and the structured output contract that downstream steps rely on. Asserting "semgrep not installed" without running either command is also a violation — the script is the source of truth for that verdict.

</HARD-GATE-SEMGREP>

Parse the script's key=value output format.

You MUST output the structured triage block:

```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- SAST (semgrep): <N new findings> / clean / not found / error
- Security-reviewer dispatch: YES / NOT NEEDED
```

If triggers match, dispatch the security-reviewer in the **same message** as the code-reviewer (see `ops-subagent-rules`). If your diff touches authentication, authorization, permissions, secrets, encryption, or CI/CD — security-reviewer dispatch is mandatory regardless of diff size.

</HARD-GATE-SECURITY>

### Code Review

Dispatch the **code-reviewer** agent with:
- The complete diff (`git diff`)
- The skill-specific context provided by the calling skill
- The project instruction rules — `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` (if applicable)

**One cycle maximum**: fix issues, then re-dispatch every reviewer that found issues (code-reviewer AND security-reviewer if dispatched). Wait for their verdicts and verify approval before proceeding. If still failing after one cycle → escalate to user.

## Step 4: Check Project Instructions

Read the project instruction files (`CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` — whichever exist at the project root) and their subdirectory variants. Verify all applicable rules were followed. Fix violations before completing.
