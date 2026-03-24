# ops — Project Instructions

## Architecture: scripts vs. prompts

Logic with complex deterministic branching (config detection, baseline selection, structured parsing) lives in `scripts/`. Scripts are prefixed `ops-` to avoid PATH namespace collisions.

Logic that requires judgment, contextual interpretation, or adaptation to unforeseen cases stays in skills markdown files.

When in doubt: if the logic can be expressed as a pure function of inputs (files, env vars, git state) with no need for LLM reasoning, it belongs in a script.

## Versioning

Every change must update the version in three places:
1. `.claude-plugin/plugin.json` (`version` field)
2. `.claude-plugin/marketplace.json` (`version` field)
3. `CHANGELOG.md` (new section at the top)
