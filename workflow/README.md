# rossflow

AI development workflow package. Adds a structured, skill-based development process to any project regardless of tech stack.

## Quickstart

Install into any project:
```bash
bash install.sh /path/to/your-project
```

Then open Claude Code in your project and run:
```
/workflow-init
```

## How it works

`install.sh` copies rossflow skills into `.claude/skills/` and asset folders into `.claude/rossflow/`. `/workflow-init` scaffolds `docs/`, `specs/`, `bugs/`, `smoke-tests/`, places config + doc templates, and wires `CLAUDE.md` to reference `workflow-instructions.md` (only — config files load on-demand). It then hands off to `/project-init-new`, which interviews you about stack, architecture, design source, and patterns, and writes a session file. `/project-init-write` reads that session, requires CONFIRM, and generates every project file (config, ARCHITECTURE.md, DECISIONS.md, PATTERNS.md, MAP.md, spec-000, project-specific CLAUDE.md rules). After that you cycle: `/spec-create` → `/spec-implement` → `/spec-smoke-and-fix` → `/decision-sync` → `/ship`.

## Skills

### Setup
| Skill | Purpose |
|-------|---------|
| `/workflow-init` | Scaffold directories, place templates and configs, wire CLAUDE.md, then call project-init-new. |
| `/project-init-new` | Structured interview: stack, architecture, design source, patterns, spec-000. Writes a session file only. |
| `/project-init-write` | Reads the session file and writes all project files after CONFIRM. |

### Specs
| Skill | Purpose |
|-------|---------|
| `/spec-create` | Generate a spec with outline approval, DEC alignment check, validation, branch checkout. Auto-runs `/decision-verify` first. |
| `/spec-implement` | Implement a spec: read context, plan with architecture-fit gate, lint/typecheck/test cycles, simplify pass, write smoke test + context update. |
| `screen-implement` | Variant of spec-implement for `type: screen` specs. Enforces design-fidelity, reuses COMPONENT-LIBRARY entries, auto-runs ui-fidelity-check. |

### Quality
| Skill | Purpose |
|-------|---------|
| `/spec-smoke-test` | Run a spec's smoke tests (HTTP/DB/UI), file bug reports for failures, summarise. |
| `/spec-smoke-and-fix` | Orchestrate smoke-test → bug-fix loop, max 3 cycles. Spawns one `/bug-fix` subagent per bug. |
| `/bug-fix` | Severity-ordered bug fix with classification (runtime / ui-fidelity / architecture-violation / contract-change), max 3 attempts per bug. |
| `ui-fidelity-check` | Visual + structural diff vs design source (token audit, asset audit, label/numeric audit, screenshot diff). Files bugs on failure. |

### Sync & verify
| Skill | Purpose |
|-------|---------|
| `/decision-sync` | Merge per-spec context updates into ARCHITECTURE.md / DECISIONS.md, scaffold component READMEs, regenerate `docs/MAP.md` from per-component READMEs. |
| `/decision-verify` | Run all DEC `Verifies:` rules as machine checks. Auto-invoked by `/spec-create`; cheap when no rules exist. |
| `/doc-check` | On-demand AI semantic compare of a component's source vs its README. Proposes patches with approval gate. |
| `design-source-extract` | Parse a design-source folder into DESIGN-SYSTEM.md, COMPONENT-LIBRARY.md, design-source-index.json, design-tokens.json. Invoked by project-init-new and design-diff. |
| `/design-diff` | Compare a new design drop vs current extraction; emit delta + propose patch specs. |

### Ship
| Skill | Purpose |
|-------|---------|
| `/ship` | Commit all changes, push, open PR to main. |

## Concepts

### Decisions (DECs)
Append-only ADRs in `docs/DECISIONS.md`. Each DEC carries Status / Context / Decision / Consequences and either a machine-checkable `Verifies:` rule or `Unverifiable: true`. `/spec-create` runs `/decision-verify` first so new specs cannot build on top of violated decisions.

### Patterns library
`patterns/INDEX.md` lists all available patterns. During init, `project-init-new` Phase 4 auto-selects files matching the approved stack (always-on: principles, arch; conditional: typescript, reactnative, nextjs, fastapi, django, sqlalchemy, pytest, state-management + one of state-redux-toolkit / state-zustand, client-persistence). The chosen stems are stored in `patterns_include`; project's `docs/PATTERNS.md` is generated from that list. Skills grep this index at spec time and read only matching files — never bulk-load.

### Design system
If a design source folder is detected (`design/`, `figma-export/`, `mockups/`, `*.html` at root), `project-init-new` Phase 2.5 invokes `design-source-extract` to produce `docs/DESIGN-SYSTEM.md` (tokens + visual rules), `docs/COMPONENT-LIBRARY.md` (reusable components), and a machine-readable per-screen index. Screen specs then route to `screen-implement` and are validated by `ui-fidelity-check`.

### Auto-discovery during project-init
`project-init-new` Phase 0 reads existing `.claude/workflow-*.md` configs, `docs/patterns/INDEX.md`, `CLAUDE.md`, and scans the repo root for design sources. Re-running on a populated project is detected and gated by an explicit "Continue?" prompt before any overwrite — every overwrite of an existing file goes through its own approval gate inside `/project-init-write`.

### Component context (auto-generated)
`docs/MAP.md` is a generated index of per-component READMEs. `decision-sync` regenerates it from `find src -name README.md` on every run. Spec-implement reads MAP first, then opens any READMEs the spec touches — no manual maintenance needed.

## What's included

- **Skills (16)**: see table above.
- **Patterns** (`patterns/`): principles, arch, typescript, reactnative, nextjs, state-management, state-redux-toolkit, state-zustand, client-persistence, fastapi, django, sqlalchemy, pytest. Plus `INDEX.md` routing index.
- **Templates** (`templates/`): spec, smoke-test, bug, decisions, pr-description, screen-spec, component-readme.
- **Doc templates** (`docs-templates/`): ARCHITECTURE, DECISIONS, MAP (generated), DESIGN-SYSTEM, COMPONENT-LIBRARY, PROGRESS.
- **Config templates** (`config-templates/`): workflow-config, workflow-infra, workflow-git, workflow-smoke. Loaded on-demand by skills, not inlined in CLAUDE.md.
