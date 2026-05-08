# rossflow — Todo & Audit
_Last updated: 2026-05-08_

---

## File Inventory

### Skills (`workflow/skills/`)

| File | Status | Description |
|------|--------|-------------|
| `workflow-init/SKILL.md` | ✅ Complete | 9-step project scaffolding: creates dirs, places templates, wires CLAUDE.md, hands off to project-init-new |
| `project-init-new/SKILL.md` | ✅ Complete | 8-phase structured interview: discovers stack/architecture, populates all config files, generates session file |
| `project-init-write/SKILL.md` | ✅ Complete | Reads session file, shows summary, requires CONFIRM, writes all project config files, docs, CLAUDE.md, spec-000 |
| `spec-create/SKILL.md` | ✅ Complete | Generates spec files with outline approval gate, validation, branch checkout |
| `spec-implement/SKILL.md` | ✅ Complete | Implements a spec: branch check, plan, implement with typecheck/lint cycles, smoke test + context update |
| `spec-smoke-test/SKILL.md` | ✅ Complete | Runs HTTP/DB/UI smoke steps, files bug reports, captures logs and screenshots on failure |
| `bug-fix/SKILL.md` | ✅ Complete | Severity-ordered bug fixing (🔴→🟡→🟢), max 3 attempts, escalates contract-breaking bugs |
| `spec-smoke-and-fix/SKILL.md` | ✅ Complete | Automated loop: smoke → spawn fix subagents → repeat up to 3 cycles |
| `context-sync/SKILL.md` | ✅ Complete | Processes context-update-*.md files into ARCHITECTURE.md, ctx files, DECISIONS.md, MAP.md |
| `ship/SKILL.md` | ✅ Complete | Conventional commit, push, PR creation via [pr_tool] |

---

### Templates (`workflow/templates/`)

| File | Status | Description | Used by |
|------|--------|-------------|---------|
| `spec-template.md` | ✅ Complete | Spec file structure: Goal, Contracts, Behaviour, Failure paths, Files, Tests, Done when | spec-create, spec-implement |
| `smoke-test-template.md` | ✅ Complete | Smoke test structure: environment, prerequisites, HTTP/DB/UI steps | spec-implement |
| `bug-template.md` | ✅ Complete | Bug report: severity, expected vs actual, request/response, logs, DB snapshot, reproduction | spec-smoke-test, bug-fix |
| `ctx-template.md` | ✅ Complete | Context file for docs/ctx/*.md: Purpose, Public interface, Internal structure, State, Dependencies, Constraints, Recent changes | context-sync |
| `decisions-template.md` | ✅ Complete | DECISIONS.md row format: DEC-NNN, title, rationale, date, supersedes | project-init-new, context-sync |
| `pr-description-template.md` | ✅ Complete | PR body: What, Why, Spec, Changes, Smoke tested, Done-when verified | ship |

---

### Docs templates (`workflow/docs-templates/`)

| File | Status | Description |
|------|--------|-------------|
| `ARCHITECTURE.md` | ✅ Correct shell | Empty structure (Overview, Modules, Data Flows, External Integrations, Key Constraints) — filled by project-init-new |
| `DECISIONS.md` | ✅ Correct shell | Append-only table with header — filled as decisions are made |
| `MAP.md` | ✅ Correct shell | Component → ctx file table — updated by context-sync when new ctx files are created |
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
| `workflow-instructions.md` | ✅ Complete | Runtime-injected workflow rules: skill table (incl. init skills), coding behaviour, file checklists, conditionality rules, absolute rules |
| `README.md` | ✅ Complete | Quickstart, skills table (10), patterns, templates, config templates, how-it-works steps |

---

## Bugs

### ✅ B2 — MAP.md never updated by any skill — FIXED
- `context-sync/SKILL.md` now appends rows to `docs/MAP.md` when new ctx files are created.

### ✅ B3 — `/workflow-init` and `/project-init-new` absent from skill table — FIXED
- `workflow-instructions.md` now has a "Getting started" section at top of skill table with both init skills and `/project-init-write`.

---

## Todo

### High priority

_All high-priority items resolved._

### Medium priority

| # | Item | File(s) to change | Notes |
|---|------|--------------------|-------|
| T10 | Add troubleshooting section to `workflow-instructions.md` | `workflow-instructions.md` | Common failure modes: missing config keys, orchestrator not running, wrong branch |

### Low priority / consider

| # | Item | File(s) to change | Notes |
|---|------|--------------------|-------|
| T12 | Write `CONTRIBUTING.md` or extend README for how to add new skills/patterns | `README.md` or new file | Useful once rossflow is open-sourced or shared |

---

## Summary

| Category | Total | ✅ Done | ⚠️ Needs work | ❌ Stub/missing |
|----------|-------|---------|----------------|-----------------|
| Skills | 10 | 10 | 0 | 0 |
| Templates | 6 | 6 | 0 | 0 |
| Docs templates | 5 | 5 | 0 | 0 |
| Config templates | 4 | 4 | 0 | 0 |
| Pattern files | 9 | 9 | 0 | 0 |
| Root files | 3 | 3 | 0 | 0 |
| **Total** | **37** | **37** | **0** | **0** |

**Core workflow: 100% complete.** All skills, templates, docs, config, and patterns done.
**Bugs: 0 open.** B2 and B3 both fixed.
**Open todos: 2** — both low priority (troubleshooting section, CONTRIBUTING.md).
