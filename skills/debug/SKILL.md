---
name: ops-debug
description: "Use when something is broken, failing, or behaving unexpectedly."
---

# /ops-debug — Systematic debugging

<HARD-GATE-IRON-LAW>
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

Violating the letter of the rules is violating the spirit of the rules. Do NOT guess. Investigate systematically. Understand the root cause before writing a fix. If you catch yourself about to write a fix without a CONFIRMED hypothesis from Step 3, STOP — you are violating the Iron Law and this is a FAILURE of this skill.
</HARD-GATE-IRON-LAW>

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

---

## Workflow — 8 sequential step files

This skill is split into 8 step files you execute one at a time. Each step file contains its own instructions and ends with an explicit hand-off telling you which file to read next.

```
Step 0 — Browser Bug Triage        →  skills/debug/step-00-browser-bug-triage.md
Step 1 — Investigate               →  skills/debug/step-01-investigate.md
Step 2 — Hypothesize               →  skills/debug/step-02-hypothesize.md
Step 3 — Test Hypotheses           →  skills/debug/step-03-test-hypotheses.md
Step 4 — Fix                       →  skills/debug/step-04-fix.md
Step 5 — Code Quality + Review     →  skills/debug/step-05-code-review.md
Step 6 — Discovery Check           →  skills/debug/step-06-discovery-check.md
Step 7 — Verify                    →  skills/debug/step-07-verify.md
```

---

## How to execute this skill

1. Read `skills/debug/step-00-browser-bug-triage.md` **now**.
2. Execute its instructions exactly as written.
3. At the end of each step file you will find a `## ✅ End of Step N` block containing (a) a step-specific completion checklist, (b) a `TaskUpdate` instruction to mark the step completed, and (c) a hand-off pointing to the next file. Follow that hand-off.
4. **Do NOT read all 8 files at once.** Read them one at a time, in order.
5. **Do NOT skip any step.** The chain-of-custody between step files is what makes this skill work reliably across models with varying instruction-following strength.
6. **Step 1.5 Instrumentation** (from the pre-decomposition version) is inlined into `step-01-investigate.md` as a conditional sub-section — not its own file. Apply it if the error path crosses multiple components.
7. **Circuit Breaker** (5+ failed fix attempts) is inlined into `step-04-fix.md` — it triggers the `ops-circuit-breaker` process and escalates to the user.
8. **Step 3 has a branching hand-off** — Branch A (at least one hypothesis CONFIRMED → step-04) or Branch B (all REFUTED → back to step-01 to re-investigate, do NOT attempt a fix).

---

## Red Flags — you are about to guess

If any of these thoughts cross your mind, STOP — you are about to skip root cause investigation:

| Thought | Reality |
|---------|---------|
| "The error is obvious, no need to investigate" | Obvious errors hide deep root causes. Investigate. |
| "I've seen this bug before, I know the fix" | Confirm with evidence. Your memory may be wrong. |
| "One test is enough to validate the hypothesis" | Unless it's intermittent. Test multiple times. |
| "The fix works, no need for code review" | Unless it modifies ≤1 file and is a pure typo/config change. Otherwise review is mandatory. |
| "All hypotheses are refuted, I'll try a fix anyway" | Go back to Step 1. No fix without a confirmed root cause. |

---

**→ Read `skills/debug/step-00-browser-bug-triage.md` now and begin Step 0.**
