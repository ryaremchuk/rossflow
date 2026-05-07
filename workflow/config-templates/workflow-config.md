# Workflow Config
# Primary config — read by every skill at runtime.
# Populated by project-init-new during project initialization.

## Project
project_name:           # e.g. myapp — used in subagent prompts and reports

## Stack
backend_lang:           # python | go | rust | node | java
package_manager:        # uv | pip | npm | yarn | cargo | go mod
frontend_lang:          # typescript | javascript | none
test_runner:            # pytest | jest | vitest | go test | cargo test

## Commands
# Use {files} as placeholder where the skill passes specific file paths
typecheck_cmd:          # e.g. uv run mypy {files} --strict
lint_cmd:               # e.g. uv run ruff check {files}
test_cmd:               # e.g. uv run pytest {test_dir} -v --tb=short
frontend_typecheck_cmd: # e.g. npx tsc --noEmit | none
frontend_lint_cmd:      # e.g. npx eslint src/ --ext .ts,.tsx | none
frontend_test_cmd:      # e.g. npm test -- --watchAll=false | none

## Directories
backend_dir:            # e.g. backend
frontend_dir:           # e.g. frontend | none
test_dir:               # e.g. backend/tests
specs_dir:              # e.g. specs
smoke_tests_dir:        # e.g. smoke-tests
bugs_dir:               # e.g. bugs
docs_dir:               # e.g. docs

## Patterns
# Stems of pattern preset files to merge into docs/PATTERNS.md during init
# Engineering standards (principles, arch) are always included — do not list them here
patterns_include:       # e.g. [fastapi, sqlalchemy, pytest, nextjs]
