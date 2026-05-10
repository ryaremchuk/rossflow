---
name: project-init-new
description: Structured interview to discover project context, tech stack, and architecture. Writes session file on completion. Run /project-init-write to generate all project files. Invoked by workflow-init; safe to re-run standalone.
---

Conduct a structured project interview, then write a session file for /project-init-write.

⛔ No project files written during this skill. Session file only.
"Move on" at any point skips remaining questions in the current phase and advances with what has been collected.
Never ask more than 2 questions at once. Always suggest first — developer reacts, never fills blanks.

---

## Phase 0 — Read context

Read in order:
1. `.claude/workflow-config.md` — note which fields are already populated
2. `.claude/workflow-infra.md`
3. `.claude/workflow-git.md`
4. `.claude/workflow-smoke.md`
5. `docs/patterns/INDEX.md` — note available pattern file names
6. `CLAUDE.md` — check for existing project description
7. Scan project root for design-source candidates: `claude-design-source/`, `design/`, `figma-export/`, `mockups/`, `*.fig`, `*.html` at root. Set `DESIGN_SOURCE_FOUND=true|false` and record paths.

**Re-run detection:** if `docs/ARCHITECTURE.md` has content beyond the template placeholder, OR any `.claude/workflow-*.md` has filled values, this is a re-run. Output a warning listing the files with existing content, state that existing values will be shown before any overwrite, and ask `Continue? (yes / no)`. ⛔ STOP. Halt on "no".

---

## Phase 1 — Discovery

Open with exactly:

```
Let's set up your project. What are we building?
Describe it however feels natural — a sentence or ten paragraphs, whatever captures it.
```

⛔ STOP. Wait for developer response.

After response, output:
- A 3–5 bullet summary of what you understood
- Any ambiguities identified (target users, expected scale, key constraints, monetisation model)
- At most 2 clarifying questions

⛔ STOP. Wait for response or "move on".

Hold for later: project name, one-paragraph description, target users, scale expectations, key constraints.

---

## Phase 2 — Tech stack

Based on the project description, suggest a complete stack. Present as a table with a reason for each choice. For layers that don't apply, write `none — [why not needed for this project type]`.

```
Based on [one-line project summary], here's a stack I'd suggest:

| Layer                 | Suggested | Reason |
|-----------------------|-----------|--------|
| Backend language      | ...       | ...    |
| Package manager       | ...       | ...    |
| Frontend              | ...       | ...    |
| Database              | ...       | ...    |
| ORM / migrations      | ...       | ...    |
| Backend testing       | ...       | ...    |
| UI testing            | ...       | ...    |
| Infra / orchestration | ...       | ...    |
| PR tool               | ...       | ...    |

Does this stack work? Change anything you want.
```

⛔ STOP. Wait for response.

Update table based on feedback. Repeat until developer explicitly approves. On approval:

```
Stack locked. Moving to architecture.
```

Hold all values and map them to config keys.

**workflow-config.md** — `project_name` (kebab from project name), `backend_lang`, `package_manager`, `frontend_lang` (typescript | javascript | none), `test_runner`. Commands derive from chosen tools — `typecheck_cmd` (e.g. `uv run mypy {files} --strict`), `lint_cmd` (e.g. `uv run ruff check {files}`), `test_cmd` (e.g. `uv run pytest {test_dir} -v --tb=short`). `frontend_typecheck_cmd` / `frontend_lint_cmd` / `frontend_test_cmd` derive from frontend choice; `none` if no frontend. `backend_dir` from stack convention (`backend` Python, `src` Go), `frontend_dir` (`none` if no frontend), `test_dir` (e.g. `backend/tests`). Fixed: `specs_dir`=specs, `smoke_tests_dir`=smoke-tests, `bugs_dir`=bugs, `docs_dir`=docs.

**workflow-infra.md** — `type` (docker-compose | kubernetes | none); `backend_service` / `frontend_service` / `db_service` (`none` if not present); `backend_port` (8000 FastAPI, 3000 Express, …); `frontend_port` (`none` if no frontend); `db_type` (postgresql | mysql | sqlite | mongodb | none); `db_url` derived from db_type + project_name (e.g. `postgresql://localhost/[project_name]`); `db_query_tool` (psql | mysql | sqlite3 | none); `db_migration_tool` (alembic | flyway | prisma | liquibase | none).

**workflow-git.md** — `branch_prefix`=feat, `main_branch`=main, `commit_scopes` csv of layers present (e.g. `backend,frontend,infra`), `pr_tool` from PR tool choice (`none` if not applicable).

