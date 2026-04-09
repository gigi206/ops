# Step 6 — Present

Mark the task "Research: present" as `in_progress` now via `TaskUpdate`.

## What to do

Present a structured synthesis to the user:

```markdown
## Research: <topic>

### Codebase Patterns
- [Key findings from researcher-code]

### Documentation
- [Key findings from researcher-doc, with sources and versions]

### History & Ownership
- [Key findings from git-historian]

### Repository Analysis
- [Key findings from researcher-repo, if dispatched in Step 4]
- [Version used vs HEAD comparison, if applicable]

### Risk Assessment
- [HIGH/MEDIUM/LOW areas with justification]

### Gaps
- [What remains unclear or wasn't found]
```

Ask the user if they want to dig deeper into any area, or if this is sufficient context to proceed with planning or implementation.

---

## ✅ End of Step 6

Before marking complete, verify:
- [ ] You produced a `## Research: <topic>` block with all applicable sections (Codebase Patterns, Documentation, History & Ownership, Repository Analysis if Step 4 ran, Risk Assessment, Gaps).
- [ ] Every finding cites its source (file:line, doc URL, commit hash, or agent name).
- [ ] You asked the user if they want to dig deeper or proceed with planning/implementation.

Mark the task "Research: present" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 6 steps of `/ops-research` have been executed. The research output is ready for the user's next action (typically `/ops-plan` or `/ops-brainstorm`). There is no next file to read.
