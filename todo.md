# rossflow — Todo & Audit
_Last updated: 2026-05-08_

---

## File Inventory

### Skills (`workflow/skills/`)

| File | Status | Description |
|------|--------|-------------|
| `workflow-init/SKILL.md` | ✅ Complete | 9-step project scaffolding: creates dirs, places templates, wires CLAUDE.md, hands off to project-init-new |
| `project-init-new/SKILL.md` | ✅ Complete | 8-phase structured interview: discovers stack/architecture, populates all config files, generates spec-000 |
| `spec-create/SKILL.md` | ✅ Complete | Generates spec files with outline approval gate, validation, branch checkout, writes for-humans summary |
| `spec-implement/SKILL.md` | ✅ Complete | Implements a spec: branch check, plan, implement with typecheck/lint cycles, smoke test + context update |
| `spec-smoke-test/SKILL.md` | ✅ Complete | Runs HTTP/DB/UI smoke steps, files bug reports, captures logs and screenshots on failure |
| `bug-fix/SKILL.md` | ✅ Complete | Severity-ordered bug fixing (🔴→🟡→🟢), max 3 attempts, escalates contract-breaking bugs |
| `spec-smoke-and-fix/SKILL.md` | ✅ Complete | Automated loop: smoke → spawn fix subagents → repeat up to 3 cycles |
| `context-sync/SKILL.md` | ✅ Complete | Processes context-update-*.md files into ARCHITECTURE.md, ctx files, DECISIONS.md |
| `ship/SKILL.md` | ✅ Complete | Conventional commit, push, PR creation via [pr_tool] |

---

### Templates (`workflow/templates/`)

