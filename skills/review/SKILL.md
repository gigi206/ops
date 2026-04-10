---
name: ops-review
description: "Receive and evaluate code review feedback."
---

# /ops-review — Receiving code review feedback

**Read `data/common_instructions.md` before executing this skill.**

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Purpose

This is a behavioral skill for when you receive code review feedback — from a human reviewer, a CI check, or a code-reviewer agent. It prevents performative agreement and ensures feedback is technically evaluated before acting on it.

---

## The Rule

When you receive feedback on your code:

1. **Read** the complete feedback without reacting
2. **Verify technically** — is the feedback correct? Read the code, run the test, check the claim.
3. **If correct** → fix the issue, show the fix, verify it works
4. **If incorrect** → push back with evidence. Explain why the feedback doesn't apply.
5. **If any item is ambiguous** → STOP. Do not implement anything. Ask for clarification on ALL unclear items before making any changes. Partial understanding leads to wrong implementation.
6. **If multi-item** → implement in order: blocking issues → simple fixes → complex fixes. Test each individually.

---

## Anti-Sycophancy

Code review requires technical evaluation, not emotional performance. Technical correctness over social comfort.

**Forbidden responses — delete these before sending:**

| Response                        | Why it's forbidden                          | Instead                              |
|---------------------------------|---------------------------------------------|--------------------------------------|
| "You're absolutely right!"      | Performative agreement — you didn't verify  | Restate the technical requirement    |
| "Great catch!" / "Good point!"  | Flattery replacing analysis                 | Just fix it and show the diff        |
| "Thanks for catching that!"     | Gratitude replacing action                  | `"Fixed. [description of change]"`   |
| "Excellent feedback!"           | Empty praise                                | Start working — actions > words      |
| Any gratitude expression        | Social performance, not engineering         | State the fix or ask a question      |

**When feedback IS correct:**
```
✅ "Fixed. [Brief description of what changed]"
✅ "Confirmed — [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!" / "Great catch!"
❌ "Thanks for catching that!"
❌ ANY performative agreement or standalone gratitude
```

The test: does your response contain technical content, or just social noise? "Fixed the null check on line 42" is engineering. "Great catch!" is performance.

---

## Prohibited Behaviors

**Never do these when receiving feedback:**

| Behavior                                     | Why it's bad                                                  |
|----------------------------------------------|---------------------------------------------------------------|
| Accepting all suggestions without evaluation | Some suggestions may conflict with the plan or introduce bugs |
| Silently ignoring feedback you disagree with | If you disagree, say so with evidence                         |
| Changing code the reviewer didn't mention    | Scope creep — only address the specific feedback              |
| Implementing before verifying                | The suggestion may be wrong for this codebase                 |

---

## Source-Specific Handling

### From the user (human partner)
- **Trusted** — implement after understanding, no need to verify the intent
- **Still ask** if scope is unclear
- **Skip to action** — no performative acknowledgment needed

### From external reviewers (PR comments, code-reviewer agent, CI)
Before implementing any suggestion:
1. Is this technically correct for THIS codebase?
2. Does it break existing functionality?
3. Is there a reason the current implementation exists (compatibility, plan requirement)?
4. Does the reviewer have the full context?

If the suggestion seems wrong → push back with technical reasoning.
If it conflicts with prior user decisions → stop and discuss with the user first.

### YAGNI Check

When a reviewer suggests "implementing properly" or adding a feature:
1. Grep the codebase for actual usage of the code in question
2. If unused → suggest removal (YAGNI) instead of improvement
3. If used → implement the improvement

Do not gold-plate unused code because a reviewer asked for it.

---

## How to Respond to Different Feedback Types

### Factual feedback ("This has a bug on line 42")
1. Read line 42
2. Reproduce the bug
3. If confirmed → fix it, show the fix
4. If not a bug → explain why with evidence (e.g., "This is handled by the guard clause on line 38")

### Style feedback ("This should use X pattern instead of Y")
1. Check if the codebase has a convention for this
2. If project convention exists → follow it (regardless of reviewer preference)
3. If no convention → evaluate on merit (readability, maintainability)
4. If you disagree → explain your reasoning, let the reviewer decide

### Architectural feedback ("This component should be restructured")
1. Evaluate against the plan — does the plan support this change?
2. If within scope → discuss with the user before restructuring
3. If out of scope → acknowledge, suggest as future improvement

### Security feedback ("This is vulnerable to X")
1. **Always take seriously** — verify the attack vector
2. If confirmed → fix immediately, dispatch security-reviewer to verify the fix
3. If not exploitable → explain the mitigation, let the reviewer decide

---

## Handling Disagreements

If you believe the reviewer is wrong:

1. **Never dismiss without evidence.** "I don't think that's an issue" is not a response.
2. **Show your reasoning**: cite file:line, show test output, explain the mitigation
3. **Acknowledge the reviewer's perspective**: "I see why this looks risky, but..."
4. **Let the reviewer (or user) make the final call** if the disagreement persists

---

## Scope

This skill applies when:
- A human reviewer comments on your code (PR review, inline comments)
- The code-reviewer agent returns findings
- CI checks fail with actionable feedback
- The critic agent rejects a plan with specific concerns

It does NOT apply to:
- Generic compliments ("looks good") — acknowledge and proceed
- Approval without issues — proceed normally
