---
name: ops:discovery-checks
description: "Internal: categorize discoveries as Minor/Significant/Major during implementation or debugging. Activated when implementer or debugger reports unexpected findings."
user-invocable: false
---

# Discovery Checks

After each task completes or after a fix is applied, check if unexpected discoveries were reported — things that were unexpected, different from what the plan assumed, or newly learned.

Categorize each discovery:

## Minor discovery
*Something unexpected but doesn't affect the current work (e.g., "this file uses tabs instead of spaces", "the config file has inconsistent formatting").*

> Note it in the discovery log. Continue to the next step.

## Significant discovery
*Something that affects upcoming work but doesn't invalidate the approach (e.g., "the API returns XML, not JSON — upcoming tasks need to parse XML instead", "the same misconfiguration exists in 3 other services").*

> **PAUSE.** Present the discovery to the user with 2-3 options:

> "During [current work context], I discovered that [description]. This affects [what else].
> Options:
> A) [Concrete adaptation — specific to the situation]
> B) [Alternative approach]
> C) Something else?
> Work is paused until you decide."

Wait for user decision. Amend remaining work accordingly, then resume.

## Major discovery
*Something that invalidates the chosen approach (e.g., "the library doesn't support streaming — the entire architecture is compromised", "the root cause is architectural").*

> **STOP.** Present the discovery to the user with options:

> "During [current work context], I discovered that [description]. This fundamentally affects the approach.
> Options:
> A) [Alternative approach]
> B) [Reduced scope or band-aid fix now, plan proper fix separately]
> C) Replan from scratch with `/ops:plan` using this new information
> D) Something else?
> Work is stopped until you decide."

Wait for user decision. Depending on the choice, either amend and resume, or restart the planning cycle.

**The goal**: catch structural problems early instead of looping until the circuit breaker triggers. Implementers and debuggers MUST NOT silently work around significant or major discoveries. If the reality doesn't match the plan, the user must be informed and must decide.
