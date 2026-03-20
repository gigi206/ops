---
name: ops:research
description: "Autonomous codebase and documentation exploration. Dispatches 3 research agents in parallel."
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
1. Clarify → 2. Parallel Research (3 agents) → 3. Synthesize → 4. Present
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

---

## Step 4: Present

Present a structured synthesis to the user:

```markdown
## Research: <topic>

### Codebase Patterns
- [Key findings from researcher-code]

### Documentation
- [Key findings from researcher-doc, with sources and versions]

### History & Ownership
- [Key findings from git-historian]

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
