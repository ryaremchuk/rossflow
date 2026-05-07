---
name: workflow-init
description: Scaffold a new project's rossflow structure — creates directories, places templates and config files, wires CLAUDE.md, then hands off to project-init-new. Run once after install.sh.
---

Initialise rossflow for this project.

⛔ Never overwrite existing files. This skill is safe to re-run.

---

## Step 1 — Verify prerequisites

Check that rossflow has been installed:

```bash
ls .claude/workflow-instructions.md
ls .claude/skills/
```

If either is missing, stop immediately:

```
⛔ rossflow not installed.

Run install first:
  bash .claude/rossflow/install.sh

Then re-run: /workflow-init
```

Do not proceed past this step if either check fails.

---

## Step 2 — Create project folder structure

Create each directory if it does not already exist. Never overwrite existing content.

```bash
mkdir -p docs/ctx
mkdir -p specs/updates
mkdir -p smoke-tests
mkdir -p bugs
```

Report each directory:
- `created` — mkdir ran and directory is new
- `already existed` — directory was already present

---

## Step 3 — Place docs templates

Source: `.claude/rossflow/docs-templates/`
Destination: `docs/`

For each file, check if the destination already exists. Copy only if it does not.

Files to place:
- `ARCHITECTURE.md` → `docs/ARCHITECTURE.md`
- `DECISIONS.md` → `docs/DECISIONS.md`
- `PATTERNS.md` → `docs/PATTERNS.md`
- `MAP.md` → `docs/MAP.md`

Report each file: `placed` or `skipped (already exists)`.

If any source file is missing from `.claude/rossflow/docs-templates/`, stop:
```
⛔ Step 3 failed: source file missing — .claude/rossflow/docs-templates/<filename>
install.sh may be incomplete. Re-run: bash .claude/rossflow/install.sh
```

---

## Step 4 — Place operational templates

Source: `.claude/rossflow/templates/`

For each file, check if the destination already exists. Copy only if it does not.

Files to place:
- `spec-template.md` → `specs/spec-template.md`
- `smoke-test-template.md` → `smoke-tests/template.md`
- `bug-template.md` → `bugs/template.md`

Report each file: `placed` or `skipped (already exists)`.

If any source file is missing from `.claude/rossflow/templates/`, stop:
```
⛔ Step 4 failed: source file missing — .claude/rossflow/templates/<filename>
install.sh may be incomplete. Re-run: bash .claude/rossflow/install.sh
```

---

## Step 5 — Place config files

Source: `.claude/rossflow/config-templates/`
Destination: `.claude/`

For each file, check if the destination already exists. Copy only if it does not.

Files to place:
- `workflow-config.md` → `.claude/workflow-config.md`
- `workflow-infra.md` → `.claude/workflow-infra.md`
- `workflow-git.md` → `.claude/workflow-git.md`
- `workflow-smoke.md` → `.claude/workflow-smoke.md`

Report each file: `placed` or `skipped (already exists)`.
Track count of skipped files for the summary.

If any source file is missing from `.claude/rossflow/config-templates/`, stop:
```
⛔ Step 5 failed: source file missing — .claude/rossflow/config-templates/<filename>
install.sh may be incomplete. Re-run: bash .claude/rossflow/install.sh
```

---

## Step 6 — Place patterns library

Source: `.claude/rossflow/patterns/`
Destination: `docs/patterns/`

```bash
mkdir -p docs/patterns
```

For every `.md` file in `.claude/rossflow/patterns/`, check if the destination file already exists. Copy only if it does not.

Report: total files placed and total skipped.
Track count of skipped files for the summary.

If the source directory is missing, stop:
```
⛔ Step 6 failed: patterns directory missing — .claude/rossflow/patterns/
install.sh may be incomplete. Re-run: bash .claude/rossflow/install.sh
```

---

## Step 7 — Wire CLAUDE.md

The reference line that must be present:
```
For AI development workflow rules, see .claude/workflow-instructions.md
```

**If `CLAUDE.md` does not exist:** create it with exactly this content:
```
[Project Name]

Replace this with a one-line description of your project.

For AI development workflow rules, see .claude/workflow-instructions.md
```
Report: `CLAUDE.md created`.

**If `CLAUDE.md` exists:**
Read it. Check if the reference line is already present anywhere in the file.
- Already present → report: `CLAUDE.md already wired`. No changes.
- Not present → append the reference line at the end of the file (preceded by a blank line if the file does not already end with one).
  Report: `CLAUDE.md updated — reference line appended`.

---

## Step 8 — Create PROGRESS.md

Source: `.claude/rossflow/docs-templates/PROGRESS.md`

Check if `PROGRESS.md` exists in the project root.
- Exists → report: `PROGRESS.md already exists. Skipped.`
- Does not exist → copy from source to project root.
  Report: `PROGRESS.md created`.

If the source file is missing, stop:
```
⛔ Step 8 failed: source file missing — .claude/rossflow/docs-templates/PROGRESS.md
install.sh may be incomplete. Re-run: bash .claude/rossflow/install.sh
```

---

## Step 9 — Summary and handoff

Print this table, filling in the actual status from each step:

```
rossflow init — summary
───────────────────────────────────────────────────────────
 Item                  Status
───────────────────────────────────────────────────────────
 docs/ structure       created / already existed
 specs/ structure      created / already existed
 smoke-tests/          created / already existed
 bugs/                 created / already existed
 Docs templates        placed / skipped (N existing)
 Operational templates placed / skipped (N existing)
 Config files          placed / skipped (N existing)
 Patterns library      placed / skipped (N existing)
 CLAUDE.md             created / updated / already wired
 PROGRESS.md           created / already existed
───────────────────────────────────────────────────────────
```

Then print:
```
✅ rossflow init complete.

Config files are in .claude/ — they are empty stubs.
Do not fill them manually.

Next step will ask you questions and populate them.

Proceeding to: /project-init-new
```

Immediately invoke the `project-init-new` skill.
