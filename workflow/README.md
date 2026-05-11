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

`install.sh` copies rossflow skills into `.claude/skills/` and asset folders into `.claude/rossflow/`. `/workflow-init` scaffolds `docs/`, `specs/`, `specs/plans/`, `specs/proposed/`, `bugs/`, `smoke-tests/`, `smoke-tests/regression/`, places config + doc templates, and wires `CLAUDE.md` to reference `workflow-instructions.md` (only — config files load on-demand). It then hands off to `/project-init-new`, which interviews you about stack, architecture, design source, and patterns, and writes a session file. `/project-init-write` reads that session, requires CONFIRM, and generates every project file (config, ARCHITECTURE.md, DECISIONS.md, PATTERNS.md, MAP.md, spec-000, project-specific CLAUDE.md rules). After that you cycle: `/spec-create` → `/spec-implement` → `/spec-smoke-and-fix` → `/decision-sync` → `/ship`. Periodically (every 5–10 specs): `/code-audit` for tech-debt visibility and `/discover-smoke-scenarios` to refresh frozen regression baselines.

## Skills

### Setup
| Skill | Purpose |
|-------|---------|
| `/workflow-init` | Scaffold directories, place templates and configs, wire CLAUDE.md, then call project-init-new. |
| `/project-init-new` | Structured interview: stack, architecture, design source, patterns, spec-000. Writes a session file only. |
| `/project-init-write` | Reads the session file and writes all project files after CONFIRM. Auto-invokes `/tools-bootstrap` at the end. |
| `/tools-bootstrap` | Check, install, and set up all tools required by the project's tech stack (git, runtimes, DB clients, test drivers, etc). Idempotent — re-run anytime the stack changes. |

### Specs
| Skill | Purpose |
|-------|---------|
| `/spec-create` | Conversational discovery → outline approval → 3-artifact write (contract spec + implementation plan + draft smoke test). Auto-runs `/decision-verify` first. Surfaces overlap with in-progress specs. |
| `/spec-implement` | Implement a spec: read context (plan + draft smoke required), re-validate plan against current state, lint/typecheck/test cycles, simplify pass, refine draft smoke into final, write context update. |
| `screen-implement` | Variant of spec-implement for `type: screen` specs. Enforces design-fidelity, reuses COMPONENT-LIBRARY entries, auto-runs ui-fidelity-check. |

### Quality
| Skill | Purpose |
|-------|---------|
| `/spec-smoke-test` | Run a spec's smoke tests (HTTP/DB/UI), file bug reports for failures, summarise. |
| `/spec-smoke-and-fix` | Orchestrate smoke-test → bug-fix loop, max 3 cycles. Spawns one `/bug-fix` subagent per bug. |
| `/smoke-all` | Run every per-spec smoke test + every frozen regression baseline. Hard-blocks `/ship` on any failure. Use after each spec impl to catch cross-spec regressions. |
| `/discover-smoke-scenarios` | Generate fresh regression scenarios for a module/spec from current source + DECs + specs. Approved scenarios are frozen as a baseline at `smoke-tests/regression/`. Re-runs produce diffs against baseline (deterministic by design). |
| `/bug-fix` | Severity-ordered bug fix with classification (runtime / ui-fidelity / architecture-violation / contract-change), max 3 attempts per bug. |
| `/code-audit` | SAST + LLM diff scan over recent changes. Aggregates findings by module, drafts refactor spec stubs at `specs/proposed/`. Run every 5–10 specs. |
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
| `/ship` | Commit all changes, push, open PR to main. Does NOT auto-invoke `/smoke-all` — run manually when you want a regression gate. |

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

### Three-artifact spec output
`/spec-create` writes three files per spec, each reviewed independently:
- `specs/spec-NNN-name.md` — **contract spec** (signatures, behavior, failure paths). Reviewed for "is the contract right?"
- `specs/plans/plan-spec-NNN-name.md` — **implementation plan** (file list, DEC alignment, reuse mapping, risks, rollback). Reviewed for "is the plan right?" Re-validated by `/spec-implement` Step 2 against current state.
- `smoke-tests/spec-NNN-name-DRAFT.md` — **pre-impl smoke test** (acceptance target while coding). Refined into final `smoke-tests/spec-NNN-name.md` by `/spec-implement` Step 5.

### Regression baseline freeze
`/discover-smoke-scenarios` produces module/spec scenario sets from current source. Approved scenarios are frozen at `smoke-tests/regression/<scope>.md` with `frozen_at_sha` frontmatter. Subsequent `/discover-smoke-scenarios` runs produce **diffs** against the frozen baseline (Stable / Modified / Added / Removed) — never a wholesale regeneration unless `--refresh` is passed. This keeps regression results deterministic and signal-rich. `/smoke-all` runs both per-spec smokes and frozen baselines.

### Conversational spec discovery
`/spec-create` Step 3 surfaces affected DECs, candidate implementation paths with tradeoffs, in-progress spec overlaps, and a 🔴 watch-list — all BEFORE drafting the outline. The user picks a direction; the outline drafts with that direction baked in. The 🔴 hard-stop bypass phrase ("ignore flag, proceed anyway, accept risk") is negotiated at discovery, not at outline.

## What's included

- **Skills (20)**: see tables above.
- **Patterns** (`patterns/`): principles, arch, typescript, reactnative, nextjs, state-management, state-redux-toolkit, state-zustand, client-persistence, fastapi, django, sqlalchemy, pytest. Plus `INDEX.md` routing index.
- **Templates** (`templates/`): spec, plan, smoke-test, smoke-test-draft, bug, decisions, pr-description, screen-spec, component-readme.
- **Doc templates** (`docs-templates/`): ARCHITECTURE, DECISIONS, MAP (generated), DESIGN-SYSTEM, COMPONENT-LIBRARY, PROGRESS.
- **Config templates** (`config-templates/`): workflow-config (now includes `sast_cmd`), workflow-infra, workflow-git, workflow-smoke. Loaded on-demand by skills, not inlined in CLAUDE.md.
