# rossflow - AI Development Workflow

> STATUS: IN PROGRESS — extraction and generalization phase

## Structure
- `skills/` — SKILL.md files, one per skill
- `templates/` — file templates used by skills at runtime
- `patterns/` — pattern library: always-on engineering standards + opt-in technology presets
- `config-templates/` — blank workflow config files with documented keys, copied to `.claude/` on install
- `docs-templates/` — structural shells for project knowledge base docs
- `workflow-instructions.md` — workflow rules injected into any project via one CLAUDE.md reference line
- `install.sh` — copies workflow into a target project

## Install
```bash
bash install.sh /path/to/target-project
```
