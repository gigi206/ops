---
name: ops:security-gate
description: "Internal: triage changes against 14 security triggers + SAST scan (semgrep), dispatch security-reviewer if needed, handle re-verification loop. Activated during final review in implement, do, and security skills."
user-invocable: false
---

# Security Gate — Triage, Dispatch & Re-verify

## Step 1: Triage

Evaluate the changes against these security domain triggers:

- Authentication, authorization, or identity federation
- APIs, endpoints, or interfaces exposed beyond the trust boundary
- Secrets, credentials, keys, or tokens (creation, storage, rotation, transmission)
- Encryption, TLS, or certificate configuration
- User input handling or data validation
- Access control rules or permission models
- Network exposure, firewall rules, or traffic policies
- Infrastructure definitions (IaC) that provision or modify security-relevant resources
- CI/CD pipeline configuration (build, deploy, release workflows)
- Container, VM, or runtime privilege configuration
- Dependency or supply chain changes (new packages, registries, image sources)
- Policy enforcement, admission control, or compliance rules
- Data storage, retention, or backup configuration handling sensitive data
- Logging, audit, or observability configuration (risk of leaking sensitive data)

## Step 1b: SAST Scan (optional)

Check if `semgrep` is available (`which semgrep`).

If available:
1. Scope the file list to the same files evaluated in Step 1. Use `git diff --name-only` to obtain the modified file list in the current context.
2. Determine config: **prefer local config** — check for `.semgrep/` directory or `.semgrep.yml` in project root. Use local config if present (`semgrep scan --config .semgrep/ --json` or `--config .semgrep.yml`), fall back to `--config auto` otherwise (downloads generic rules from network — slower, requires connectivity, less project-tuned).
3. Run: `semgrep scan <config flag> --json <modified files>`
4. Parse JSON output for findings. Classify each finding by severity (ERROR, WARNING, INFO).
5. If findings with severity WARNING or ERROR exist, **evaluate each finding in context of the diff** before deciding to dispatch:
   - If at least one finding is plausible (not an obvious false positive given the code context), force security-reviewer dispatch (regardless of Step 1 triage result). Include Semgrep findings summary in the security-reviewer context with the instruction: "Evaluate each semgrep finding for relevance. Semgrep `--config auto` uses generic rules — treat findings as signals to investigate, not as confirmed vulnerabilities. Dismiss false positives with a brief justification."
   - If ALL findings are clearly false positives (e.g., `hashlib.md5()` in non-crypto hashing, `eval()` in a template engine), do NOT force dispatch. Note in triage output: "SAST: N findings, all dismissed as false positives" with a one-line justification per finding.
6. If findings are INFO-only: note in triage output but do NOT force dispatch (INFO findings alone are insufficient to trigger a review cycle).
7. If no findings: note as clean.

If not available: continue with Step 1 triage result only.

> **Note:** `--config auto` requires network access to download rule packs. In air-gapped environments, provide a local config (`.semgrep/` or `.semgrep.yml`).

If semgrep crashes, times out, or fails (network error for --config auto):
- Inform the user: "Semgrep SAST skipped: <reason>. Continuing with LLM triage only."
- Do not block the pipeline.

## Dispatch Decision

After completing Step 1 (triage) and Step 1b (SAST scan), produce the combined output:

```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- SAST (semgrep): <N findings (E errors, W warnings, I info)> / clean / not found / error
- Security-reviewer dispatch: YES / NOT NEEDED
```

If ANY trigger matches OR semgrep reports plausible WARNING/ERROR findings (after gate triage), dispatch the security-reviewer. If in doubt, dispatch — false positives are cheap; missed vulnerabilities are not.

**If NO triggers match AND semgrep reports no plausible findings (all dismissed, clean, or unavailable)**: stop here. No security-reviewer needed.

## Step 2: Re-verification loop

If the security-reviewer finds **critical issues** and fixes are applied, re-dispatch to verify. Follow the `ops:redispatch-optimization` process for the re-dispatch prompt.

- **Cap at 3 iterations.** If not approved after 3 rounds, stop and escalate to the user with a summary of all unresolved findings.
- **Each iteration**: fix issues → re-dispatch with optimized prompt → check verdict.
- If the re-review surfaces **new** critical issues, fix them and re-dispatch again (within the 3-iteration cap).
