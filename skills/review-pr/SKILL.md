---
name: ops:review-pr
description: "Review an external PR: checkout, analyze, produce structured review with actionable comments."
---

# /ops:review-pr — Review a pull request

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops:subagent-rules` process.

## Purpose

Review someone else's pull request. Produce a structured, actionable review that helps the author improve their code. This is NOT `/ops:review` (receiving feedback) — this is giving feedback.

---

## Workflow

```
1. Load PR → 2. Understand context → 3. Dispatch pr-reviewer → 4. Security gate → 5. Present review
```

---

## Step 1: Load PR

Get the PR to review:
- If the user provided a PR number or URL → fetch it with `gh pr view` and `gh pr diff`
- If the user said "review the current branch" → use `git diff` against the base branch

Collect:
- The full diff
- The PR title and description (if available)
- Related issues or tickets (if referenced)

---

## Step 2: Understand Context

Before dispatching the reviewer:
- Read the project's `CLAUDE.md` and `.claude/CLAUDE.md` for conventions
- Quickly scan the files touched to understand the area of the codebase
- Note the size of the PR (files changed, lines added/removed)

If the PR is very large (>500 lines changed across >10 files), warn the user:
> "This PR is large ([N] files, [N] lines). A thorough review may take a while. Want me to proceed, or focus on specific files?"

---

## Step 3: Dispatch pr-reviewer

Dispatch the **pr-reviewer** agent with:
- The full diff
- The PR description (if available)
- The CLAUDE.md rules (if applicable)
- The related issue/ticket context (if available)
- Any specific user instructions (e.g., "focus on the auth changes", "check backward compatibility")

**Wait for the agent to return.**

---

## Step 4: Security Gate

Run the `ops:security-gate` process on the PR diff. If security triggers match, dispatch the **security-reviewer** in the **same message** as the pr-reviewer (see `ops:subagent-rules`) — merge its findings into the final review.

---

## Step 5: Present Review

Present the pr-reviewer's findings (and security-reviewer's if dispatched) to the user in a structured format:

```markdown
## PR Review: <title>

**Overall:** ✅ Approve | 🔄 Request changes | 💬 Comment only

### Summary
[1-2 sentences]

### Strengths
- [What was done well]

### Critical (must fix)
- [file:line — issue + suggestion]

### Important (should fix)
- [file:line — issue + suggestion]

### Security (if applicable)
- [Findings from security-reviewer]

### Nits
- [Minor suggestions]
```

Then ask the user:
> "Want me to post these comments on the PR, adjust the review, or leave it as-is?"

If the user wants to post:
- Use `gh pr review` to submit the review
- Use `gh pr comment` for inline comments if supported
