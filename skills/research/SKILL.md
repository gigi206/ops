---
name: ops:research
description: "Autonomous codebase and documentation exploration. Dispatches 3 research agents in parallel, with conditional repository cloning when documentation is insufficient."
---

# /ops:research — Autonomous exploration

## Instruction Priority

Follow the `ops:instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops:subagent-rules` process.

## Purpose

Explore a topic autonomously without planning or implementation. Use this when you need to understand a codebase area, gather documentation, or investigate history — without committing to a plan or making changes.

---

## Workflow

```
1. Clarify → 2. Parallel Research (3 agents) → 3. Synthesize → 4. Conditional Clone (if researcher-doc requests it) → 5. Final Synthesize → 6. Present
```

---

## Step 1: Clarify

Restate the user's question or topic in one sentence to confirm understanding. If the scope is too broad, ask one clarifying question before dispatching agents.

---

## Step 2: Parallel Research

Spawn 3 agents **in parallel** — all 3 Agent tool_use blocks in a **single message** (see `ops:subagent-rules`):

### researcher-code
- Explore the codebase for patterns, conventions, existing implementations, integration points, and risks relevant to the topic.
- Map architecture: trace dependency chains, identify what depends on what.
- Flag risks: missing tests, fragile patterns, undocumented assumptions.

### researcher-doc
- Query Context7 MCP for relevant library/tool documentation.
- If Context7 returns insufficient results, fall back to WebSearch + WebFetch.
- Focus: official docs, API schemas, configuration references for the specific versions involved.

### git-historian — Research Mode
- Scope: files and directories relevant to the topic.
- Window: 6 months.
- Focus: all (timeline, regressions, ownership, hotspots, architectural milestones).
- Build commit timeline, detect regressions, map ownership, identify hotspots.
- **Output**: structured YAML with risk assessment (HIGH/MEDIUM/LOW per area).

**Wait for all 3 agents to return before proceeding.**

---

## Step 3: Synthesize

Combine findings from all 3 agents into a coherent picture. Identify:
- **Agreements**: where all agents converge
- **Gaps**: what wasn't found or remains unclear
- **Contradictions**: where agents disagree (different versions, conflicting patterns)

Check whether repository cloning is needed by parsing researcher-doc's `Source Verification Needed` list:
1. If the field is **absent** → proceed to Step 6 (Present). Add a warning in the synthesis: "> ⚠ researcher-doc did not return Source Verification Needed field"
2. Collect all targets with `Needed: high` into a list. If the list is empty (all targets are `none` or `low`) → proceed to Step 6 (Present). Note any `low` gaps in the synthesis for transparency.
3. If one or more targets have `Needed: high` → proceed to Step 4 (Conditional Repository Analysis) with the list of high targets.

---

## Step 4: Conditional Repository Analysis

**This step only runs when researcher-doc signaled `Needed: high` for one or more targets.**

For each target in the high list, dispatch a **researcher-repo** agent with:
- The target name and ecosystem (from the `Source Verification Needed` entry)
- The original question/topic
- The synthesized findings from Step 3 (so it knows what was already found and where the gaps are)
- The rationale from researcher-doc explaining what is missing for this target
- Any repo name/URL mentioned in the question or in the agents' findings

**Dispatch all researcher-repo agents in parallel** — all Agent tool_use blocks in a **single message** (see `ops:subagent-rules`). If only one target has `high`, dispatch a single agent.

Each researcher-repo agent will:
1. Locate and clone the relevant external repository
2. Analyze the version matching the project's dependencies
3. Optionally analyze HEAD/main for fixes and new features
4. Return structured findings

**Wait for all agents to return before proceeding.**

---

## Step 5: Final Synthesis

**This step only runs if Step 4 was executed.**

Integrate the `researcher-repo` findings into the synthesis from Step 3:
- Update or resolve gaps identified earlier
- Note any contradictions between repository analysis and prior findings

---

## Step 6: Present

Present a structured synthesis to the user:

```markdown
## Research: <topic>

### Codebase Patterns
- [Key findings from researcher-code]

### Documentation
- [Key findings from researcher-doc, with sources and versions]

### History & Ownership
- [Key findings from git-historian]

### Repository Analysis
- [Key findings from researcher-repo, if dispatched]
- [Version used vs HEAD comparison, if applicable]

### Risk Assessment
- [HIGH/MEDIUM/LOW areas with justification]

### Gaps
- [What remains unclear or wasn't found]
```

Ask the user if they want to dig deeper into any area, or if this is sufficient context to proceed with planning or implementation.

---

## Constraints

- **Do NOT make changes.** This skill is read-only — no edits, no commits.
- **Do NOT plan.** If the user wants to plan based on research, suggest `/ops:plan`.
- **Cite sources.** Every finding must reference its source (file:line, doc URL, commit hash).
