---
name: ops:security
description: "On-demand security review of code, infrastructure, or pipeline changes."
---

# /ops:security — On-demand security review

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Purpose

Launch a deep security review on demand — outside of `/ops:implement` or `/ops:debug`. Use this when you want a standalone security assessment of staged changes, a specific file, a directory, or an entire feature branch.

---

## Inputs

The user may invoke this skill in several ways:

| Invocation                     | Scope                                         |
|--------------------------------|-----------------------------------------------|
| `/ops:security` (no args)      | Staged + unstaged changes (git diff)          |
| `/ops:security path/to/file`   | Specific file(s)                              |
| `/ops:security path/to/dir`    | All files in directory                        |
| `/ops:security --branch`       | Full diff from current branch vs. base branch |
| `/ops:security --commit <ref>` | Diff of a specific commit                     |

---

## Workflow

### Step 1: Determine Scope

Based on the invocation, gather the changes to review:

- **No args**: run `git diff` and `git diff --staged` to capture all pending changes. If both are empty, tell the user there's nothing to review.
- **File/directory path**: read the specified files. If the path doesn't exist, tell the user.
- **`--branch`**: run `git diff $(git merge-base HEAD main)...HEAD` (adapt base branch from context or CLAUDE.md).
- **`--commit <ref>`**: run `git diff <ref>~1..<ref>`.

### Step 2: Security Gate

Run the `ops:security-gate` process on the diff/files (triage + dispatch + re-verification loop).

**If no security-sensitive areas are found**: tell the user — "No security-sensitive areas detected in scope. Nothing to escalate." Offer to run anyway if they want a second opinion.

**If security-sensitive areas are found**: the security-gate handles triage, dispatch of the security-reviewer, and re-verification loop.

### Step 3: Present Results

When the security-reviewer returns, present its report directly to the user.

**If Critical issues found:**
> Present each with file:line, attack scenario, and recommended fix.
> Ask the user: "Want me to fix these now?"

**If Important issues found:**
> Present each with risk and recommendation.
> Ask the user: "Want me to address these?"

**If Secure (no issues):**
> Confirm: "Security review passed — no issues found in scope."
> Include scope summary so the user knows what was covered.

### Step 4 (optional): Fix

If the user asks to fix issues:
1. Apply the fixes
2. Run validation (build, lint, tests as appropriate)
3. The `ops:security-gate` re-verification loop handles re-dispatch (cap 3 iterations).
4. Present the verification result

---

## Constraints

- **Do NOT auto-fix without asking.** Present findings, let the user decide.
- **Scope to what's requested.** Don't audit the entire codebase when the user asked about one file.
- **No false urgency.** If there's nothing to report, say so. Don't manufacture findings to justify the review.
- **Technology-agnostic.** Apply security principles regardless of language, framework, or platform.
- **Respect project conventions.** Read CLAUDE.md for project-specific security rules before dispatching the reviewer.
