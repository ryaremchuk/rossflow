---
name: tools-bootstrap
description: Check, install, and set up all tools required by the project's tech stack. Idempotent — safe to re-run anytime.
---

## Config

Read all four files before executing. All tool names, paths, and commands come from these files.

- `.claude/workflow-config.md`
- `.claude/workflow-infra.md`
- `.claude/workflow-smoke.md`
- `.claude/workflow-git.md`

---

Verify, install, and set up every tool the project needs. Two separate gates: system installs first, project setup second.

Optional argument: `--tier1-only` — check and install Tier 1 blocking tools only. Skip DB clients, test drivers, and optional tools.

---

## Step 0 — Derive tool surface

From config values, build the tool surface (what this project needs):

**Tier 1 — Blocking** (project cannot start without these)

| Tool | Condition | Check command |
|------|-----------|---------------|
| `git` | always | `git --version` |
| `gh` | `[pr_tool]` = `gh` | `gh --version` |
| node runtime | `[backend_lang]` = `node` OR `[frontend_lang]` != `none` | `node --version` |
| python runtime | `[backend_lang]` = `python` | `python3 --version` |
| go runtime | `[backend_lang]` = `go` | `go version` |
| rust toolchain | `[backend_lang]` = `rust` | `rustc --version` |
| `[package_manager]` | always (e.g. `uv`, `npm`, `yarn`, `cargo`, `go`) | `[package_manager] --version` |
| `docker` | `[orchestrator]` = `docker-compose` | `docker --version` |
| `docker-compose` / `docker compose` | `[orchestrator]` = `docker-compose` | `docker compose version` |

**Tier 2 — Test** (smoke tests will fail without these)

| Tool | Condition | Check command |
|------|-----------|---------------|
| `[db_query_tool]` (psql / mysql / sqlite3 / mongosh) | `[db_type]` != `none` | `[db_query_tool] --version` |
| `[db_migration_tool]` (alembic / prisma / flyway / liquibase) | `[db_migration_tool]` != `none` | varies — see below |
| `[ui_driver]` (playwright / cypress / maestro) | `[ui_driver]` != `none` | varies — see below |

Migration tool checks:
- `alembic` → `alembic --version`
- `prisma` → `npx prisma --version`
- `flyway` → `flyway -version`
- `liquibase` → `liquibase --version`

UI driver checks:
- `playwright` → `npx playwright --version`
- `cypress` → `npx cypress --version`
- `maestro` → `maestro --version`

**Tier 3 — Optional** (degrade gracefully if absent)

| Tool | Condition | Check command |
|------|-----------|---------------|
| SAST tool from `[sast_cmd]` | `[sast_cmd]` != `none` | extract binary name, run `<binary> --version` |
| `ast-grep` | always | `ast-grep --version` |

---

## Step 1 — Check each tool

For each tool in the surface, run its check command. Record:
- ✅ present — capture version string
- ❌ missing — `which` returned nothing or command failed
- ⚠️ version drift — only if `.rossflow/tools-status.md` exists and version differs from recorded value

Load `.rossflow/tools-status.md` if it exists and compare current versions against recorded ones.

---

## Step 2 — Report status

Print grouped by tier:

```
── Tier 1 — Blocking ──────────────────────────────────
  ✅  git              2.49.0
  ✅  node             22.11.0
  ❌  docker           not found
  ❌  docker-compose   not found

── Tier 2 — Test ──────────────────────────────────────
  ❌  psql             not found
  ✅  playwright       1.44.0

── Tier 3 — Optional ──────────────────────────────────
  ✅  semgrep          1.72.0
  ❌  ast-grep         not found
```

If all tools are present and no version drift detected:

```
✅ All tools ready. Nothing to install.
```

Write/update `.rossflow/tools-status.md` and stop.

---

## Step 3 — Install gate 👤 STOP

Show what will be installed with the exact platform-specific commands.

Detect platform: `uname -s`
- `Darwin` → use `brew install <package>`
- `Linux` → detect distro via `/etc/os-release` → use `apt-get install -y <package>` or `yum install -y <package>`

Brew package mapping:
- docker → `brew install --cask docker`
- psql (PostgreSQL client only) → `brew install libpq`
- mysql client → `brew install mysql-client`
- mongosh → `brew install mongosh`
- gh → `brew install gh`
- ast-grep → `brew install ast-grep`
- playwright → installed via npm (not brew)
- maestro → `curl -Ls "https://get.maestro.mobile.dev" | bash`

If any Tier 1 tools are missing, print:

```
⚠️  Blocking tools missing. The project cannot start until these are installed.
```

Gate options: `all` / `tier1-only` / `select <comma-separated list>` / `skip`

⛔ STOP. Wait for explicit choice before installing anything.

---

## Step 4 — Install (system-level)

Install only the tools approved in Step 3. Run installs sequentially — some tools depend on others (e.g., docker must precede docker-compose if both are missing).

For each tool: print the command, run it, capture exit code and output.

On failure: print the output, mark the tool as ❌ failed, continue with the rest. Do not abort.

---

## Step 5 — Setup gate 👤 STOP

Project-level setup is separate from system install. Setup modifies project state: it creates databases, pulls Docker images, runs migrations, and installs browser binaries. Show exactly what will run:

Build the setup list from config:

| Action | Condition | Command |
|--------|-----------|---------|
| Pull Docker images | `[orchestrator]` = `docker-compose` | `docker compose pull` |
| Create dev database | `[db_type]` != `none` AND `[db_query_tool]` present | e.g. `createdb [project_name]` / `mysql -e "CREATE DATABASE IF NOT EXISTS [project_name]"` |
| Run migrations | `[db_migration_tool]` != `none` | e.g. `alembic upgrade head` / `npx prisma migrate dev` |
| Install playwright browsers | `[ui_driver]` = `playwright` | `npx playwright install chromium` |
| Install cypress | `[ui_driver]` = `cypress` | `npx cypress install` |

Only show actions that are relevant to this project's config. Skip items where the precondition is false.

If no setup actions apply, print `No project setup required.` and proceed to Step 7.

Gate options: `all` / `select <comma-separated list>` / `skip`

⛔ STOP. Wait for explicit choice before running any setup.

---

## Step 6 — Setup (project-level)

Execute approved setup commands in order (pull → create DB → migrate → install test drivers).

For each command: print it, run it, capture exit code and output.

On failure: print the output, mark the action as ❌ failed, continue with the rest. Partial setup is better than no setup.

---

## Step 7 — Post-install verify

Re-run Step 1 checks only for tools that were installed or set up in Steps 4 and 6. Report delta:

```
── Post-install results ───────────────────────────────
  ✅  docker           27.3.1    (was: not found)
  ✅  psql             16.2      (was: not found)
  ❌  docker-compose   not found (install failed — see output above)
```

---

## Step 8 — Write status file

Write `.rossflow/tools-status.md`:

```markdown
# Tools Status

bootstrapped_at: <ISO timestamp>
platform: <darwin|linux> (<arch>)

## Tools
<tool>: <version>
...

## Setup
<action>: ✅ <date> | ❌ failed
...

## Failures
<tool or action>: <one-line reason>
...
```

On re-run: compare current versions against this file. Tools matching recorded versions are marked ✅ without reinstalling.

---

## Done

Print summary:

```
✅ tools-bootstrap complete.
   Installed:  <N tools>
   Set up:     <N actions>
   Failures:   <N> (see above)

Next: /spec-implement spec-000-[project_name]
```

If any Tier 1 tools failed to install, replace "Next" with:

```
⚠️  Blocking tools still missing. Resolve failures above before continuing.
```
