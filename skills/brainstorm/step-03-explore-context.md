# Step 3 — Explore project context

- Check the current project state (files, docs, recent commits)
- Understand existing structure and conventions before asking questions
- This informs your questions — ask smart questions, not generic ones

## Complexity Assessment

After exploring context, present the complexity classification to the user following common_instructions rule 2 (text analysis + tool call).

**You MUST present ALL THREE options with their consequences.** The user needs to see what each level means before choosing.

**Part 1 — text analysis:**

```
Based on what I see in the codebase:

**A. Simple** — 1-3 files, known pattern, no architectural fork.
  + Express brainstorm: 1-2 questions max, all dimensions batched, design as single block, YAGNI in summary. Transitions to /ops-do.
  − If it turns out more complex, we'll need to revisit.

**B. Normal** — Multiple files, some architectural choices.
  + Standard brainstorm: questions as needed, dimensions one by one, design section by section. Transitions to /ops-plan.
  − More time than Simple.

**C. Complex** — New subsystem, migration, cross-cutting concern.
  + Full brainstorm: scope decomposition, visual companion, extra dimensions beyond the 7 defaults, design with documented alternatives. Transitions to /ops-plan.
  − Longest flow, only worth it for genuinely complex features.

I'd recommend **[X]** because [concrete justification from what you observed].
```

**Part 2 — tool call with short labels:** `A. Simple`, `B. Normal (Recommended)`, `C. Complex` (move Recommended to whichever you recommend).

Wait for the user's answer. The user may override.

**Store the chosen level** — it determines the flow for all subsequent steps. Steps 4-11 check this level and adapt accordingly.

---

## ✅ End of Step 3

Before proceeding, verify:
- [ ] You have checked the current project state (relevant files, docs, recent commits).
- [ ] You understand the existing structure and conventions of the area you will be working on.
- [ ] Your upcoming clarifying questions will be informed by what you observed (not generic).
- [ ] You stated a complexity classification (Simple / Normal / Complex) and the user confirmed.

**→ If Simple or Normal: read `skills/brainstorm/step-06-clarifying-questions.md` now and execute Step 6** (skip Steps 4-5).

**→ If Complex: read `skills/brainstorm/step-04-assess-scope.md` now and execute Step 4.**

Do NOT continue without reading the correct file first.
