---
name: ops-verify
description: "Evidence before claims. Always."
---

# /ops-verify — Verification before completion

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Purpose

This is a behavioral skill, not a workflow. It applies **everywhere, all the time** — during `/ops-implement`, `/ops-debug`, or any work outside of ops skills.

The rule is simple: **never claim a result without showing the evidence.**

---

## The Gate

Before making any assertion of success or completion, you MUST:

1. **Identify** the verification command for the claim
2. **Run** it — fresh, complete, not from cache or memory
3. **Read** the full output, including exit code
4. **Verify** the output actually confirms the claim
5. **Only then** make the claim

If any step fails, the claim is **not verified**. Say what happened instead of what you expected.

---

## Common Failures

| Claim              | Required Evidence                       | NOT Evidence                 |
|--------------------|-----------------------------------------|------------------------------|
| "Tests pass"       | Test command output showing 0 failures  | "I ran the tests earlier"    |
| "Build succeeds"   | Build command output with exit code 0   | "The code looks correct"     |
| "No lint errors"   | Linter output showing 0 warnings/errors | "I followed the conventions" |
| "Fix works"        | Original failing command now succeeds   | "I addressed the root cause" |
| "Deploy succeeded" | Status command showing healthy state    | "I applied the manifest"     |
| "PR is clean"      | CI checks passing, no conflicts         | "I pushed the changes"       |

---

## Red Flags — you are about to make an unverified claim

- [ ] Using "should", "probably", "seems to", "I believe" instead of showing output
- [ ] Saying "tests pass" without a test command in your recent output
- [ ] About to commit, push, or create a PR without running validation
- [ ] Claiming a fix works based on reading the code, not running it
- [ ] Reporting DONE without the validation output in the conversation
- [ ] Repeating a previous result instead of running a fresh command

If you catch yourself doing any of these: **STOP. Run the command. Show the output.**

---

## Scope

This skill applies to:
- Every task completion in `/ops-implement`
- Every fix verification in `/ops-debug`
- Every commit, push, or PR creation
- Any time you assert something works, passes, succeeds, or is done

It does NOT apply to:
- Research findings (opinions and analysis don't need command output)
- Design proposals (future work, not completed work)
- Questions to the user
