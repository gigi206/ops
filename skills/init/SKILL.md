---
name: ops-init
description: "Diagnose environment: ops recap, qlty/semgrep, project linters, linter prerequisites, build tools, LSP. Propose installation for missing tools."
---

# /ops-init — Environment Diagnostic & Tool Setup

**Read `data/common_instructions.md` before executing this skill.**

<HARD-GATE-LANGUAGE>
Your **very first action** — before reading any step file, before any diagnostic, before any tool call other than this one — must be to run `echo $LANG` via Bash. Parse the result (e.g., `fr_FR.UTF-8` → French, `en_US.UTF-8` → English). **All subsequent output — diagnostics, tables, proposals, summaries — must be in that language.** Technical terms and tool names stay in English.

If you start producing diagnostic output (including reading any other step file) without having first run `echo $LANG` and chosen the output language, you have FAILED this skill.
</HARD-GATE-LANGUAGE>

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Stop-and-propose rule (global — applies to every step)

If any step detects missing or broken tools, **stop at the end of that step**, present findings and propose solutions (A/B/C style). Wait for the user's decision before proceeding to the next step. Do NOT batch all issues for the end. Do NOT combine multiple steps in a single message.

If nothing is missing in a step, proceed directly to the next.

---

## Workflow — 7 sequential step files

This skill is split into 7 step files you execute one at a time. Each step file contains its own instructions and ends with an explicit hand-off telling you which file to read next. You never need to read more than one step file at a time.

```
Step 0 — Bootstrap                         →  skills/init/step-00-bootstrap.md
Step 1 — Recap                             →  skills/init/step-01-recap.md
Step 2 — Ops Tools                         →  skills/init/step-02-ops-tools.md
Step 3 — Project Linters                   →  skills/init/step-03-project-linters.md
Step 4 — Linter Prerequisites              →  skills/init/step-04-linter-prerequisites.md
Step 5 — Build Tools                       →  skills/init/step-05-build-tools.md
Step 6 — LSP + Final Summary               →  skills/init/step-06-lsp.md
```

---

## How to execute this skill

1. **Before reading any step file**, run `echo $LANG` via Bash and choose the output language (per `<HARD-GATE-LANGUAGE>` above).
2. Read `skills/init/step-00-bootstrap.md` **now**.
3. Execute its instructions exactly as written.
4. At the end of each step file you will find a `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) a hand-off pointing to the next file. Follow that hand-off.
5. **Do NOT read all 7 files at once.** Read them one at a time, in order, as instructed by each file's hand-off.
6. **Do NOT skip any step.** The chain-of-custody between step files is what makes this skill work reliably across models with varying instruction-following strength.
7. **Do NOT improvise the order.** If you somehow land in a step file without having executed the previous one, STOP and go back to `step-00-bootstrap.md`.
8. **Apply the Stop-and-propose rule at every step.** If a step detects missing or broken tools, stop at the end of that step, present findings and propose solutions, wait for the user's decision. Do NOT batch issues across steps.

---

## Rules (global — apply to every step)

- Only check languages actually found in the project (Step 0b). Do NOT list the entire table.
- **Only show install commands for package managers the user actually has** (from Step 0c).
- Tools detected here are reported to the user but NOT passed to downstream skills. `ops-code-quality` and `ops-security-gate` re-detect independently — each skill must work standalone without prior setup.
- If nothing is missing across all steps, report "all tools available" and show only the final summary.
- Do NOT auto-install without consent. Always show commands before executing.

---

**→ First run `echo $LANG` (per `<HARD-GATE-LANGUAGE>`), then read `skills/init/step-00-bootstrap.md` and begin Step 0.**
