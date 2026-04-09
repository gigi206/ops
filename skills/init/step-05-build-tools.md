# Step 5 — Build Tools

Mark the task "Init: build tools" as `in_progress` now via `TaskUpdate`.

Detect build tools expected by the project and verify they are installed.

## Detection

Scan for project indicators:

| Indicator | Expected tool | Check |
|---|---|---|
| `tsconfig.json` | `tsc` (TypeScript compiler) | `which tsc` |
| `babel.config.*` / `.babelrc` | `babel` | `which babel` or in node_modules |
| `webpack.config.*` | `webpack` | in node_modules |
| `vite.config.*` | `vite` | in node_modules |
| `Makefile` | `make` | `which make` |
| `CMakeLists.txt` | `cmake` | `which cmake` |
| `Cargo.toml` | `cargo` | `which cargo` |
| `go.mod` | `go` | `which go` |
| `build.gradle*` | `gradle` / `./gradlew` | `which gradle` or `./gradlew` |
| `pom.xml` | `mvn` | `which mvn` |
| `Dockerfile` | `docker` | `which docker` |
| `docker-compose.*` | `docker compose` | `which docker` |

## Stop-and-propose

If any expected build tool is missing:

```
## Build Tools
| Tool | Expected by | Installed | Fix |
|---|---|---|---|
| tsc | tsconfig.json | ✗ | npm install -g typescript |
| make | Makefile | ✓ | — |
```

> **A)** Install all missing tools
> **B)** I'll handle it myself
> **C)** Skip

Wait for the user's decision.

---

## ✅ End of Step 5

Before proceeding, verify:
- [ ] You scanned the project for build tool indicators from the detection table.
- [ ] For each detected indicator, you checked whether the expected tool is installed.
- [ ] If any expected build tool is missing: you presented the `## Build Tools` table and the A/B/C options, and got the user's decision.

Mark the task "Init: build tools" as `completed` via `TaskUpdate`.

**→ Next: read `skills/init/step-06-lsp.md` now and execute Step 6.**

Do NOT continue without reading that file first.
