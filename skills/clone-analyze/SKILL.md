---
name: ops-clone-analyze
description: "Clone and analyze an external repository. Use when you need to understand a library, framework, application, or tool by reading its source code."
---

# /ops-clone-analyze — Repository analysis

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Purpose

Clone and analyze an external repository to answer questions that documentation and web research cannot resolve. Use this when you need to understand a library's internals, verify undocumented behavior, check if a bug is fixed in a newer version, or study how an application implements a specific feature.

---

## Workflow

```
1. Clarify → 2. Dispatch researcher-repo → 3. Present
```

---

## Step 1: Clarify

Restate the user's question and identify the target:
- What is the user trying to understand?
- Which library, framework, application, or tool is involved?
- Is there a specific version to analyze?

If the user provides neither a repo URL nor a library name:
1. Check local package manifests (`package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`, etc.) for dependencies related to the question
2. If still ambiguous, ask the user to specify the target

---

## Step 2: Dispatch researcher-repo

Spawn the **researcher-repo** agent with:
- The user's question
- The version used in the local project (if applicable)
- Any additional context from the conversation

The agent handles repository location internally (manifests, web search, disambiguation).

**Wait for the agent to return before proceeding.**

---

## Step 3: Present

Pass through the agent's structured output directly (Repository Analysis format).

Ask: "Want to dig deeper into any section, or is this sufficient?"

---

## Constraints

- **Do NOT make changes.** This skill is read-only — no edits, no commits.
- **Do NOT plan.** If the user wants to plan based on findings, suggest `/ops-plan`.
- **No confidence gate** — this is an explicit user request, not a conditional trigger.
- **Cite sources.** Every finding must reference its source (file:line from the cloned repo, commit hash).