**workflow-smoke.md** — `ui_driver` (playwright | cypress | maestro | none); `ui_script_lang` derived (javascript | typescript | python | none); `ui_script_lang_ext` derived (js | ts | py | none); `tmp_script_prefix`=smoke-tests/.tmp-, `log_tail_backend`=50, `log_tail_frontend`=30.

---

## Phase 2.5 — Design source discovery

If `DESIGN_SOURCE_FOUND=true`: list the inventory at the discovered path (HTML mockups, CSS/token files, asset folders, JSX/scripts, system docs) and state the extraction targets — `DESIGN-SYSTEM.md` (tokens + asset inventory + visual rules), `COMPONENT-LIBRARY.md` (reusable component proposals), `design-source-index.json` (machine-readable per-screen index). Ask "Proceed with extraction?" ⛔ STOP. Independent approval gate. On approval, invoke `design-source-extract` with the path; then continue.

If `DESIGN_SOURCE_FOUND=false`: ask the developer to pick (a) point at folder → re-scan + extract; (b) interview-only, no visual reference; (c) provide screenshots/links later — proceed without. ⛔ STOP. Independent approval gate. For (b)/(c), mark a DEC requirement to record this in DECISIONS.md.

Hold for project-init-write: `design_source_path`, `design_source_status` (extracted | pointed | absent | deferred).

---

## Phase 3 — Architecture

Use approved stack + project description + (if extracted) DESIGN-SYSTEM.md. Walk the 13-section architecture template at `workflow/docs-templates/ARCHITECTURE.md` in order.

For each section:
1. Generate draft based on inputs.
2. Show: `What we chose / Why / Rejected / Implications / Triggers re-eval`.
3. Gate type:
   - **Hard-stop sections** (require explicit independent approval): §3 layered architecture, §4 state model, §5 navigation, §6 persistence, §10 boundaries.
   - **Auto-accept sections** (proceed unless objection): §1, §2, §7, §8, §9, §11, §12, §13.

Hard-stop output:
```
**§<N> — <Section name>**
What I chose: <draft>
Why: <reasoning>
Rejected: <list>
Implications: <list>
Triggers re-eval: <condition>

Approve, edit, or reject?
```
⛔ STOP per hard-stop section. Independent approval gate.

Auto-accept output: brief draft, pause for objection only.

On approval of all sections:
```
Architecture locked. Sections producing DECs: §<list>. Recording in Phase 6 as DEC-001..DEC-NNN.
```

Hold full architecture text (all 13 sections) — write VERBATIM in project-init-write, do not summarize.

---

## Phase 4 — Patterns selection

Automatically select pattern files based on the approved stack:
- Always include: principles, arch
- If frontend_lang == typescript or backend_lang == typescript: typescript
- If React or RN stack: state-management (always) + ask state library → exactly one of state-redux-toolkit | state-zustand
- If RN stack: + reactnative, client-persistence
- If Next.js: + nextjs (state-management already included by React rule)
- If Python+FastAPI: fastapi, pytest
- If Python+Django: django, pytest, sqlalchemy (if used)
- Else: ask

**State library question (only when React or RN is in stack):**

```
Which state library will this project use?
- redux-toolkit — Redux with RTK + RTK Query, mature, opinionated
- zustand — minimal, hooks-first, low boilerplate
- other — name it, I'll skip the library file (you'll add the recipe later)
```

⛔ STOP. Wait for response. Record choice as `state_library`. If `redux-toolkit` → add `state-redux-toolkit` to includes. If `zustand` → add `state-zustand`. If `other` → include only `state-management` and note in DECs.

**Persistence question (only when stack stores data on-device — RN, PWA, desktop):**

`client-persistence` is auto-included for RN. For other stacks, ask: "Will this project persist data on-device?" yes → add `client-persistence`.

Show:

```
Based on your stack, I'll apply these patterns:
✅ principles — always on
✅ arch — always on
✅ [file] — [one-line reason tied to stack choice]
⬜ [file] — not applicable (no [tech])
```

Ask: "Anything to add or remove?"

⛔ STOP. Wait for response. "Looks good" or no objection is sufficient to proceed.