| File | Status | Description | Used by |
|------|--------|-------------|---------|
| `spec-template.md` | ✅ Complete | Spec file structure: Goal, Contracts, Behaviour, Failure paths, Files, Tests, Done when | spec-create, spec-implement |
| `smoke-test-template.md` | ✅ Complete | Smoke test structure: environment, prerequisites, HTTP/DB/UI steps | spec-implement |
| `bug-template.md` | ✅ Complete | Bug report: severity, expected vs actual, request/response, logs, DB snapshot, reproduction | spec-smoke-test, bug-fix |
| `ctx-template.md` | ❌ Stub | Single-line TODO — context file template for docs/ctx/*.md | Not yet used |
| `decisions-template.md` | ❌ Stub | Single-line TODO — DECISIONS.md entry template | Not yet used |
| `dev-plan-template.md` | ❌ Stub | Single-line TODO — purpose unclear | Not yet used |
| `pr-description-template.md` | ❌ Stub | Single-line TODO — PR description template used by ship? | ship (unconfirmed) |
| `scenario-template.md` | ❌ Stub | Single-line TODO — purpose unclear | Not yet used |
| `test-cases-template.md` | ❌ Stub | Single-line TODO — purpose unclear | Not yet used |

---

### Docs templates (`workflow/docs-templates/`)

| File | Status | Description |
|------|--------|-------------|
| `ARCHITECTURE.md` | ✅ Correct shell | Empty structure (Overview, Modules, Data Flows, External Integrations, Key Constraints) — filled by project-init-new |
| `DECISIONS.md` | ✅ Correct shell | Append-only table with header — filled as decisions are made |
| `MAP.md` | ✅ Correct shell | Component → ctx file table — should be filled by context-sync (see bug below) |
| `PATTERNS.md` | ✅ Correct shell | Stub with note — patterns index updated by project-init-new |
| `PROGRESS.md` | ✅ Correct shell | Spec tracker table — updated by spec-create |

---

### Config templates (`workflow/config-templates/`)

| File | Status | Description |
|------|--------|-------------|
| `workflow-config.md` | ✅ Complete | All keys documented: project_name, stack, commands, dirs, patterns_include |
| `workflow-infra.md` | ✅ Complete | Orchestrator, services, ports, DB type/URL/tools |
| `workflow-git.md` | ✅ Complete | Branch prefix, main branch, commit scopes, PR tool |
| `workflow-smoke.md` | ✅ Complete | UI driver, script lang/ext, tmp prefix, log tail counts |

---

### Patterns library (`workflow/patterns/`)

| File | Status | Description |
|------|--------|-------------|
| `PATTERNS.md` | ✅ Complete | Index: always-load (principles, arch) + load-when-relevant (6 tech files) |
| `principles.md` | ✅ Complete | 10 patterns + 4 anti-patterns: function size, params, early return, naming, pure functions, DRY, YAGNI, comments, SRP, cyclomatic complexity |
| `arch.md` | ✅ Complete | 8 patterns + 4 anti-patterns: 3-layer model, HTTP/DB layer, module boundaries, ports & adapters, god objects, unidirectional flow, error at boundaries |
| `fastapi.md` | ✅ Complete | 7 patterns + 4 anti-patterns: response_model, Pydantic, Depends, HTTPException, BackgroundTasks, logging, router org |
| `sqlalchemy.md` | ✅ Complete | 7 patterns + 4 anti-patterns: async session, Mapped[T], select(), transaction scope, migrations, relationship loading, session lifecycle |
| `pytest.md` | ✅ Complete | 8 patterns + 4 anti-patterns: fixture scope, asyncio_mode, parametrize, mocking, AsyncClient, conftest, assertion messages, test naming |
| `nextjs.md` | ✅ Complete | 7 patterns + 4 anti-patterns: Server/Client components, data fetching, API client, dynamic imports, error.tsx, loading.tsx, route handlers |
| `reactnative.md` | ✅ Complete | 7 patterns + 4 anti-patterns: StyleSheet, navigation types, Platform.select, API client, useEffect cleanup, native modules, FlatList |
| `django.md` | ✅ Complete | 7 patterns + 4 anti-patterns: model conventions, serializers, ViewSet/APIView, permissions, settings structure, signals, QuerySet managers |

---

### Root files

| File | Status | Description |
|------|--------|-------------|
| `install.sh` | ✅ Complete | Copies rossflow into target project, version tracking, re-run guard, skill skip logic |
| `workflow-instructions.md` | ✅ Complete | Runtime-injected workflow rules: how to find things, skill table, coding behaviour, file checklists, conditionality rules, absolute rules |
| `README.md` | ⚠️ Outdated | Still says "IN PROGRESS — extraction and generalization phase"; structure section needs update |

---

## Bugs

### 🔴 B1 — `for-humans/` directory never created
- **Problem:** `spec-create` Step 7 writes to `for-humans/specs-overview/<filename>`. Neither `workflow-init` nor `install.sh` creates this directory. Will fail on a fresh project.
- **Fix:** Add `mkdir -p for-humans/specs-overview` to `workflow-init/SKILL.md` Step 2.

### 🔴 B2 — MAP.md never updated by any skill
- **Problem:** `docs/MAP.md` is read by `spec-create`, `spec-implement`, and `bug-fix` to identify ctx files. But no skill writes to it. `context-sync/SKILL.md` says it updates ARCHITECTURE.md and ctx files but makes no mention of MAP.md. On a real project MAP.md stays empty forever, defeating its purpose.
- **Fix:** Add MAP.md update step to `context-sync`: when a new ctx file is created or a module is added, append a row to MAP.md.

### 🟡 B3 — `/workflow-init` and `/project-init-new` absent from skill table in `workflow-instructions.md`
- **Problem:** The skill invocation table only lists the 7 repeating dev-cycle skills. A developer opening a new project has no discoverable entry point documented in the injected instructions.
- **Fix:** Add a "Getting started" section (or a top row in the table) for `/workflow-init` and `/project-init-new`.

---

## Todo

### High priority

| # | Item | File(s) to change | Notes |
|---|------|--------------------|-------|
| T1 | Fix `for-humans/` directory creation | `workflow-init/SKILL.md` Step 2 | Add `mkdir -p for-humans/specs-overview` |
| T2 | Add MAP.md update to context-sync | `context-sync/SKILL.md` | When a new ctx file is created, add row to `docs/MAP.md` |
| T3 | Decide fate of 6 stub templates | `templates/ctx-template.md` etc. | Write them or delete them; they occupy space in the install |
| T4 | Add init skills to workflow-instructions.md skill table | `workflow-instructions.md` | Document `/workflow-init` and `/project-init-new` for discoverability |

### Medium priority

| # | Item | File(s) to change | Notes |
|---|------|--------------------|-------|
| T5 | Write `ctx-template.md` | `templates/ctx-template.md` | Template for `docs/ctx/ctx-<component>.md` — referenced by context-sync |
| T6 | Write `pr-description-template.md` | `templates/pr-description-template.md` | Ship skill generates PR body inline; a template would standardise the format |
| T7 | Update `README.md` | `README.md` | Remove "IN PROGRESS" status; update structure section to reflect current file layout including patterns/ and skills/ names |
| T8 | Write `decisions-template.md` | `templates/decisions-template.md` | Template for a standalone decision entry (project-init-new records decisions in DECISIONS.md) |

### Low priority / consider

| # | Item | File(s) to change | Notes |
|---|------|--------------------|-------|
| T9 | Delete unused stubs: `dev-plan-template.md`, `scenario-template.md`, `test-cases-template.md` | `templates/` | No skill references them; they add noise to the install and confuse developers |
| T10 | Add troubleshooting section to `workflow-instructions.md` | `workflow-instructions.md` | Common failure modes: missing config keys, orchestrator not running, wrong branch |
| T11 | `install.sh` — add `for-humans/specs-overview/` to the installed directory listing | `install.sh` or `workflow-init` | `install.sh` currently only creates `.claude/`; runtime dirs created by `workflow-init` |
| T12 | Consider writing a `CONTRIBUTING.md` or extending README for how to add new skills/patterns | `README.md` or new file | Useful once rossflow is open-sourced or shared |

---

## Summary

| Category | Total | ✅ Done | ⚠️ Needs work | ❌ Stub/missing |
|----------|-------|---------|----------------|-----------------|
| Skills | 9 | 9 | 0 | 0 |
| Templates | 9 | 3 | 0 | 6 |
| Docs templates | 5 | 5 | 0 | 0 |
| Config templates | 4 | 4 | 0 | 0 |
| Pattern files | 9 | 9 | 0 | 0 |
| Root files | 3 | 2 | 1 | 0 |
| **Total** | **39** | **32** | **1** | **6** |

**Core workflow: 100% complete.** Skills, config templates, docs templates, and patterns are all done.
**Bugs: 2 critical** (for-humans/ never created, MAP.md never written). Fix these before first real project use.
**Stubs: 6 templates** need a decision — write them or delete them.
