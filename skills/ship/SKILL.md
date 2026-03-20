---
name: ops:ship
description: "Commit, PR, and capture learnings."
---

# /ops:ship — Ship the work

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Purpose

This skill wraps up completed work: verifies everything is clean, commits, optionally creates a PR, and captures learnings. Use after `/ops:implement` or any significant code change.

---

## Workflow

```
1. Verify → 2. Summarize → 3. Commit → 4. PR (optional) → 5. Learnings → 6. Rule Proposals
```

---

## Step 1: Verify

Before shipping anything, run full validation:

1. **Run all validation commands** from the plan (if one exists)
2. **Run linters** on all modified files
3. **Run tests** if the project has a test suite
4. **Check git status** — no untracked files that should be committed, no uncommitted changes that should be included

**Gate**: Do NOT proceed to commit if validation fails. Fix first.

This step invokes the `/ops:verify` behavioral rule — every claim needs evidence.

---

## Step 2: Summarize Changes

Present a concise summary of what was done:

```markdown
## Changes

### Files modified
- `path/to/file.ext` — what changed

### Files created
- `path/to/new-file.ext` — purpose

### What was done
- [1-3 bullet points summarizing the work]

### Deviations from plan
- [Any changes from what was planned, or "None"]
```

---

## Step 3: Commit

1. **Stage the relevant files** — use `git add <specific files>`, not `git add .`
2. **Propose a commit message** to the user:
   - Concise summary line (imperative mood, <72 chars)
   - Body explaining **why**, not what (the diff shows the what)
   - Follow the project's commit conventions if documented in CLAUDE.md
3. **Wait for user approval** before committing
4. **Commit** and show the result

**Rules**:
- Never commit files that contain secrets (.env, credentials, tokens)
- Never commit without user approval
- Never amend a previous commit unless the user explicitly asks
- Never push without user approval

---

## Step 4: Pull Request (optional)

If the user asks for a PR, or if the work is on a branch:

1. **Push** to remote (with user approval)
2. **Create PR** with:
   - Title: concise (<70 chars)
   - Body: summary from Step 2 + test plan
3. **Show the PR URL** to the user

If the user doesn't ask for a PR, skip this step.

---

## Step 5: Learnings

Capture what was learned during this work:

```markdown
## Learnings

### Problems solved
- [What went wrong and how it was fixed]

### Decisions made
- [Non-obvious choices and rationale]

### Gotchas discovered
- [Things future agents should know]

### Patterns that worked
- [Reusable approaches worth remembering]
```

Present this to the user.

---

## Step 6: Rule Proposals

After presenting the learnings, evaluate each one: **is this a recurring lesson tied to a specific type of file or area?**

### When to propose a rule

A learning should become a rule when it meets **both** criteria:
- **Recurring**: it will apply again the next time someone touches this kind of file (not a one-time fix)
- **Targetable**: it can be scoped to a glob pattern (e.g., `**/migrations/**`, `**/*.sh`, `src/api/routes/*.ts`)

If a learning is one-off or too vague to target, don't propose it — it stays in the session summary and that's fine.

### How to propose

For each learning that qualifies, present a concrete rule proposal:

```
I suggest creating a rule from this learning:

File: .claude/rules/api-error-handling.md
Glob: src/api/routes/*.ts

---
description: API route error handling conventions
globs: ["src/api/routes/*.ts"]
---

- Always return structured error responses with `code` and `message` fields
- Never expose stack traces or internal paths in non-development environments
- Validate request body before any business logic — fail fast with 400

Create this rule? [yes / modify / skip]
```

### Rules

- **Never write a rule without user approval.** Always propose, wait, then write.
- **One proposal at a time.** Don't dump 5 rules at once — present each, get a decision, move on.
- **Keep rules short.** A rule is 3-8 bullet points. If it's longer, it's documentation, not a rule.
- **Check for existing rules first.** Read `.claude/rules/` before proposing — if a relevant rule already exists, propose an update instead of a new file.
- **If the user says "modify"**, ask what they want to change, apply the edits, show the updated version, and confirm again.
- **If the user says "skip"**, move on. Don't argue.

---

## Constraints

- **Never push to main/master without explicit user approval.**
- **Never force push unless the user explicitly asks.**
- **Never skip validation to ship faster.** If something fails, fix it first.
- **Keep commit messages honest.** If the implementation deviates from the plan, say so in the commit body.
