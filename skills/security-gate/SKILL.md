---
name: ops-security-gate
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

**Complexity filter**: If ALL of the following are true, a trigger match is LOW-SENSITIVITY and should NOT force dispatch by itself (only dispatch if semgrep or qlty also report findings):
- The diff touches fewer than 50 lines of code (excluding comments, blank lines, and test files)
- The changes are limited to boolean flags, configuration values, or feature toggles (no new logic paths, no new conditional branches)
- No new external interfaces are introduced (no new endpoints, CLI commands, exports, or protocol messages)

**Always-dispatch triggers** (bypass the complexity filter): authentication/identity federation, secrets/credentials/keys/tokens, encryption/TLS/certificates, and CI/CD pipeline configuration. These are high-impact regardless of diff size.

## Step 1b: SAST Scan

Run `ops-semgrep-scan.sh [--config <path>] <modified files>` (the script is on PATH via the session-start hook). If you already know the semgrep config path (e.g., `.semgrep/` or `.semgrep.yml` in project root), pass it via `--config`. Otherwise, omit `--config` and the script auto-detects. The script handles diff-aware baseline selection and error handling.

The script outputs key=value metadata lines, followed by raw semgrep JSON (separated by a blank line) when findings are present. Parse the metadata lines first:

- `status=not_installed` → semgrep not available. Continue with Step 1 triage result only.
- `status=error` → semgrep failed. Read the `error=` line. Inform the user: "Semgrep SAST skipped: `<error>`. Continuing with LLM triage only." Do not block the pipeline.
- `status=no_files` → no modified files to scan. Note as clean.
- `status=no_findings` → semgrep ran, no findings. Note as clean. Raw JSON follows but contains no results.
- `status=findings_unknown` → semgrep ran, but no JSON parser (jq/python3) was available to count results. Parse the raw semgrep JSON yourself to determine findings. Treat as `status=findings` for dispatch purposes.
- `status=findings` → findings present. Parse the raw semgrep JSON that follows the blank line. Extract `results[]` entries and check each finding's `extra.severity`:
  - **WARNING or ERROR**: evaluate each finding in context of the diff before deciding to dispatch:
    - If at least one finding is plausible (not an obvious false positive), force security-reviewer dispatch (regardless of Step 1 triage result). Include findings summary in the security-reviewer context with: "Evaluate each semgrep finding for relevance. Treat findings as signals to investigate, not confirmed vulnerabilities. Dismiss false positives with a brief justification."
    - If ALL findings are clearly false positives (e.g., `hashlib.md5()` in non-crypto hashing), do NOT force dispatch. Note: "SAST: N findings, all dismissed as false positives" with a one-line justification per finding.
  - **INFO-only**: note in triage output but do NOT force dispatch.

## Step 1c: Incorporate qlty security findings

If `ops-code-quality` was run before this gate (which is the normal sequence), check its report for a `Security findings from qlty` line. These come from security-focused qlty plugins (trivy, trufflehog, osv-scanner, bandit, checkov) and should be treated as additional signals alongside semgrep findings.

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

If the security-reviewer finds **critical issues** and fixes are applied, re-dispatch to verify. Follow the `ops-redispatch-optimization` process for the re-dispatch prompt.

- **Cap at 3 iterations.** If not approved after 3 rounds, stop and escalate to the user with a summary of all unresolved findings.
- **Each iteration**: fix issues → re-dispatch with optimized prompt → check verdict.
- If the re-review surfaces **new** critical issues, fix them and re-dispatch again (within the 3-iteration cap).
