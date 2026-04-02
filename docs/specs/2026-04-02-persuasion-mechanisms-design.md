# Targeted Persuasion Mechanisms — Design Spec

**Status**: Implemented
**Date**: 2026-04-02
**Scope**: Add rationalization tables, Red Flags, Iron Laws, and CSO-optimized descriptions to critical skills and agents

## Problem

OPS uses Authority-based persuasion almost exclusively (hard gates, "FAILURE", "MUST"). Research shows:
- Meincke et al. (2025, N=28,000): Commitment (+81pp) and Scarcity (+72pp) are stronger than Authority (+40pp) for LLM compliance
- Anthropic docs (Claude 4.6): aggressive Authority language causes overtriggering in Claude 4.5/4.6 models

Current gaps:
- 1 rationalization table across the entire codebase (implementer TDD only)
- 3 Red Flags sections (implementer TDD, testing-anti-patterns, verify)
- 2 Iron Laws (both TDD-related)
- 7/26 skill descriptions leak workflow instead of describing trigger conditions (CSO problem)
- No anti-rationalization in critic, plan, implement (orchestrator), or debug

## Approach

**Add targeted persuasion mechanisms to 6 core files with proven circumvention risk, plus CSO description updates in 4 additional SKILL.md frontmatter files (10 files total).** No new files. No blanket changes. No additional Authority language.

Persuasion principles used:
- **Commitment**: force agents to announce intent before acting (public self-commitment)
- **Scarcity**: tie rules to specific moments ("IMMEDIATELY after X", "BEFORE Y")
- **Social Proof**: "X without Y = failure. Every time." to establish norms
- **Inoculation**: "Violating the letter of the rules is violating the spirit of the rules." to close an entire class of rationalizations

Format: hybrid Red Flags / Rationalization tables (single table combining the thought and the counter-argument). This is more compact and scannable than separate Red Flags lists + Rationalization tables.

## Changes

### 1. `agents/implementer.md`

**1a. Add letter/spirit inoculation** (after "Iron rule: NO production code without a failing test first.")

Note: this line already exists in `skills/implement/tdd-reference.md:9`. The duplication is intentional — agents under token pressure may not load the reference file, so the inoculation must also appear inline.

Add: `Violating the letter of the rules is violating the spirit of the rules.`

**1b. Add non-TDD rationalization table** (after Constraints section, end of file)

New section: `## Red Flags — non-TDD`

Hybrid table with columns `Thought` | `Reality`:

| Thought | Reality |
|---------|---------|
| "Validation will probably pass, no need to run it" | "Probably" is not evidence. Run it. |
| "This out-of-scope file has an obvious bug, quick fix" | Report it in DONE_WITH_CONCERNS. Do not fix it. |
| "DONE_WITH_CONCERNS would cause doubt, I'll report DONE" | Honesty protects the project. DONE_WITH_CONCERNS exists for a reason. |
| "The plan is vague but I understand the intent" | Report BLOCKED with a specific question. Do not guess. |
| "It's just formatting, no need to read the file first" | Read before write. Always. One wrong indent breaks YAML. |

### 2. `agents/critic.md`

**2a. Add hybrid Red Flags / Rationalization table** (after Constraints section, end of file)

New section: `## Red Flags — you are about to rubber-stamp`

| Thought | Reality |
|---------|---------|
| "The plan is long and detailed, it must be good" | Length is not quality. Look for what is missing. |
| "I can't find problems, so there are none" | Look harder. Activate adversarial mode. |
| "This is a minor issue, not worth mentioning" | The critic exists to mention it. Report it. |
| "The approach is unusual but creative" | Unusual = risk. Document why it works or flag it. |
| "The plan follows project instructions, so it's correct" | Compliance is not correctness. Verify the logic. |
| "I already found 3 problems, that's enough" | Keep going. Problems hide behind other problems. |

### 3. `skills/verify/SKILL.md`

**3a. Rename "The Gate" to "The Iron Law"**

Change heading `## The Gate` to `## The Iron Law`. This modifies an existing gate (renaming + adding preamble), not just appending new content.

Add after the heading, before the numbered steps:

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.

Violating the letter of the rules is violating the spirit of the rules.
```

**3b. Add rationalization table** (after Red Flags section, before Scope section — add `---` before and after the new section, matching the existing separator pattern in the file)

New section: `## Red Flags — you are about to rationalize`

| Thought | Reality |
|---------|---------|
| "I read the code, it's correct" | Reading is not running. Run the command. |
| "I verified this 2 tasks ago" | Stale result. Run it again. |
| "The validation command isn't relevant for this change" | If it's in the plan, run it. |
| "The test passes in my head" | Tests pass in the terminal, not in your head. |

### 4. `skills/plan/SKILL.md`

**4a. Add hybrid Red Flags / Rationalization table** (after Step 9, end of file)

New section: `## Red Flags — you are about to skip a step`

| Thought | Reality |
|---------|---------|
| "The intent is clear, no need to clarify with the user" | Step 1 is mandatory. Clarify. |
| "I already know this codebase, research is unnecessary" | The 3 agents find what you don't know to look for. |
| "One research agent is enough for this simple case" | 3 agents, one message. No substitutions. |
| "The critic approved, but I improved the plan after" | Re-dispatch the critic. It must validate the changes. |
| "The user said 'go ahead', that means implement now" | That means approve the plan. Invoke /ops-implement. |
| "The spec is obvious, no need for spec-reviewer" | The reviewer finds what you forgot. Dispatch it. |
| "I'll skip the research adequacy table, it's clearly fine" | The table must appear in your output. It's not a mental check. |