Hold: list of selected pattern file stems (for `patterns_include` config key and for generating the project's `docs/PATTERNS.md` in `project-init-write`).

---

## Phase 5 — First spec

Output:

```
What's the first thing to build? This becomes spec-000 — the first implementation task.

It should be a thin vertical slice: something that touches all layers and proves the stack works end to end.

For this project, a natural starting point would be:
[suggest a concrete first task — e.g. "a health-check endpoint with DB connectivity test" or "user registration + login endpoints with JWT"]

Is that the right starting point, or do you have something else in mind?
```

⛔ STOP. Wait for response.

After developer approves or describes the first task, draft spec-000 using `specs/spec-template.md` exactly. Fill every section in the template — no TBD, no empty sections. Specifically:
- Contracts: signatures + types only, never bodies. Backend block uses `[backend_lang]`. Frontend block only if frontend exists.
- Failure paths: at least one per external I/O (DB, external API).
- Files: paths use `[backend_dir]` / `[frontend_dir]` placeholders.
- Tests: names in `test_[unit]_[scenario]_[expected]` format.
- Done when: checklist using `[typecheck_cmd]` / `[lint_cmd]` / `[test_cmd]` placeholders.

Present the full draft.

Ask: "Does this spec capture what you want to build first?"

⛔ STOP. Wait for response. Refine until approved.

Hold: spec filename as `spec-000-[short-name]` (lowercase kebab, max 3 words after `000`).

---

## Phase 6 — Gap check

Review all collected information.

**Config completeness:** list any config fields still unresolved. For each, propose a sensible default:

```
A few values still need defaults:
- workflow-infra.md → backend_port — suggest 8000 (standard for [backend choice])
- workflow-git.md → commit_scopes — suggest backend,infra (no frontend in this project)
[...]
```

**Decisions to record (mandatory ≥5 entries for any non-trivial project):**

For each architectural choice surfaced in Phase 3, draft a DEC entry following the schema at `workflow/docs-templates/DECISIONS.md`.

Required DECs:
- State model (chosen pattern + rejected alternatives)
- Persistence strategy
- Navigation typing
- Design system source-of-truth (if extracted)
- Testing posture (test runner, unit-test policy; disabling unit tests REQUIRES explicit reason DEC)

Each DEC MUST include either a `Verifies` rule (machine-checkable) or `Unverifiable: true` with reason.

Show each DEC entry in full before writing.
⛔ STOP per DEC. Independent approval gate.

**Project rules (derived from stack, written into target project's CLAUDE.md by project-init-write):**

For each tech-stack-applicable pattern selected in Phase 4, derive 3–5 absolute rules. Rules are self-contained, machine-checkable where possible, and absolute (no "should" / "prefer"). Required rule sources:
- RN → reactnative.md: FlatList for >10-item lists, `useSafeAreaInsets()` not literal paddingTop, no inline `#hex` outside `src/constants/`.
- TS → principles.md: max screen file 250 LOC, max function complexity 20.
- Persistence → client-persistence.md: storage SDK calls only via typed wrappers; auth/secret values only via secure store.
- State → state-management.md: per-screen domain hook instantiation forbidden; shared state lives in the chosen library's single store.

Rendered as flat bullet list under "## Project Rules" in target CLAUDE.md.

Show rules to user. ⛔ STOP. Independent approval gate.

Ask: "Anything missing or wrong before I write everything?"

⛔ STOP. Wait for response.

---

## Write session file

After Phase 6 gap check is complete and the developer has responded, write `.claude/project-init-session.md` with the exact schema below. Fill every field from what was collected in Phases 1–6. Use empty string for fields that could not be determined.

```markdown
# project-init-new session
_Generated: [date]_
_Status: awaiting-confirm_

## Project
name: 
description: 

## Stack
backend_lang: 
package_manager: 
frontend_lang: 
frontend_typecheck_cmd: 
frontend_lint_cmd: 
frontend_test_cmd: 
test_runner: 
typecheck_cmd: 
lint_cmd: 
test_cmd: 
backend_dir: 
frontend_dir: 
test_dir: 

## Infra
orchestrator: 
backend_service: 
frontend_service: 
db_service: 
backend_port: 
frontend_port: 
db_type: 
db_url: 
db_query_tool: 
db_migration_tool: 

## Git
branch_prefix: 
main_branch: 
commit_scopes: 
pr_tool: 

## Smoke
ui_driver: 
ui_script_lang: 
ui_script_lang_ext: 
tmp_script_prefix: 
log_tail_backend: 
log_tail_frontend: 

## Patterns
patterns_include: 
state_library: <!-- redux-toolkit | zustand | other | none — when frontend has React/RN -->
client_persistence: <!-- yes | no — when project stores data on-device -->

## Design
design_source_path: 
design_source_status: extracted | pointed | absent | deferred

## Decisions
<!-- One entry per decision, DEC-NNN format -->

## Architecture
<!-- Full 13-section architecture text from Phase 3, verbatim -->

## Project rules
<!-- Bullet list of stack-derived rules from Phase 6f -->

## Spec-000
<!-- Full spec-000 content as drafted and approved in Phase 5 -->
```

After writing the session file, print:

```
Interview complete. Session saved to .claude/project-init-session.md

Review the session file if you want to make any manual adjustments.
When ready to write all project files, run: /project-init-write
```

Then stop. Do not write any project files.
