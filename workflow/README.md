# rossflow

AI development workflow package. Adds a structured, skill-based development
process to any project regardless of tech stack.

## Quickstart

Install into any project:
```bash
bash install.sh /path/to/your-project
```

Then open Claude Code in your project and run:
```
/workflow-init
```

## What's included

### Skills (10)
| Skill | Trigger | Purpose |
|-------|---------|---------|
| workflow-init | /workflow-init | Scaffold project structure, place templates and configs |
| project-init-new | /project-init-new | Structured interview: stack, architecture, patterns, spec-000 |
| project-init-write | /project-init-write | Write all project files after interview CONFIRM |
| spec-create | /spec-create | Generate a spec file with approval gate and branch |
| spec-implement | /spec-implement | Implement a spec with lint/test cycles |
| spec-smoke-test | /spec-smoke-test | Run smoke tests, file bug reports |
| spec-smoke-and-fix | /spec-smoke-and-fix | Automated smoke → fix loop |
| bug-fix | /bug-fix | Fix open bug reports |
| context-sync | /context-sync | Sync context files to architecture docs |
| ship | /ship | Commit, push, create PR |

### Patterns library (9 files)
Always-on: principles, arch
Tech presets: fastapi, sqlalchemy, pytest, nextjs, reactnative, django

### Templates (6)
spec, smoke-test, bug, ctx, decisions, pr-description

### Config templates (4)
workflow-config, workflow-infra, workflow-git, workflow-smoke

## How it works

1. `install.sh` copies rossflow into `.claude/` of your target project
2. `/workflow-init` scaffolds `docs/`, `specs/`, `bugs/`, `smoke-tests/`, wires `CLAUDE.md`
3. `/project-init-new` interviews you: stack, architecture, first spec
4. `/project-init-write` writes all config and doc files after your approval
5. Development cycle: spec-create → spec-implement → spec-smoke-test → ship
