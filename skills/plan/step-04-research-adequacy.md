# Step 4 — Research Adequacy Check

Mark the task "Plan: research adequacy check" as `in_progress` now via `TaskUpdate`.

Before designing approaches, verify the research produced concrete evidence — not just "we understand".

**You MUST present this table to the user** with the evidence filled in:

| Dimension             | Status   | Evidence                                                       |
|-----------------------|----------|----------------------------------------------------------------|
| **Technical context** | OK / GAP | [Cite `file:line` of similar code or list files read]          |
| **Dependencies**      | OK / GAP | [List of files affected from researcher-code]                  |
| **Risks**             | OK / GAP | [Concrete risks found, or "none found after checking X, Y, Z"] |
| **Documentation**     | OK / GAP | [Sources with versions, e.g., "Context7: express v4.18.2"]     |

This table is not a mental checklist — it must appear in your output so the user can verify the research was adequate.

**If 3-4 dimensions are OK**: Proceed to Step 5.

**If 1-2 dimensions show GAP**:
- Identify the specific gap (e.g., "no similar implementation found — we don't know the pattern to follow")
- Spawn a targeted follow-up agent to fill the gap (researcher-doc or researcher-code, whichever is relevant)
- Do NOT proceed with a half-understood problem

**If 0 dimensions have evidence**: The task is probably too vague. Go back to Step 1 and clarify with the user.

---

## ✅ End of Step 4

Before proceeding, verify:
- [ ] You presented the research adequacy table in your output (not just a mental check).
- [ ] Each dimension has concrete evidence or is marked GAP.

Then choose your branch based on the state of the evidence table:

---

### Branch A — 3-4 dimensions OK (or gaps have been filled)

- [ ] You are NOT about to proceed with a half-understood problem.

Mark the task "Plan: research adequacy check" as `completed` via `TaskUpdate`.

**→ Next: read `skills/plan/step-05-design-approaches.md` now and execute Step 5.**

Do NOT continue without reading that file first.

---

### Branch B — 1-2 dimensions have GAP

- [ ] You identified the specific gap.
- [ ] You spawned a targeted follow-up agent to fill it.
- [ ] The gap is now filled with concrete evidence (table updated).

Do NOT mark this task completed yet. Stay in this step — re-evaluate this End block after the follow-up finishes. When all dimensions are OK, follow Branch A.

---

### Branch C — 0 dimensions have evidence (task too vague)

The task is too vague to research meaningfully. Go back to clarification.

Do NOT mark this task completed.

**→ Go back: read `skills/plan/step-01-clarify-intent.md` now and re-clarify with the user.** You will re-enter this step later via the normal chain — when that happens, re-evaluate this End block.
