---
name: ops:security
description: "On-demand security review of code, infrastructure, or pipeline changes."
---

# /ops:security — On-demand security review

## Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority.
2. **CLAUDE.md project rules** — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

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

### Step 2: Triage

Scan the diff/files and classify what security domains are touched:

- Authentication, authorization, or identity federation
- APIs, endpoints, or interfaces exposed beyond the trust boundary
- Secrets, credentials, keys, or tokens
- Encryption or certificate configuration
- User input handling or data validation
- Access control rules or permission models
- Network exposure, firewall rules, or traffic policies
- Infrastructure definitions (IaC)
- CI/CD pipeline configuration
- Container, VM, or runtime privilege configuration
- Dependency or supply chain changes
- Policy enforcement, admission control, or compliance rules
- Data storage, retention, or backup configuration
- Logging, audit, or observability configuration

**If no security-sensitive areas are found**: tell the user — "No security-sensitive areas detected in scope. Nothing to escalate." Offer to run anyway if they want a second opinion.

**If security-sensitive areas are found**: list them briefly, then proceed to Step 3.

### Step 3: Dispatch Security Reviewer

Dispatch the **security-reviewer** agent with:
- The full diff or file contents in scope
- The list of security domains identified in Step 2
- The project's CLAUDE.md rules (if the project has one)
- Any user-provided context (e.g., "focus on the auth flow", "we're worried about supply chain")

### Step 4: Present Results

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

### Step 5 (optional): Fix

If the user asks to fix issues:
1. Apply the fixes
2. Run validation (build, lint, tests as appropriate)
3. Re-dispatch the **security-reviewer** with an optimized prompt that includes:
   - The security-reviewer's previous findings
   - The fixes applied and why
   - The new diff (`git diff`)
   - A request for the full standard verdict
   - Do NOT re-include the original diff or the security domains list — the agent handled those on the first pass
4. If the re-review finds **new critical issues**: fix them, run validation again, and re-dispatch with the same optimized prompt pattern. This is a **loop capped at 3 iterations**. After 3 iterations without approval, stop and escalate to the user.
5. Present the verification result

---

## Constraints

- **Do NOT auto-fix without asking.** Present findings, let the user decide.
- **Scope to what's requested.** Don't audit the entire codebase when the user asked about one file.
- **No false urgency.** If there's nothing to report, say so. Don't manufacture findings to justify the review.
- **Technology-agnostic.** Apply security principles regardless of language, framework, or platform.
- **Respect project conventions.** Read CLAUDE.md for project-specific security rules before dispatching the reviewer.
