---
name: ops-perf
description: "Performance investigation and optimization. Profile, benchmark, identify bottlenecks, optimize with measured evidence."
---

# /ops-perf — Performance investigation

## Instruction Priority

Follow the `ops-instruction-priority` rules when instructions conflict.

## Subagent Rules

Before dispatching any agent in this skill, follow the `ops-subagent-rules` process.

## Purpose

Investigate and fix performance problems. This is NOT a bug (`/ops-debug`) — the code works, it's just slow. Every claim must be backed by measurements: baseline before, result after, delta quantified.

---

## Workflow

```
1. Define problem → 2. Establish baseline → 3. Research → 4. Hypothesize → 5. Optimize → 6. Measure → 7. Verify → 8. Review Pipeline
```

---

## Step 1: Define the Problem

Clarify what's slow and what "fast enough" means:
- **What** is slow? (specific endpoint, page load, build time, query, function)
- **How** slow is it? (current measurement if available)
- **What's the target?** (acceptable latency, throughput, time)
- **Where** does it run? (local, CI, production, specific hardware constraints)

If the user doesn't have measurements, that's fine — Step 2 will establish them. But get the target if possible.

---

## Step 2: Establish Baseline

**Before changing anything**, measure the current performance. Without a baseline, you can't prove improvement.

Depending on the problem:

| Type | How to measure |
|------|---------------|
| **Endpoint/API** | `time curl`, `ab`, `wrk`, `hey`, or language-specific benchmarks |
| **Function/method** | Microbenchmark (e.g., `pytest-benchmark`, `go test -bench`, `criterion` for Rust, `Benchmark.js`) |
| **Build time** | `time make`, `time npm run build`, etc. |
| **Query** | `EXPLAIN ANALYZE`, query profiler, timing logs |
| **Page load** | Lighthouse, DevTools Performance tab, Core Web Vitals |
| **Memory** | Heap profiling, memory snapshots, RSS tracking |

Record the baseline with exact numbers:
```
## Baseline
- Metric: [what you measured]
- Value: [number with units]
- Method: [how you measured it]
- Conditions: [hardware, data size, concurrency]
```

**Run the measurement 3+ times** to ensure stability. Report median, not best-case.

---

## Step 3: Research (2 agents in parallel)

Dispatch two agents **in parallel** — both Agent tool_use blocks in a **single message** (see `ops-subagent-rules`):

### researcher-code
- Profile the target code: trace the hot path, identify where time is spent
- Map the dependency chain: what calls what, where are the I/O boundaries
- Look for known anti-patterns: N+1 queries, unbounded loops, missing caching, synchronous I/O in async contexts, excessive allocations
- Check if similar code elsewhere in the project solved the same problem differently

### researcher-doc
- Query Context7 MCP for performance optimization patterns for the specific framework/library
- Focus: caching strategies, query optimization, async patterns, profiling tools available

**Wait for both agents to return before proceeding.**

---

## Step 4: Hypothesize

Based on research, identify the most likely bottleneck(s). Present to the user:

> "Based on profiling, the bottleneck is [description]:
> - [Evidence: where time is spent, what the profiler shows]
> - [Proposed optimization: what to change and expected impact]
> - [Risk: what could break, what tradeoffs are involved]
>
> Want me to proceed, or investigate further?"

**Do NOT optimize without a hypothesis.** Random changes are not optimization — they're guessing.

---

## Step 5: Optimize

Implement the optimization:
- **One change at a time.** Do not combine multiple optimizations — you need to measure the impact of each.
- **Preserve correctness.** Run tests after each change to verify behavior is unchanged.
- **Keep the old code.** If the optimization is significant, consider keeping the old implementation commented or behind a flag until measured. (Only if the user agrees — don't impose this.)

---

## Step 6: Measure

**After each optimization**, re-measure using the exact same method as the baseline:
- Same conditions (data size, concurrency, hardware)
- Same measurement tool
- 3+ runs, report median

Present the comparison:
```
## Result
- Baseline: [original value]
- After optimization: [new value]
- Improvement: [delta, percentage]
- Method: [same as baseline]
```

**If no measurable improvement** → revert the change. An optimization that doesn't improve anything is just complexity.

**If regression** → revert immediately. Explain what happened.

**If improvement** → proceed to next optimization or to Step 7 if the target is met.

---

## Step 7: Verify

1. Run the full test suite — all tests must pass
2. Confirm the optimization didn't change behavior
3. Present final before/after comparison with all optimizations applied
4. `/ops-verify` behavioral rule applies — show the numbers

---

## Step 8: Review Pipeline

Run the `ops-review-pipeline` process with the following code-reviewer context:
- The performance problem description and baseline measurements
- The optimization hypothesis and measured results
- Explicit instruction: **verify correctness is preserved** and the optimization is sound (not a micro-optimization that hurts readability for negligible gain)
