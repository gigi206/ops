# Step 6 — LSP + Final Summary

Mark the task "Init: LSP" as `in_progress` now via `TaskUpdate`.

## LSP Diagnostic

Dispatch to the CLI-specific sub-skill for LSP diagnostic:
- If `cli=claude-code`: follow the LSP section of `skills/init/claude-code.md` (Category 1)
- If `cli=opencode`: follow the LSP section of `skills/init/opencode.md` (Category 1)

The sub-skill handles diagnostic, table output, and interactive fix proposals (A/B/C/D). Follow its process entirely.

## Final Summary

After all steps are complete, present a final recap:

```
## Init Complete

| Step | Status |
|---|---|
| Recap | N skills, N agents, N MCP |
| Ops tools | qlty ✓, semgrep ✓ |
| Project linters | N/N installed |
| Prerequisites | all met |
| Build tools | N/N installed |
| LSP | N/N languages working |
```

---

## ✅ End of Step 6

Before marking complete, verify:
- [ ] You dispatched to the correct CLI-specific sub-skill (`claude-code.md` or `opencode.md`) for LSP diagnostic.
- [ ] You followed the sub-skill's process entirely (including A/B/C/D fix proposals if any).
- [ ] You output the `## Init Complete` final summary table.

Mark the task "Init: LSP" as `completed` via `TaskUpdate`.

**→ Skill complete.** All 7 steps of `/ops-init` have been executed. The environment is ready for downstream ops skills. There is no next file to read.
