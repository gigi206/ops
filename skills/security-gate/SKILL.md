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

## Step 1b: SAST Scan

Check if `semgrep` is available (`which semgrep`).

If available:
1. Scope the file list to the same files evaluated in Step 1. Use `git diff --name-only` to obtain the modified file list in the current context.
2. Determine config: **prefer local config** — check for `.semgrep/` directory or `.semgrep.yml` in project root. If local config exists but has no rules (empty `rules: []`), treat it as absent and fall back. Use local config if present and non-empty (`semgrep scan --config .semgrep/ --json` or `--config .semgrep.yml`), fall back to `--config auto` otherwise (downloads generic rules from network — slower, requires connectivity, less project-tuned).
3. **Diff-aware scanning**: determine the baseline commit to report only **new** findings (not pre-existing ones):
   - If on a feature branch: use the merge-base with the main branch (`git merge-base HEAD main` or `master`).
   - If on the main branch: use `HEAD~1` (last commit).
   - Add `--baseline-commit=<ref>` to the scan command. This makes semgrep report only findings introduced since that commit.
   - If the baseline commit cannot be determined (e.g., shallow clone, detached HEAD), omit `--baseline-commit` and note in the report: "baseline unavailable — showing all findings".
4. Run: `semgrep scan <config flag> --json --baseline-commit=<ref> <modified files>`
5. Parse JSON output for findings. Classify each finding by severity (ERROR, WARNING, INFO).
6. If findings with severity WARNING or ERROR exist, **evaluate each finding in context of the diff** before deciding to dispatch:
   - If at least one finding is plausible (not an obvious false positive given the code context), force security-reviewer dispatch (regardless of Step 1 triage result). Include Semgrep findings summary in the security-reviewer context with the instruction: "Evaluate each semgrep finding for relevance. Semgrep `--config auto` uses generic rules — treat findings as signals to investigate, not as confirmed vulnerabilities. Dismiss false positives with a brief justification."
   - If ALL findings are clearly false positives (e.g., `hashlib.md5()` in non-crypto hashing, `eval()` in a template engine), do NOT force dispatch. Note in triage output: "SAST: N findings, all dismissed as false positives" with a one-line justification per finding.
7. If findings are INFO-only: note in triage output but do NOT force dispatch (INFO findings alone are insufficient to trigger a review cycle).
8. If no findings: note as clean.

If not available: continue with Step 1 triage result only.

> **Note:** `--config auto` requires network access to download rule packs. In air-gapped environments, provide a local config (`.semgrep/` or `.semgrep.yml`).

If semgrep crashes, times out, or fails (network error for --config auto):
- Inform the user: "Semgrep SAST skipped: <reason>. Continuing with LLM triage only."
- Do not block the pipeline.

## Step 1c: Incorporate qlty security findings

If `ops:code-quality` was run before this gate (which is the normal sequence), check its report for a `Security findings from qlty` line. These come from security-focused qlty plugins (trivy, trufflehog, osv-scanner, bandit, checkov) and should be treated as additional signals alongside semgrep findings.

- If qlty reported security findings: include them in the triage output and in the security-reviewer context (if dispatched).
- If qlty reported no security findings or was not run: proceed normally.

## Dispatch Decision

After completing Step 1 (triage), Step 1b (SAST scan), and Step 1c (qlty security findings), produce the combined output:

```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- SAST (semgrep): <N new findings (E errors, W warnings, I info)> / clean / not found / error
- Security findings from qlty: <list> / none / not run
- Security-reviewer dispatch: YES / NOT NEEDED
```

If ANY trigger matches OR semgrep reports plausible WARNING/ERROR findings (after gate triage) OR qlty reports security findings, dispatch the security-reviewer. If in doubt, dispatch — false positives are cheap; missed vulnerabilities are not.

**If NO triggers match AND no plausible findings from semgrep or qlty**: stop here. No security-reviewer needed.

## Step 2: Re-verification loop

If the security-reviewer finds **critical issues** and fixes are applied, re-dispatch to verify. Follow the `ops:redispatch-optimization` process for the re-dispatch prompt.

- **Cap at 3 iterations.** If not approved after 3 rounds, stop and escalate to the user with a summary of all unresolved findings.
- **Each iteration**: fix issues → re-dispatch with optimized prompt → check verdict.
- If the re-review surfaces **new** critical issues, fix them and re-dispatch again (within the 3-iteration cap).
