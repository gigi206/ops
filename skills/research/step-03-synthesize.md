# Step 3 — Synthesize

Mark the task "Research: synthesize" as `in_progress` now via `TaskUpdate`.

## What to do

Combine findings from all 3 agents into a coherent picture. Identify:
- **Agreements**: where all agents converge
- **Gaps**: what wasn't found or remains unclear
- **Contradictions**: where agents disagree (different versions, conflicting patterns)

## Decision: conditional repository analysis

Check whether repository cloning is needed by parsing researcher-doc's `Source Verification Needed` list:

1. If the field is **absent** → take Branch A. Add a warning in the synthesis: "> ⚠ researcher-doc did not return Source Verification Needed field"
2. Collect all targets with `Needed: high` into a list. If the list is empty (all targets are `none` or `low`) → take Branch A. Note any `low` gaps in the synthesis for transparency.
3. If one or more targets have `Needed: high` → take Branch B with the list of high-severity targets.

---

## ✅ End of Step 3

Before proceeding, verify:
- [ ] You synthesized findings from all 3 agents (agreements, gaps, contradictions) in your output.
- [ ] You parsed researcher-doc's `Source Verification Needed` list.

Then choose your branch based on the verification state:

---

### Branch A — Source verification NOT needed (field absent, or all targets are none/low)

- [ ] No target in researcher-doc's output has `Needed: high`.
- [ ] You noted any `low` gaps or the absence of the field in the synthesis for transparency.

Mark the task "Research: synthesize" as `completed` via `TaskUpdate`.

Also mark the two conditional tasks as `completed` with the "not applicable" note via `TaskUpdate`:
- "Research: conditional repo analysis" → `completed` (note: "not applicable — no high-severity source verification gaps")
- "Research: final synthesis" → `completed` (note: "not applicable — Step 4 was skipped")

**→ Next: read `skills/research/step-06-present.md` now and execute Step 6.**

Do NOT continue without reading that file first.

---

### Branch B — One or more targets have `Needed: high`

- [ ] At least one target has `Needed: high` in researcher-doc's output.
- [ ] You have the list of high-severity targets with their name, ecosystem, and researcher-doc's rationale.

Mark the task "Research: synthesize" as `completed` via `TaskUpdate`.

**→ Next: read `skills/research/step-04-conditional-repo-analysis.md` now and execute Step 4.**

Do NOT continue without reading that file first.