### 5. `skills/implement/SKILL.md`

**5a. Add hybrid Red Flags / Rationalization table** (after the last section, end of file)

New section: `## Red Flags — you are about to break the pipeline`

| Thought | Reality |
|---------|---------|
| "These 2 tasks are small, I'll bundle them in one implementer" | 1 task = 1 agent. No bundling. The count audit will catch it. |
| "Code quality looks clean, no need to run it before the reviewer" | Hard gate. Quality BEFORE review. Always. |
| "The security-gate says NOT NEEDED but I have a doubt" | Dispatch the security-reviewer. False positives are cheap. |
| "Final validation is redundant, I validated each task" | Tasks interact. Re-validate ALL. Not some — ALL. |
| "The implementer reported DONE, no need to check" | Run the validation command yourself. Trust but verify. |

### 6. `skills/debug/SKILL.md`

**6a. Elevate Philosophy to Iron Law**

Replace:
```markdown
## Philosophy

Do NOT guess. Investigate systematically. Understand the root cause before writing a fix.
```

With:
```markdown
## The Iron Law

NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

Violating the letter of the rules is violating the spirit of the rules.

Do NOT guess. Investigate systematically. Understand the root cause before writing a fix.
```

**6b. Add hybrid Red Flags / Rationalization table** (after Circuit Breaker section, end of file)

New section: `## Red Flags — you are about to guess`

| Thought | Reality |
|---------|---------|
| "The error is obvious, no need to investigate" | Obvious errors hide deep root causes. Investigate. |
| "I've seen this bug before, I know the fix" | Confirm with evidence. Your memory may be wrong. |
| "One test is enough to validate the hypothesis" | Unless it's intermittent. Test multiple times. |
| "The fix works, no need for code review" | Unless it modifies ≤1 file and is a pure typo/config change. Otherwise review is mandatory. |
| "All hypotheses are refuted, I'll try a fix anyway" | Go back to Step 1. No fix without a confirmed root cause. |

### 7. CSO Description Updates (frontmatter only)

**7a. CSO-optimize skill frontmatter descriptions**

The CSO problem is in the SKILL.md YAML `description` fields, not in `bootstrap-context.md` itself. The bootstrap-context.md routing table and natural-language rules already use trigger-focused language ("If the user reports a bug, suggest /ops-debug"). No changes are needed in bootstrap-context.md.

Skill frontmatter `description` fields to rewrite (in each SKILL.md file):

| Skill | Current (process-focused) | Proposed (trigger-focused) |
|-------|---------------------------|----------------------------|
| `ops-do` | "Lightweight structured workflow: research, execute, verify, review." | "Use when the task is well-understood, small, and doesn't need design discussion." |
| `ops-implement` | "Execute a validated plan task by task." | "Use when a plan has been approved and you're ready to build." |
| `ops-refactor` | "Restructure code without changing behavior. Verifies test coverage first, then applies incremental changes with validation between each step." | "Use when code needs restructuring without changing its external behavior." |
| `ops-debug` | "Systematic debugging: investigate, hypothesize, fix." | "Use when something is broken, failing, or behaving unexpectedly." |
| `ops-plan` | "Clarify intent, research, and plan before writing code." | "Use when a task needs design, research, or decomposition before coding." |
| `ops-ship` | "Commit, PR, and capture learnings." | "Use when work is done and ready to commit or create a PR." |
| `ops-full` | "Full pipeline: plan, implement, and ship in a single session." | "Use when you want to plan, build, and ship a feature in one go." |

**7b. Files touched for CSO-only changes (description frontmatter updates)**

These 4 SKILL.md files are NOT in the core 7-file scope but receive a one-line frontmatter description change each:
- `skills/do/SKILL.md`
- `skills/refactor/SKILL.md`
- `skills/ship/SKILL.md`
- `skills/full/SKILL.md`

The remaining 3 skills (plan, implement, debug) are already in the core scope and get their frontmatter updated as part of those changes.

**Total files modified: 10** (6 core + 4 CSO-only).

## Validation

Since there is no test framework, validation is:
1. All modified files parse as valid markdown (no broken tables, no unclosed formatting)
2. Line counts: 6 core files grow by 10-20 lines each; 4 CSO-only files change 1 line each
3. No references to external projects or inspirations in the changes
4. Existing hard gates remain unchanged, except verify/SKILL.md where "The Gate" is renamed to "The Iron Law" (intentional upgrade, not a removal)
5. AGENTS.md rules followed: all content in English
6. Standard versioning rules apply (plugin.json, marketplace.json, package.json, CHANGELOG.md)

## Risks

1. **Overtriggering**: mitigated by using Commitment/Scarcity/Social Proof instead of more Authority
2. **Table fatigue**: mitigated by keeping tables short (5-7 rows each) and using hybrid format
3. **Stale rationalization entries**: mitigated by choosing rationalizations from documented session failures, not hypothetical ones
