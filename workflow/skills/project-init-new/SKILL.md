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
5. `docs/patterns/PATTERNS.md` — note available pattern file names
6. `CLAUDE.md` — check for existing project description

**Re-run detection:** if `docs/ARCHITECTURE.md` has content beyond the template placeholder text, this is a re-run on an existing project. Output:

```
⚠️  project-init-new has been run before on this project.

Files with existing content:
- docs/ARCHITECTURE.md
- [list any .claude/workflow-*.md files that have values filled in]

Continuing will update these files. Existing values will be shown before any overwrite.

Continue? (yes / no)
```

⛔ STOP. Wait for confirmation before proceeding. If "no" — halt.

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

Hold all values and map them to config keys:

**workflow-config.md fields:**
- `project_name` — derived from project name (lowercase-kebab)
- `backend_lang` — from backend language choice
- `package_manager` — from package manager choice
- `frontend_lang` — typescript | javascript | none
- `test_runner` — from backend testing choice
- `typecheck_cmd` — derive from backend lang (e.g. `uv run mypy {files} --strict` for Python+uv)
- `lint_cmd` — derive from backend lang (e.g. `uv run ruff check {files}`)
- `test_cmd` — derive from test runner (e.g. `uv run pytest {test_dir} -v --tb=short`)
- `frontend_typecheck_cmd` — derive from frontend choice; `none` if no frontend
- `frontend_lint_cmd` — derive from frontend choice; `none` if no frontend
- `frontend_test_cmd` — derive from frontend choice; `none` if no frontend
- `backend_dir` — derive from stack convention (e.g. `backend` for Python, `src` for Go)
- `frontend_dir` — derive from stack convention; `none` if no frontend
- `test_dir` — derive from backend_dir convention (e.g. `backend/tests`)
- `specs_dir`: specs | `smoke_tests_dir`: smoke-tests | `bugs_dir`: bugs | `docs_dir`: docs

**workflow-infra.md fields:**
- `type` — orchestrator type: docker-compose | kubernetes | none
- `backend_service` — service name in orchestrator config (e.g. `backend`); none if no orchestrator
- `frontend_service` — e.g. `frontend`; none if no frontend
- `db_service` — e.g. `postgres`; none if no orchestrator
- `backend_port` — standard port for chosen backend (e.g. 8000 for FastAPI, 3000 for Express)
- `frontend_port` — standard port for chosen frontend; none if no frontend
- `db_type` — postgresql | mysql | sqlite | mongodb | none
- `db_url` — derive from db_type and project_name (e.g. `postgresql://localhost/[project_name]`)
- `db_query_tool` — psql | mysql | sqlite3 | none
- `db_migration_tool` — alembic | flyway | prisma | liquibase | none

**workflow-git.md fields:**
- `branch_prefix`: feat
- `main_branch`: main
- `commit_scopes` — comma-separated list of layers present (e.g. `backend,frontend,infra`)
- `pr_tool` — from PR tool choice; none if not applicable

**workflow-smoke.md fields:**
- `ui_driver` — from UI testing choice: playwright | cypress | maestro | none
- `ui_script_lang` — derive from ui_driver choice: javascript | typescript | python | none
- `ui_script_lang_ext` — derive from ui_script_lang: js | ts | py | none
- `tmp_script_prefix`: smoke-tests/.tmp-
- `log_tail_backend`: 50
- `log_tail_frontend`: 30

---

## Phase 3 — Architecture

Using the approved stack and project description, propose a high-level architecture.

Present as a populated draft of `docs/ARCHITECTURE.md`:

```
## Overview
[2–3 sentences: what the system does and its primary design intent]

## Modules
[Component] — [responsibility, one line]
[Component] — [responsibility, one line]
...

## Data Flows
[Plain text description of how data moves through the system]

[ASCII or markdown diagram if it adds clarity — optional]

## External Integrations
- [Service name] — [what it provides and when it is called]

## Key Constraints
- [constraint derived from project requirements or scale]
```

Ask: "Does this match your vision? What would you change?"

⛔ STOP. Wait for response.

Refine until developer approves. On approval:

```
Architecture locked. Moving to patterns.
```

---

## Phase 4 — Patterns selection

Automatically select pattern files based on the approved stack:
- Always include: `principles`, `arch`
- Add files from `docs/patterns/PATTERNS.md` that match stack choices

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

Hold: list of selected pattern file stems (for `patterns_include` config key and for updating `docs/patterns/PATTERNS.md` index).

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

After developer approves or describes the first task, draft spec-000 using `specs/spec-template.md` exactly. Fill every section — no TBD, no empty sections:

- **Goal** — what this first slice builds and why it proves the stack works
- **Not in scope** — what is explicitly deferred to later specs
- **Assumptions** — what the installed stack already provides
- **Contracts** — function signatures and API shapes using the approved stack's types. Backend block uses `[backend_lang]`. Frontend block present only if frontend exists.
- **Behaviour** — numbered steps for the happy path
- **Failure paths** — at least one per external I/O (DB, external API)
- **Files** — actual paths using `[backend_dir]`, `[frontend_dir]` config key placeholders
- **Tests** — test names in `test_[unit]_[scenario]_[expected]` format
- **Done when** — checklist using `[typecheck_cmd]`, `[lint_cmd]`, `[test_cmd]` placeholders

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

**Decisions to record:** identify 3–5 key architectural decisions from the interview. Format:

```
Decisions I'll record in docs/DECISIONS.md:
DEC-001 — [decision] — [rationale]
DEC-002 — [decision] — [rationale]
[...]
```

**Project-specific rules:** derive 3–5 absolute rules implied by the architecture. Show:

```
Project rules I'll add to CLAUDE.md:
- [rule — e.g. "Never expose internal database IDs in API responses"]
- [rule — e.g. "All mutations must be idempotent — external services may retry"]
- [rule — e.g. "No synchronous calls to external services in the HTTP request path"]
```

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

## Decisions
<!-- One entry per decision, DEC-NNN format -->

## Project rules
<!-- 3-5 project-specific absolute rules derived from architecture discussion -->

## Architecture
<!-- Full architecture text as drafted and approved in Phase 3 -->

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
