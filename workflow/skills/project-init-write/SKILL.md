---
name: project-init-write
description: Reads .claude/project-init-session.md written by /project-init-new, shows a summary, requires CONFIRM, then writes all project config files, docs, CLAUDE.md, and spec-000.
---

Read the project-init session file and write all project outputs after explicit confirmation.

⛔ No project files written before CONFIRM.

---

## Step 1 — Read and validate session file

Read `.claude/project-init-session.md`.

If the file does not exist:
```
❌ No session file found at .claude/project-init-session.md

Run /project-init-new first to complete the project interview.
```
Stop.

If `_Status: complete_` is present:
```
⚠️  This session has already been applied (Status: complete).

Re-running will overwrite existing project files.
Continue anyway? (yes / no)
```
⛔ STOP. If "no" — halt.

Check that these fields are non-empty: `name`, `backend_lang`, `## Architecture` section content, `## Spec-000` section content.

If any are missing or empty, list them and stop:
```
❌ Session file is incomplete. Missing required fields:
- [field name]
- [field name]

Edit .claude/project-init-session.md to fill these fields, then re-run /project-init-write.
```

---

## Step 2 — Show summary

Count the number of decision entries in the `## Decisions` section.

Present:

```
Ready to write — please confirm.
──────────────────────────────────────────────────
Project:      [name]
Stack:        [backend_lang] / [frontend_lang] / [db_type]
Orchestrator: [orchestrator]
Patterns:     [patterns_include]
Decisions:    [N] to record
First spec:   spec-000-[name]

Files that will be written:
  .claude/workflow-config.md
  .claude/workflow-infra.md
  .claude/workflow-git.md
  .claude/workflow-smoke.md
  docs/ARCHITECTURE.md
  docs/DECISIONS.md
  docs/patterns/PATTERNS.md    ← ✅ marks added to selected patterns
  CLAUDE.md                    ← project description + ## Project Rules appended
  specs/spec-000-[name].md
──────────────────────────────────────────────────
Type CONFIRM to write all files, or tell me what to change.
```

⛔ STOP. Wait for CONFIRM or explicit equivalent ("yes", "do it", "write it").

If developer requests changes: update `.claude/project-init-session.md` with those changes, then re-show the summary above. Do not write project files until CONFIRM.

---

## Step 3 — Write outputs (only after CONFIRM)

Write in this order. Print each filename as it is written.

**Re-run guard:** if a file already has content beyond template placeholders, show the first line of existing content and the new value, then ask:
```
[filename] already has content. Overwrite? (yes / skip)
```
⛔ STOP. Wait for response before writing that file.

---

### 1 — `.claude/workflow-config.md`

Populate from session `## Stack` and `## Patterns` sections:

```
project_name:           [name]
backend_lang:           [backend_lang]
package_manager:        [package_manager]
frontend_lang:          [frontend_lang]
test_runner:            [test_runner]
typecheck_cmd:          [typecheck_cmd]
lint_cmd:               [lint_cmd]
test_cmd:               [test_cmd]
frontend_typecheck_cmd: [frontend_typecheck_cmd]
frontend_lint_cmd:      [frontend_lint_cmd]
frontend_test_cmd:      [frontend_test_cmd]
backend_dir:            [backend_dir]
frontend_dir:           [frontend_dir]
test_dir:               [test_dir]
specs_dir:              specs
smoke_tests_dir:        smoke-tests
bugs_dir:               bugs
docs_dir:               docs
patterns_include:       [patterns_include]
```

Preserve comments and section headers from the template. Keep any line whose value is empty as a blank placeholder.

---

### 2 — `.claude/workflow-infra.md`

Populate from session `## Infra` section. Preserve template comments and headers.

---

### 3 — `.claude/workflow-git.md`

Populate from session `## Git` section. Preserve template comments and headers.

---

### 4 — `.claude/workflow-smoke.md`

Populate from session `## Smoke` section. Preserve template comments and headers.

---

### 5 — `docs/ARCHITECTURE.md`

Write full content from session `## Architecture` section. Sections: Overview, Modules, Data Flows, External Integrations, Key Constraints.

---

### 6 — `docs/DECISIONS.md`

Write one row per decision entry from session `## Decisions` section. Use today's date for any entry without a date. Format:

```
| DEC-001 | [decision] | [rationale] | [date] | — |
```

---

### 7 — `docs/patterns/PATTERNS.md`

Add `✅` prefix to each pattern stem listed in `patterns_include`. Add `⬜` prefix to all other pattern entries. Do not modify descriptions, links, or other content.

---

### 8 — `CLAUDE.md`

Append after the existing content (do not modify anything already in the file):

```

[project description from session ## Project → description field]

## Project Rules
[rules from session ## Project rules section, one bullet per line]
```

---

### 9 — `specs/spec-000-[name].md`

Write the full content from session `## Spec-000` section verbatim. Section order and names must match `specs/spec-template.md`. No custom sections, no omitted sections.

---

## Step 4 — Mark session complete

Update `.claude/project-init-session.md`: change `_Status: awaiting-confirm_` to `_Status: complete_`.

Print:

```
✅ project-init-write complete.

Next steps:
1. Review docs/ARCHITECTURE.md and docs/DECISIONS.md — adjust if needed
2. Run: /spec-implement spec-000-[name]
3. After implementation: /spec-smoke-test spec-000-[name]
4. Then: /ship
```
