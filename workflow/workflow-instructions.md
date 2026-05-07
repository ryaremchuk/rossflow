# Workflow Instructions
> This file is owned by the workflow package. Do not edit manually.
> Referenced from CLAUDE.md via: "For AI development workflow rules, see `.claude/workflow-instructions.md`"
> Project-specific rules belong in CLAUDE.md, not here.

---

## How to find things

- Architecture and data flows → `docs/ARCHITECTURE.md`
- Every settled decision with reasoning → `docs/DECISIONS.md`
- Code conventions (imports, logging, typing) → `docs/PATTERNS.md`
- Component-level context → `docs/MAP.md` → then relevant `docs/ctx/ctx-<component>.md`
- Current build state, what exists → `PROGRESS.md`
- Workflow config (commands, dirs, stack) → `.claude/workflow-config.md`
- Infra config (ports, DB, services) → `.claude/workflow-infra.md`

---

## Skill invocation

| Task | Command | What it does |
|------|---------|--------------|
| **⬅ New project** | `/workflow-init` | Scaffolds project structure, places all templates and configs, then calls project-init-new |
| **⬅ Existing project** | `/project-init-new` | Structured interview: defines architecture, tech stack, patterns, writes session file |
| Write project files | `/project-init-write` | Reads session file, shows summary, requires CONFIRM, writes all project files |
| Create new spec | `/spec-create <description or existing spec path>` | Generates spec file with outline approval gate, validation, branch checkout |
| Implement spec | `/spec-implement <spec-filename-without-extension>` | Implements spec with typecheck/lint cycles, writes smoke test and context update |
| Run smoke tests | `/spec-smoke-test <spec-filename-without-extension>` | Executes HTTP/DB/UI steps, files bug reports on failure |
| Fix open bugs | `/bug-fix <spec-filename-without-extension>` | Severity-ordered bug fixes, max 3 attempts, escalates contract-breaking bugs |
| Automated smoke+fix loop | `/spec-smoke-and-fix <spec-filename-without-extension>` | Smoke → fix → repeat up to 3 cycles |
| Sync docs from context updates | `/context-sync` | Merges context-update files into ARCHITECTURE.md, ctx files, MAP.md |
| Commit + push + PR | `/ship` | Conventional commit, push, PR creation |

---

## Coding behavior

- State assumptions before implementing. If ambiguous, ask.
- No scope creep — implement exactly what the spec says, nothing more.
- Touch only what the task requires. Mention unrelated issues, don't fix them.

---

## File creation checklist

**New API route:**
- [ ] Route handler in `[backend_dir]/api/routes/<module>`
- [ ] Request and response models / schemas
- [ ] Unit tests in `[test_dir]/api/test_<module>`

**New DB table or column:** (skip if `[db_migration_tool]` is `none`)
- [ ] Update model / schema file
- [ ] Generate migration using `[db_migration_tool]`
- [ ] Review generated migration before applying
- [ ] Apply migration

---

## Conditionality Rules

When reading config files, apply these rules for optional components:

- If `[frontend_lang]` is `none` — skip all frontend steps, lint, typecheck, test, and service references
- If `[db_type]` is `none` — skip all database steps, migrations, and DB smoke test sections
- If `[ui_driver]` is `none` — skip all UI/smoke test steps that require a browser or device driver
- If `[orchestrator]` is `none` — skip all container management steps; assume services are running externally
- If `[pr_tool]` is `none` — skip PR creation; push branch only

---

## When compacting

Always preserve: list of modified files, any failing tests, current spec name and phase, open tech debt comments (`DEBT[...]`).

---

## Absolute rules (workflow-level)

- Never skip type annotations — type checking enforced
- Never modify DB schema without a migration (if `[db_migration_tool]` is not `none`)
- Never commit secrets — `.env` only, never in code or git
- Never skip response schema / contract validation on API routes
- Read `workflow-config.md` before running lint, typecheck, or test commands — use the configured commands, not assumed ones

---

## Project-Specific Rules

This section is populated by project-init-new during initialization.
Do not edit manually.

[project rules will be inserted here]
