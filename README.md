# ops

A structured development workflow for Claude Code, OpenCode, and other AI coding CLIs. Plan, implement, debug, review, secure, and ship with discipline.

## Quick use

> **First time?** See [Install](#install) then run `/ops-init` inside your project.

```
# Main pipeline
/ops-plan add rate limiting to the API     →  /ops-implement  →  /ops-ship
                                                      ↑
                                               /ops-debug (when bugs arise)

# Or all at once
/ops-full add rate limiting to the API     (= plan → implement → ship)

# Specialized pipelines
/ops-do        rename the logger to use structured output
/ops-debug     users get 500 on /api/auth
/ops-test      src/auth/
/ops-refactor  split the god class in OrderService
/ops-perf      /api/search takes 3s, target 500ms
/ops-review-pr 42

# Standalone
/ops-research  how does the payment flow work
/ops-clone-analyze how does express handle middleware error propagation
/ops-brainstorm I need some kind of caching layer
/ops-security

# Useful combo
/ops-brainstorm → /ops-do         clarify needs first, then execute
```

## What it does

ops enforces a staged workflow with explicit gates, parallel research, adversarial review, and evidence-based verification. Every claim requires proof. Every major step requires review.

### Workflow

```mermaid
flowchart TD
    %% Pre-work
    brainstorm["/ops-brainstorm"] -.->|clarifies intent| plan
    brainstorm -.->|clarifies intent| do
    research["/ops-research"] -.->|gathers context| plan

    %% Main pipeline
    plan["/ops-plan"] -->|approved plan| implement["/ops-implement"]
    implement -->|code ready| ship["/ops-ship"]

    %% Full chains the main pipeline
    full["/ops-full"] ==>|"= plan → implement → ship"| plan

    %% Lightweight alternative
    do["/ops-do"] -->|code ready| ship

    %% Bug fixing
    debug["/ops-debug"] -->|fix ready| ship
    debug -.->|bugs during| implement

    %% Testing & refactoring
    test["/ops-test"] -->|tests added| ship
    test -.->|coverage gate| refactor
    refactor["/ops-refactor"] -->|restructured| ship

    %% Performance
    perf["/ops-perf"] -->|optimized| ship

    %% Reviews & audits
    review-pr["/ops-review-pr"] -.->|comments on PR| ship
    security["/ops-security"] -.->|reviews| ship

    %% Always active or standalone (no edges — behavioral or independent)
    clone-analyze["/ops-clone-analyze"]
    review["/ops-review"]
    verify["/ops-verify"]
    setup["/ops-init"]
```

**Legend:** solid arrow = produces output for the next skill, dashed arrow = optional/contextual relationship, thick arrow = chains the full pipeline, isolated nodes = behavioral (always active).

### Agent dispatch

```mermaid
flowchart LR
    %% ─── Skills ───
    research["/ops-research"]
    plan["/ops-plan"]
    implement["/ops-implement"]
    do["/ops-do"]
    debug["/ops-debug"]
    test["/ops-test"]
    refactor["/ops-refactor"]
    perf["/ops-perf"]
    review-pr["/ops-review-pr"]
    security["/ops-security"]
    audit["/ops-audit"]
    clone-analyze["/ops-clone-analyze"]

    %% ─── Research agents ───
    subgraph research_agents["Research"]
        rc{{"researcher-code"}}
        rd{{"researcher-doc"}}
        gh{{"git-historian"}}
        rr{{"researcher-repo"}}
    end

    %% ─── Review agents ───
    subgraph review_agents["Review"]
        sr{{"spec-reviewer"}}
        cr{{"critic"}}
        codrev{{"code-reviewer"}}
        secrev{{"security-reviewer"}}
        prrev{{"pr-reviewer"}}
    end

    %% ─── Build agents ───
    subgraph build_agents["Build"]
        imp{{"implementer ×N"}}
        tw{{"test-writer"}}
    end

    %% ─── Dispatch ───
    research --> rc & rd & gh
    research -.->|conditional| rr
    plan --> sr & cr
    implement --> imp & codrev
    implement -.->|if triggers| secrev
    do --> rc & rd & codrev
    do -.->|if triggers| secrev
    debug --> gh & codrev
    debug -.->|if triggers| secrev
    test --> rc & rd & tw & codrev
    refactor --> rc & rd & codrev
    perf --> rc & rd & codrev
    review-pr --> prrev
    review-pr -.->|if triggers| secrev
    security --> secrev
    clone-analyze --> rr
```

**Legend:** solid arrow = always dispatched, dashed arrow = conditional (`if triggers` = security-gate, `conditional` = insufficient confidence). Agents grouped by role: Research (read-only exploration), Review (adversarial analysis), Build (code generation).

### Pipeline skills

| Skill            | Role                                                     | Input                              | Output                                            | Agents dispatched                                                               |
| ---------------- | -------------------------------------------------------- | ---------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------- |
| `/ops-plan`      | Design and plan before coding                            | Clarified need                     | Spec + plan decomposed into tasks + user approval | via research, spec-reviewer, critic                                             |
| `/ops-implement` | Execute the plan task by task with per-task quality review | Validated plan                     | Implemented, reviewed, and validated code         | implementer (xN), code-reviewer (per-task lightweight + final), security-reviewer (if triggers) |
| `/ops-ship`      | Commit, PR, capture learnings                            | Completed code                     | Commit, PR (optional), learnings                  | None                                                                            |
| `/ops-do`        | Lightweight pipeline: research, execute, verify, review  | Well-understood task               | Implemented and reviewed code                     | researcher-code, researcher-doc, code-reviewer, security-reviewer (if triggers) |
| `/ops-debug`     | Systematic investigation: hypothesize, test, fix, verify | Bug, error, or unexpected behavior | Diagnosed and fixed code                          | git-historian, code-reviewer, security-reviewer (if triggers)                   |
| `/ops-full`      | All-in-one meta-pipeline                                 | Work description                   | Everything (plan + implement + ship chained)      | All from plan + implement + ship                                                |
| `/ops-test`      | Add tests to existing untested code                      | Files/modules to test              | Tests written, coverage improved                  | researcher-code, researcher-doc, test-writer, code-reviewer                     |
| `/ops-refactor`  | Restructure code without changing behavior               | Code to refactor + goal            | Refactored code, tests still passing              | researcher-code, researcher-doc, code-reviewer                                  |
| `/ops-perf`      | Performance investigation and optimization               | What's slow + target               | Optimized code with measured before/after         | researcher-code, researcher-doc, code-reviewer                                  |
| `/ops-review-pr` | Review an external pull request                          | PR number/URL                      | Structured review with actionable comments        | pr-reviewer, security-reviewer (if triggers)                                    |

### Standalone skills

| Skill                | Role                                                                                       | When to use                                                         |
| -------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| `/ops-research`      | Explore codebase and documentation (3 agents + conditional repo clone)                     | Understand a codebase area, gather docs, investigate history        |
| `/ops-clone-analyze` | Clone and analyze an external repo to understand its internals                             | Understand a library, framework, or tool by reading its source code |
| `/ops-brainstorm`    | Clarify needs via Socratic dialogue                                                        | Explore intent and requirements before planning                     |
| `/ops-review`        | Technically evaluate code review feedback                                                  | Receiving comments on code (human or CI)                            |
| `/ops-security`      | On-demand security review                                                                  | Security review of changes or specific files                        |
| `/ops-audit`         | Full codebase audit — code quality (qlty) + security (semgrep) with cross-triage           | First arrival on project, pre-release, periodic health check        |
| `/ops-init`          | 6-phase environment diagnostic: recap, ops tools, linters, prerequisites, build tools, LSP | First use, new environment, missing tools                           |
| `/ops-verify`        | Behavioral rule: evidence before any claim                                                 | Always active — applies in all contexts                             |

### Internal phases (`user-invocable: false`)

Shared logic extracted from skills. Not callable by the user — invoked programmatically by parent skills.

| Phase                         | Role                                                                                                                                        | Used by                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `ops-instruction-priority`    | Instruction hierarchy (user > project instructions > ops skill > system prompt)                                                             | all skills                                                                            |
| `ops-subagent-rules`          | Context rules for dispatching subagents (inline content, scoping, labeling, LSP usage)                                                      | plan, implement, do, debug, research, clone-analyze, test, refactor, perf, review-pr  |
| `ops-code-quality`            | Format, lint, and structural analysis (smells, metrics) on modified files (qlty or project tools) before code review                        | implement, do, debug, test, refactor, perf                                            |
| `ops-discovery-checks`        | Categorize unexpected discoveries (Minor / Significant / Major)                                                                             | implement, debug                                                                      |
| `ops-circuit-breaker`         | Diagnose repeated failures (researcher-code + git-historian)                                                                                | implement (3+ failures), debug (5+ failures)                                          |
| `ops-security-gate`           | Triage (14 triggers) + SAST scan (semgrep, diff-aware) + qlty security findings + dispatch security-reviewer + re-verification loop (cap 3) | implement, do, debug, security, review-pr                                             |
| `ops-review-pipeline`         | Build verification → code quality → security gate → code review → project instruction check                                                 | do, perf, refactor, test                                                              |
| `ops-redispatch-optimization` | Generic re-dispatch prompt optimization for review agents                                                                                   | plan (spec-reviewer, critic), implement (code-reviewer), security (security-reviewer) |

### Agents

| Agent                 |      Model      | Role                                                                                       | Dispatched by                                                                            |
| :-------------------- | :-------------: | :----------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------- |
| **researcher-code**   |   opus (high)   | Explore codebase: patterns, conventions, implementations, integration points, risks        | research, do, test, refactor, perf, implement (circuit-breaker), debug (circuit-breaker) |
| **researcher-doc**    | sonnet (medium) | Search official docs for libs/tools/APIs (Context7 MCP, fallback WebSearch)                | research, do, test, refactor, perf                                                       |
| **git-historian**     | sonnet (medium) | Mine git history: timelines, regressions, ownership, hotspots, architectural decisions     | research, debug, implement (circuit-breaker)                                             |
| **researcher-repo**   |   opus (high)   | Clone and analyze external repositories: version-aware analysis, structured findings       | research (conditional), clone-analyze                                                    |
| **spec-reviewer**     |   opus (high)   | Review spec for completeness, consistency, clarity, and feasibility                        | plan                                                                                     |
| **critic**            |   opus (high)   | Adversarial plan review: 5 lenses (incl. architectural alternatives), 4 perspectives incl. Architect — see [`agents/critic.md`](agents/critic.md) | plan                                                                                     |
| **implementer**       |   opus (high)   | Execute one plan task (TDD, code generation, validation)                                   | implement                                                                                |
| **code-reviewer**     |   opus (high)   | Code review: spec compliance, quality, TDD adherence, anti-patterns                        | implement (per-task lightweight + final review), do, test, refactor, perf                |
| **security-reviewer** |   opus (high)   | Deep security analysis: code, infra, CI/CD, containers, supply chain                       | security-gate: implement, do, debug, security, review-pr                                 |
| **test-writer**       |   opus (high)   | Analyze existing code and write tests: behavior analysis, edge cases, coverage             | test                                                                                     |
| **pr-reviewer**       |   opus (high)   | Review external PRs: quality, security, conventions, actionable comments                   | review-pr                                                                                |

## Install

### Claude Code

#### From marketplace (recommended)

Add the marketplace, then install the plugin:

```
/plugin marketplace add gigi206/ops
/plugin install ops
```

#### From a local clone

If you have a local clone of the repository:

```
/plugin install /path/to/ops
```

### OpenCode

Tell OpenCode:

> Fetch and follow instructions from https://raw.githubusercontent.com/gigi206/ops/refs/heads/main/.opencode/INSTALL.md

Or manually add to your `opencode.json`:

```json
{
  "plugin": ["ops@git+https://github.com/gigi206/ops.git"]
}
```

Detailed docs: [docs/opencode/README.md](docs/opencode/README.md)

### Verify

After install, restart Claude Code and type `/ops-plan`. If the skill loads, you're set.

### Setup (recommended)

Run the environment diagnostic to check your tooling:

```
/ops-init
```

This detects the CLI (Claude Code / OpenCode), languages, LSP availability, code quality tools (qlty), security analysis tools (semgrep), and MCP servers (context7, chrome-devtools-mcp). It proposes installation for anything missing.

## Requirements

- **Claude Code** — required
- **Node.js** — only needed for the visual brainstorm companion (optional)
- **Git** — needed by the git-historian agent (optional, skipped if unavailable)
- **Context7 MCP** — needed by researcher-doc (optional, falls back to web search). Install: `/plugin install context7@claude-plugins-official`
- **chrome-devtools-mcp** — needed by ops-debug for browser debugging, accessibility audits, LCP optimization (optional). Install: `/plugin install chrome-devtools-mcp@chrome-devtools-plugins`
- **qlty** — optional, used by code-quality for unified formatting, linting, and structural analysis (smells, metrics, security plugins) (install: `curl https://qlty.sh | bash`)
- **semgrep** — optional, used by security-gate for SAST scanning (install: `pip install semgrep`)

No npm dependencies. No database. No compiled binaries.

## Usage

### Quick start

```
/ops-plan add rate limiting to the API endpoints
```

After the plan is approved:

```
/ops-implement
```

When done:

```
/ops-ship
```

### Tips

- **Unknown library or tool?** — Use `/ops-clone-analyze` to read the source code of an external library, framework, or tool. ops can also trigger this automatically during `/ops-research` when documentation is insufficient — it clones the source into a temporary directory, analyzes it, and cleans up.

## Skills Reference

### `/ops-plan`

Brainstorm, research, and plan before writing code.

```
/ops-plan <description of what you want to do>
```

| Step               | What happens                                                         |
| ------------------ | -------------------------------------------------------------------- |
| Brainstorm         | Socratic-style design discussion — one question at a time            |
| Context detection  | Detect languages, check LSP availability, read project conventions   |
| Parallel research  | Delegates to `/ops-research` (3 agents in parallel)                  |
| Research adequacy  | Evidence table presented to user — gaps trigger follow-up research   |
| Design approaches  | 2-3 options with pros/cons, recommendation first                     |
| Spec writing       | Design document written, reviewed by spec-reviewer, approved by user |
| Task decomposition | Ordered tasks with files, changes, and validation commands           |
| Critic review      | Adversarial review (5 lenses incl. architectural alternatives, 4 perspectives incl. Architect, self-audit) |
| User approval      | Plan presented for final approval before implementation              |

```mermaid
flowchart TD
    B["Brainstorm"] --> C["Context detection"]
    C --> R{{"researcher-code + researcher-doc + git-historian"}}
    R -.->|confidence insufficient| RR{{"researcher-repo"}}
    R --> RA["Research adequacy"]
    RA --> D["Design approaches"]
    D --> S["Spec writing"]
    S --> SR{{"spec-reviewer"}}
    SR --> T["Task decomposition"]
    T --> CR{{"critic"}}
    CR --> A["User approval"]
```

Agents used: via **`/ops-research`** (researcher-code, researcher-doc, git-historian, **researcher-repo** conditional), **spec-reviewer**, **critic**

---

### `/ops-full`

Full pipeline: plan, implement, and ship in a single session.

```
/ops-full <description of what you want to do>
```

Chains `/ops-plan` → user approval → `/ops-implement` → `/ops-ship`. Each sub-skill runs in full with all gates preserved.

```mermaid
flowchart LR
    plan["/ops-plan"] --> approval{"User approval"} --> implement["/ops-implement"] --> ship["/ops-ship"]
```

---

### `/ops-do`

Lightweight structured workflow for well-understood tasks.

```
/ops-do <description of what you want to do>
```

| Step                         | What happens                                                                                        |
| ---------------------------- | --------------------------------------------------------------------------------------------------- |
| Restatement                  | Quick reformulation of intent — no brainstorming                                                    |
| Research                     | 2 agents in parallel: researcher-code, researcher-doc                                               |
| Scope guard                  | If too complex, suggest escalating to `/ops-plan`                                                   |
| Tasks (optional)             | Light task breakdown based on decision complexity                                                   |
| Execute                      | Implement changes directly                                                                          |
| Verify + Code quality        | Build/compile check + format, lint, structural analysis (`ops-code-quality`, qlty or project tools) |
| Security gate + Code review  | Security triage + light code review (1 cycle max)                                                   |
| Tests + Docs + Project rules | Run tests, update docs, verify project rules                                                        |

```mermaid
flowchart TD
    RS["Restatement"] --> R{{"researcher-code + researcher-doc"}}
    R --> SG["Scope guard"]
    SG --> E["Execute"]
    E --> V["Verify + Code quality"]
    V --> ST["Security triage"]
    ST --> CODREV{{"code-reviewer"}}
    ST -.->|if triggers| SECREV{{"security-reviewer"}}
    CODREV --> T["Tests + Docs"]
```

Agents used: **researcher-code**, **researcher-doc**, **code-reviewer**, **security-reviewer** (if triggers)

---

### `/ops-implement`

Execute a validated plan task by task.

```
/ops-implement
```

Prerequisite: a plan from `/ops-plan` or user-provided.

Each task goes through the full pipeline:

| Step             | What happens                                                |
| ---------------- | ----------------------------------------------------------- |
| Implementer      | One agent per task, TDD enforced when tests are relevant    |
| Validation gate  | Run validation commands, show output — no "it should work"  |
| Conformity check | Diff vs. plan — no drift, no secrets, conventions preserved |
| Discovery check  | Pause on significant findings, stop on major discoveries    |

After all tasks: code quality (`ops-code-quality`: format, lint, smells, metrics) → security triage (semgrep + qlty findings) → final review (code-reviewer + security-reviewer if applicable).

**Security escalation triggers** — the security-reviewer is dispatched when the task touches:

- Authentication, authorization, or identity federation
- APIs or interfaces exposed beyond the trust boundary
- Secrets, credentials, keys, or tokens
- Encryption or certificate configuration
- User input handling or data validation
- Access control rules or permission models
- Network exposure, firewall rules, or traffic policies
- Infrastructure definitions (IaC)
- CI/CD pipeline configuration
- Container, VM, or runtime privileges
- Dependencies or supply chain changes
- Policy enforcement or compliance rules
- Data storage, retention, or backup configuration
- Logging, audit, or observability configuration

**Circuit breaker**: 3+ consecutive failures triggers diagnostic agents (researcher-code + git-historian) and presents options to the user.

```mermaid
flowchart TD
    subgraph task_loop["Per task (×N)"]
        IMP{{"implementer"}} --> V["Validation gate"]
        V --> CC["Conformity check"]
        CC --> PTR{{"code-reviewer<br/>(per-task lightweight)"}}
        PTR -->|Critical/Important| FIX["Fix loop<br/>(fresh implementer, max 3)"]
        FIX --> PTR
        PTR -->|Approved| DC["Discovery check"]
    end
    DC --> CQ["Code quality"]
    CQ --> ST["Security triage"]
    ST --> CODREV{{"code-reviewer<br/>(final, full diff)"}}
    ST -.->|if triggers| SECREV{{"security-reviewer"}}
    CODREV --> FV["Final validation"]
```

Agents used: **implementer**, **code-reviewer**, **security-reviewer** (when applicable)

---

### `/ops-debug`

Systematic debugging: investigate, hypothesize, fix.

```
/ops-debug <description of the problem>
```

| Step                       | What happens                                                                   |
| -------------------------- | ------------------------------------------------------------------------------ |
| Investigate                | Read errors, reproduce, dispatch git-historian for recent changes              |
| Instrument                 | Add temporary logging at component boundaries (multi-component bugs only)      |
| Hypothesize                | Max 3 hypotheses with supporting evidence and disproof criteria                |
| Test                       | Confirm or refute each hypothesis with minimal tests                           |
| Fix                        | Minimal fix addressing root cause, not symptoms                                |
| Code quality + Code review | Code quality → security gate → code review (same pipeline as `/ops-implement`) |
| Discovery check            | Pause if the bug is broader than diagnosed                                     |
| Verify                     | Original failing command passes, no regressions — show proof                   |

**Circuit breaker**: 5+ failed fix attempts triggers diagnostic agents and presents options.

```mermaid
flowchart TD
    I["Investigate"] --> GH{{"git-historian"}}
    GH --> INS["Instrument"]
    INS --> H["Hypothesize"]
    H --> T["Test hypotheses"]
    T --> F["Fix"]
    F --> CQ["Code quality"]
    CQ --> ST["Security triage"]
    ST --> CODREV{{"code-reviewer"}}
    ST -.->|if triggers| SECREV{{"security-reviewer"}}
    CODREV --> DC["Discovery check"]
    DC --> V["Verify"]
```

Agents used: **git-historian**, **code-reviewer**, **security-reviewer** (when applicable), **researcher-code** (circuit breaker)

---

### `/ops-test`

Add tests to existing untested code.

```
/ops-test <files or modules to test>
```

| Step         | What happens                                                                                |
| ------------ | ------------------------------------------------------------------------------------------- |
| Scope        | Identify what to test, measure current coverage if possible                                 |
| Research     | 2 agents in parallel: researcher-code (code analysis), researcher-doc (test framework docs) |
| Test-writer  | Dispatch test-writer agent: analyze behavior, identify edge cases, write tests              |
| Validate     | Run full test suite — new + existing tests must pass                                        |
| Code quality | Format, lint, structural analysis (`ops-code-quality`, qlty or project tools)               |
| Code review  | Light review focused on test quality (1 cycle max)                                          |

```mermaid
flowchart TD
    S["Scope"] --> R{{"researcher-code + researcher-doc"}}
    R --> TW{{"test-writer"}}
    TW --> V["Validate"]
    V --> CQ["Code quality"]
    CQ --> CODREV{{"code-reviewer"}}
```

Agents used: **researcher-code**, **researcher-doc**, **test-writer**, **code-reviewer**

---

### `/ops-refactor`

Restructure code without changing behavior.

```
/ops-refactor <what to refactor and why>
```

| Step          | What happens                                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------------ |
| Scope         | Clarify target and goal — what's wrong, what "better" looks like                                       |
| Research      | 2 agents in parallel: researcher-code (map dependencies, risks), researcher-doc (refactoring patterns) |
| Coverage gate | **Hard gate** — verify tests exist before touching code. Low coverage → suggest `/ops-test` first      |
| Plan steps    | Break into small, independently verifiable transformations                                             |
| Execute       | One step at a time, run tests after each step                                                          |
| Verify        | Full test suite passes, behavior unchanged                                                             |
| Code quality  | Format, lint, structural analysis (`ops-code-quality`, qlty or project tools)                          |
| Code review   | Review focused on behavior preservation (1 cycle max)                                                  |

```mermaid
flowchart TD
    S["Scope"] --> R{{"researcher-code + researcher-doc"}}
    R --> CG["Coverage gate"]
    CG --> P["Plan steps"]
    P --> E["Execute + test each step"]
    E --> V["Verify"]
    V --> CQ["Code quality"]
    CQ --> CODREV{{"code-reviewer"}}
```

Agents used: **researcher-code**, **researcher-doc**, **code-reviewer**

---

### `/ops-perf`

Performance investigation and optimization.

```
/ops-perf <what's slow and target performance>
```

| Step         | What happens                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------------- |
| Define       | What's slow, how slow, what's the target                                                          |
| Baseline     | Measure current performance (3+ runs, median). **No baseline = no optimization**                  |
| Research     | 2 agents in parallel: researcher-code (profile hot paths), researcher-doc (optimization patterns) |
| Hypothesize  | Identify bottleneck with evidence, propose optimization                                           |
| Optimize     | One change at a time, preserve correctness                                                        |
| Measure      | Re-measure with same method — show before/after delta. No improvement → revert                    |
| Verify       | Full test suite passes, behavior unchanged                                                        |
| Code quality | Format, lint, structural analysis (`ops-code-quality`, qlty or project tools)                     |
| Code review  | Review focused on correctness preservation and optimization soundness (1 cycle max)               |

```mermaid
flowchart TD
    D["Define"] --> BL["Baseline"]
    BL --> R{{"researcher-code + researcher-doc"}}
    R --> H["Hypothesize"]
    H --> O["Optimize"]
    O --> M["Measure"]
    M --> V["Verify"]
    V --> CQ["Code quality"]
    CQ --> CODREV{{"code-reviewer"}}
```

Agents used: **researcher-code**, **researcher-doc**, **code-reviewer**

---

### `/ops-review-pr`

Review an external pull request.

```
/ops-review-pr <PR number or URL>
```

| Step          | What happens                                                                |
| ------------- | --------------------------------------------------------------------------- |
| Load PR       | Fetch diff, description, related issues via `gh`                            |
| Context       | Read project conventions, scan affected area                                |
| PR reviewer   | Dispatch pr-reviewer agent: quality, conventions, logic, tests              |
| Security gate | Triage diff against security triggers, dispatch security-reviewer if needed |
| Present       | Structured review (Critical / Important / Nits). Offer to post on PR        |

```mermaid
flowchart TD
    L["Load PR"] --> C["Context"]
    C --> PR{{"pr-reviewer"}}
    PR --> SG["Security gate"]
    SG -.->|if triggers| SECREV{{"security-reviewer"}}
    SG --> P["Present review"]
```

Agents used: **pr-reviewer**, **security-reviewer** (if triggers)

---

### `/ops-research`

Autonomous codebase and documentation exploration.

```
/ops-research <topic or question>
```

Dispatches 3 agents in parallel (researcher-code, researcher-doc, git-historian), synthesizes findings, and conditionally dispatches researcher-repo when confidence is insufficient. Read-only — no changes made.

```mermaid
flowchart TD
    D["Dispatch"] --> RC{{"researcher-code"}} & RD{{"researcher-doc"}} & GH{{"git-historian"}}
    RC & RD & GH --> S["Synthesize"]
    S -.->|confidence insufficient| RR{{"researcher-repo"}}
    S --> R["Results"]
```

---

### `/ops-clone-analyze`

Clone and analyze an external repository.

```
/ops-clone-analyze <library, framework, or tool to analyze>
```

Clones the repository (version-matched when possible), analyzes it, and presents structured findings. Use when documentation is insufficient or you need to understand internals.

```mermaid
flowchart LR
    C["Clone"] --> RR{{"researcher-repo"}} --> R["Results"]
```

Agents used: **researcher-repo**

---

### `/ops-brainstorm`

Interactive brainstorming to clarify needs before planning.

```
/ops-brainstorm <what you want to explore>
```

Socratic-style dialogue: clarity check, context exploration, scope assessment, YAGNI filter. Discussion-only — no agents dispatched, no changes made.

---

### `/ops-init`

Diagnose environment in 6 phases with stop-and-propose at each phase if issues are found.

```
/ops-init
```

| Phase | What happens                                                                  | Stop if missing |
| ----- | ----------------------------------------------------------------------------- | --------------- |
| 0     | Discovery — detect CLI, languages, package managers                           | CLI unknown     |
| 1     | Recap — skills loaded, agents registered, MCP servers                         | MCP missing     |
| 2     | Ops tools — qlty + semgrep (strongly recommended for review pipeline)         | Yes             |
| 3     | Project linters — detect from configs (eslint, ruff, etc.), verify installed  | Yes             |
| 4     | Linter prerequisites — node_modules, venv, type stubs, plugins                | Yes             |
| 5     | Build tools — compilers, transpilers, build systems                           | Yes             |
| 6     | LSP — CLI-specific diagnostic (Claude Code: 4-level, OpenCode: binary+config) | Yes             |

```mermaid
graph TD
    D["Phase 0: Discovery"] --> R["Phase 1: Recap"]
    R --> OT["Phase 2: Ops tools (qlty, semgrep)"]
    OT --> PL["Phase 3: Project linters"]
    PL --> PR["Phase 4: Linter prerequisites"]
    PR --> BT["Phase 5: Build tools"]
    BT --> LSP["Phase 6: LSP"]
    LSP --> S["Final Summary"]
    OT -.->|missing| FIX["Stop & propose A/B/C"]
    PL -.->|missing| FIX
    PR -.->|missing| FIX
    BT -.->|missing| FIX
    LSP -.->|missing| FIX
```

---

### `/ops-security`

On-demand security review of code, infrastructure, or pipeline changes.

```
/ops-security                     # staged + unstaged changes
/ops-security path/to/file        # specific file or directory
/ops-security --branch            # current branch vs. base branch
/ops-security --commit <ref>      # specific commit
```

| Step           | What happens                                                   |
| -------------- | -------------------------------------------------------------- |
| Scope          | Determine what to review based on arguments                    |
| Triage         | Identify which security domains are touched                    |
| Review         | Dispatch security-reviewer with scoped diff and context        |
| Report         | Present findings with attack scenarios and fix recommendations |
| Fix (optional) | Apply fixes if requested, re-verify with security-reviewer     |

If no security-sensitive areas are found, reports that and offers to run anyway.

```mermaid
flowchart TD
    S["Scope"] --> T["Triage"]
    T --> SAST["SAST scan (semgrep)"]
    SAST --> SECREV{{"security-reviewer"}}
    SECREV --> R["Report"]
    R -.->|if requested| F["Fix + re-verify"]
    F -.-> SECREV
```

Agents used: **security-reviewer**

---

### `/ops-audit`

Full codebase audit — code quality and security analysis with unified cross-triage.

```
/ops-audit
```

| Step         | What happens                                                              |
| ------------ | ------------------------------------------------------------------------- |
| Detect tools | Check qlty and semgrep availability                                       |
| Code quality | `qlty check --all`, `qlty smells --all`, `qlty metrics --all --functions` |
| Security     | `semgrep scan --config <auto-detected> --json .` (full codebase)          |
| Cross-triage | Deduplicate, correlate complexity+vulnerabilities, classify by severity   |
| Report       | Structured report: Critical/High (detail), Medium (top 10), Low (count)   |

Unlike `/ops-security` (diff-only), this scans the **entire codebase**.

```mermaid
flowchart TD
    D["Detect tools"] --> Q["qlty (lint + smells + metrics)"]
    D --> S["semgrep (full scan)"]
    Q --> T["Cross-triage"]
    S --> T
    T --> R["Report"]
```

---

### `/ops-review`

Evaluate code review feedback technically before acting.

```
/ops-review
```

Use when you receive feedback from a human reviewer, CI check, or code-reviewer agent.

| Feedback type                      | Response                                                      |
| ---------------------------------- | ------------------------------------------------------------- |
| Factual ("bug on line 42")         | Reproduce, confirm or refute with evidence                    |
| Style ("use X pattern")            | Check project conventions first, then evaluate on merit       |
| Architectural ("restructure this") | Evaluate against spec, discuss before changing                |
| Security ("vulnerable to X")       | Always take seriously, verify attack vector, fix if confirmed |

Rules: no performative agreement, no silent ignoring, no unverified changes. Push back with evidence when feedback is incorrect.

---

### `/ops-ship`

Commit, PR, and capture learnings.

```
/ops-ship
```

| Step          | What happens                                                   |
| ------------- | -------------------------------------------------------------- |
| Verify        | Run all validation commands, linters, tests                    |
| Summarize     | Files modified/created, what was done, deviations from plan    |
| Commit        | Stage specific files, propose message, wait for approval       |
| PR (optional) | Push and create PR if requested                                |
| Learnings     | Problems solved, decisions made, gotchas, patterns that worked |

Rules: never commit secrets, never push without approval, never skip validation.

---

### `/ops-verify`

Evidence before claims. Always active — not a workflow, a behavioral rule.

This skill is **always on** across all other skills and outside of ops. It enforces one rule: **never claim a result without showing the evidence.**

| Claim              | Required evidence                       |
| ------------------ | --------------------------------------- |
| "Tests pass"       | Test command output showing 0 failures  |
| "Build succeeds"   | Build command output with exit code 0   |
| "No lint errors"   | Linter output showing 0 warnings/errors |
| "Fix works"        | Original failing command now succeeds   |
| "Deploy succeeded" | Status command showing healthy state    |

Red flags: "should", "probably", "seems to", "I believe" — if these appear instead of command output, the claim is unverified.

## Design Principles

- **Evidence before claims** — `verify` is always active. No "it should work".
- **Parallel research** — 3 agents run simultaneously during planning, with conditional repository cloning when confidence is insufficient.
- **Adversarial review** — the critic agent tries to break your plan before you build it.
- **Circuit breakers** — repeated failures escalate to diagnostics, not infinite retries.
- **Instruction priority** — user > project instructions > ops > system defaults. Conflicts resolved explicitly.
- **TDD enforced** — the implementer follows Red-Green-Refactor with anti-rationalization gates and a deletion rule for code written before tests.
- **Minimal hooks** — one SessionStart hook injects skill awareness. No keyword detection, no prompt interception, no hidden automation.
- **Composable phases** — shared content extracted into reusable internal phases. Skills reference phases instead of duplicating content.
- **Lightweight** — documentation, a small brainstorm server, and a shell script for SAST scanning. No npm deps, no database, no compiled code.

## Structure

```
ops/
├── .claude-plugin/
│   ├── marketplace.json               # Marketplace registry entry
│   └── plugin.json                    # Plugin manifest
├── agents/                            # 11 specialized agents
│   ├── code-reviewer.md
│   ├── critic.md
│   ├── git-historian.md
│   ├── implementer.md
│   ├── pr-reviewer.md
│   ├── researcher-code.md
│   ├── researcher-doc.md
│   ├── researcher-repo.md
│   ├── security-reviewer.md
│   ├── spec-reviewer.md
│   └── test-writer.md
├── hooks/
│   ├── hooks.json                     # SessionStart hook config
│   └── session-start                  # Injects skill routing context + plugin root path
├── scripts/
│   ├── ops-detect-cli.sh              # CLI detection (Claude Code / OpenCode / unknown)
│   └── ops-semgrep-scan.sh            # SAST scan wrapper (config, baseline, error handling)
├── skills/
│   │
│   │── # ─── PIPELINES (user-facing) ───
│   ├── plan/SKILL.md                  # Brainstorm → research → design → spec → plan → critic
│   ├── implement/SKILL.md             # Load plan → execute tasks → review
│   ├── do/SKILL.md                    # Lightweight: research → execute → verify → review
│   ├── debug/SKILL.md                 # Investigate → hypothesize → fix → verify
│   ├── ship/SKILL.md                  # Verify → commit → PR → learnings
│   ├── full/SKILL.md                  # Meta: plan → implement → ship
│   ├── test/SKILL.md                  # Analyze code → write tests → validate
│   ├── refactor/SKILL.md             # Coverage gate → incremental changes → verify
│   ├── perf/SKILL.md                 # Baseline → profile → optimize → measure
│   ├── review-pr/SKILL.md            # Load PR → analyze → review → security gate
│   │
│   │── # ─── STANDALONE (user-facing) ───
│   ├── research/SKILL.md              # 3 agents in parallel (codebase, docs, git) + conditional repo clone
│   ├── brainstorm/SKILL.md            # Socratic brainstorming
│   ├── clone-analyze/SKILL.md         # Clone and analyze external repos
│   ├── review/SKILL.md                # Evaluate feedback technically
│   ├── security/SKILL.md              # On-demand security review
│   ├── audit/SKILL.md                 # Full codebase audit (qlty + semgrep)
│   ├── init/SKILL.md                  # 6-phase environment diagnostic + tool setup
│   ├── verify/SKILL.md                # Evidence before claims (behavioral)
│   │
│   │── # ─── INTERNAL PHASES (user-invocable: false) ───
│   ├── instruction-priority/SKILL.md  # Instruction hierarchy when conflicts arise
│   ├── subagent-rules/SKILL.md        # Agent dispatch rules
│   ├── code-quality/SKILL.md          # Format, lint, structural analysis (qlty or project tools) before review
│   ├── discovery-checks/SKILL.md      # Minor/Significant/Major
│   ├── circuit-breaker/SKILL.md       # Repeated failure diagnostic
│   ├── security-gate/SKILL.md         # Triage + SAST (semgrep, diff-aware) + qlty security + dispatch + re-verification loop
│   ├── review-pipeline/SKILL.md       # Build verification → code quality → security gate → code review
│   ├── redispatch-optimization/SKILL.md # Re-dispatch prompt optimization
│   │
│   │── # ─── ANNEXES ───
│   ├── implement/tdd-reference.md
│   ├── implement/testing-anti-patterns.md
│   ├── plan/visual-companion.md
│   └── plan/scripts/                  # Visual brainstorm companion (server + UI)
│
├── CHANGELOG.md
├── LICENSE
└── mise.toml
```

## License

MIT — Ghislain LE MEUR. Incorporates code from [superpowers](https://github.com/obra/superpowers) (Jesse Vincent, MIT).
