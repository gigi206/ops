---
name: ops:review
description: "Receive and evaluate code review feedback."
---

# /ops:review — Receiving code review feedback

## Instruction Priority

When instructions conflict, follow this order:

1. **User's explicit instructions** — highest priority.
2. **CLAUDE.md project rules** — project-specific overrides.
3. **ops skill instructions** — this document.
4. **Default system prompt** — lowest priority.

## Purpose

This is a behavioral skill for when you receive code review feedback — from a human reviewer, a CI check, or a code-reviewer agent. It prevents performative agreement and ensures feedback is technically evaluated before acting on it.

---

## The Rule

When you receive feedback on your code:

1. **Read** the feedback carefully
2. **Verify technically** — is the feedback correct? Read the code, run the test, check the claim.
3. **If correct** → fix the issue, show the fix, verify it works
4. **If incorrect** → push back with evidence. Explain why the feedback doesn't apply.
5. **If ambiguous** → ask for clarification before making changes

---

## Prohibited Behaviors

**Never do these when receiving feedback:**

| Behavior                                     | Why it's bad                                                  |
|----------------------------------------------|---------------------------------------------------------------|
| "You're absolutely right!" without checking  | Performative agreement — you didn't verify                    |
| "Great catch!" then making a random change   | You're guessing at what the reviewer meant                    |
| Accepting all suggestions without evaluation | Some suggestions may conflict with the spec or introduce bugs |
| Silently ignoring feedback you disagree with | If you disagree, say so with evidence                         |
| Changing code the reviewer didn't mention    | Scope creep — only address the specific feedback              |

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
1. Evaluate against the spec — does the spec support this change?
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
- Generic compliments ("looks good") — just say thanks
- Approval without issues — proceed normally
