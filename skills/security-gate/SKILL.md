---
name: ops:security-gate
description: "Internal: triage changes against 14 security triggers, dispatch security-reviewer if needed, handle re-verification loop. Activated during final review in implement, do, and security skills."
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

**Output:**

```
## Security Triage
- Security-sensitive areas in diff: YES / NO
- Triggers matched: <list which triggers and which files>
- Security-reviewer dispatch: YES / NOT NEEDED
```

If ANY trigger matches, dispatch the security-reviewer. If in doubt, dispatch — false positives are cheap; missed vulnerabilities are not.

**If NO triggers match**: stop here. No security-reviewer needed.

## Step 2: Re-verification loop

If the security-reviewer finds **critical issues** and fixes are applied, re-dispatch to verify. Follow the `ops:redispatch-optimization` process for the re-dispatch prompt.

- **Cap at 3 iterations.** If not approved after 3 rounds, stop and escalate to the user with a summary of all unresolved findings.
- **Each iteration**: fix issues → re-dispatch with optimized prompt → check verdict.
- If the re-review surfaces **new** critical issues, fix them and re-dispatch again (within the 3-iteration cap).
