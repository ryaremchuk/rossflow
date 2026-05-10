---
name: spec-implement
description: Implement a spec from specs/ directory. Pass spec filename without .md. After implementation writes smoke test file and context update file.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-config.md`
- `.claude/workflow-git.md`

---

Implement: `specs/$ARGUMENTS.md`

---

## Step 1 — Read context

Check branch:
```bash
git branch --show-current
```
If not on `[branch_prefix]/$ARGUMENTS` → abort. Output: `⛔ Wrong branch. Run: git checkout [branch_prefix]/$ARGUMENTS`

Read in order:
1. `specs/$ARGUMENTS.md` — full spec
2. `PROGRESS.md` — if 🔄 In progress, list existing files first
3. `docs/MAP.md` — identify component READMEs / docs for this spec, read them
4. `smoke-tests/template.md` — needed for Step 5
5. Files listed in spec's **Depends on**
6. Context Search: Do not read the entirety of `PATTERNS.md` and `DECISIONS.md`. Instead, use your search tools (grep or equivalent) to search those files for keywords related to the current spec to find specific, relevant conventions. (e.g., if the spec is about billing, search for 'billing' or 'stripe').
7. `docs/ARCHITECTURE.md` (full)
8. `docs/DECISIONS.md` (full; at scale, paginate by §affects matching this spec)
9. `docs/COMPONENT-LIBRARY.md` if exists
10. `docs/DESIGN-SYSTEM.md` if exists

---

## Step 2 — Plan + architecture-fit gate

Output:
- **Files to create or modify:** <list>
- **DEC alignment:** for each affecting DEC, state how plan honors it. If violated → STOP; propose supersession.
- **Components consumed:** list from COMPONENT-LIBRARY.md. Reuse ratio = imported_library_components / total_visible_ui_elements. For screen specs: ≥0.6. Below → reject plan.
- **New patterns introduced:** any not in PATTERNS.md. Must either be already documented or accompanied by post-implement proposal.
- **Architecture-fit statement:** "Implements <layer> per Architecture §<N>. Does not violate boundaries §10. Assumes DEC-<list>. New components: <list or none>."
- **Ambiguities or conflicts:** with proposed resolution.

👤 Action needed: independent approval gate (apply approval-gate rules).
⛔ STOP. Wait for explicit confirmation in response to THIS gate.

---

## Step 3 — Implement

If spec frontmatter has `type: screen`, hand off to `screen-implement` skill (inherits this plan, applies design-fidelity rules). Resume here for Step 4 reporting.

Else implement everything in spec per existing rules.

- Implement everything in spec. No skipping, no scope creep.
- Follow `docs/PATTERNS.md` and `.claude/CLAUDE.md`.
- After each [backend_lang] file: run `[typecheck_cmd]` + `[lint_cmd]`. After each [frontend_lang] file: run `[frontend_typecheck_cmd]` (skip if `none`).
- Test fails → fix implementation. Lint fails → fix code.
- New DB table/column → follow `[db_migration_tool]` conventions for schema changes (skip if `[db_migration_tool]` is `none`).

Bug triage: code mistake → fix here | spec mistake → stop, report, wait for approval.

---

## Step 4 — Verify + simplify

Run spec's Verification section + standard typecheck/lint/test:
```bash
# [backend_lang]
[typecheck_cmd]   # pass changed files via {files} placeholder
[lint_cmd]        # pass changed files via {files} placeholder
[test_cmd]        # run from [test_dir]

# [frontend_lang] — skip each command if value is none
[frontend_typecheck_cmd]
[frontend_lint_cmd]
[frontend_test_cmd]
```

After all checks pass, AUTO-INVOKE Claude Code's built-in `/simplify` skill with this spec's modified files as input. /simplify reads project conventions from PATTERNS.md and target project's CLAUDE.md "Project Rules" section, and enforces hard caps (file LOC, complexity, FlatList, useSafeAreaInsets, no inline hex) defined there.

Re-run typecheck/lint/test after simplify pass. If simplify proposes refactors that break tests, skip those proposals.

Update PROGRESS.md.

---

## Step 5 — Write smoke test

Write `smoke-tests/$ARGUMENTS.md` using `smoke-tests/template.md`.

Base smoke test on the spec contract, NOT on what was built. If implementation deviated, deviation MUST be:
1. Recorded in PROGRESS.md
2. Justified in context update (Step 6)
3. Either reverted, escalated, or formalized as DEC

Smoke failures driven by spec-vs-built drift are valid signal. Do not mask drift by writing tests against deviated implementation.

Rules:
- Every external I/O: at least one happy-path + one failure-path step
- [ui_driver] steps: always `waitFor` patterns, never `setTimeout` (omit if `[ui_driver]` is `none`)
- DB queries: exact table/column names from migration files
- Step IDs: S01, S02, S03...
- Tags: `happy-path` | `failure-path` | `edge-case`
- Types: `HTTP` | `[ui_driver]` | `DB`

Mandatory [ui_driver] patterns (if `[ui_driver]` is `none`, skip this block):
```javascript
await page.waitForLoadState('networkidle');
await page.waitForSelector('[data-testid="..."]', { state: 'visible' });
await page.waitForResponse(resp => resp.url().includes('/api/...') && resp.status() === 200);
await expect(page.locator('...')).toBeVisible();
// Never: await page.waitForTimeout(2000)
```

---

## Step 6 — Write context update

Create `specs/updates/context-update-$ARGUMENTS.md`:
Fill every section honestly based on what was actually built — not what the spec said.
If a section has nothing to report, write `none`.

```markdown
# Context Update — $ARGUMENTS
_Generated: <date>_

## Interfaces built
<!-- signatures + types only, no bodies -->
### <module path>
```python
<signature>
```

## Architecture / decision impact
<!-- which docs/ARCHITECTURE.md sections or docs/DECISIONS.md DECs need updating and why; processed by /decision-sync -->
- ARCHITECTURE.md §<N> — <reason>
- DEC-<NN> — <reason>

## Deviations from spec
<!-- "Spec said X — built Y — reason: Z" -->

## New patterns introduced
<!-- "Pattern — description — where used" -->

## Decisions surfaced
<!-- "Decision — what chosen — why" -->

## Dependencies added
<!-- "package — why" -->
```

---

## Step 7 — Done

```
✅ spec-implement complete: $ARGUMENTS

Tests:          passed
Lint:           clean
PROGRESS:       ✅ Completed
Smoke test:     smoke-tests/$ARGUMENTS.md
Context update: specs/updates/context-update-$ARGUMENTS.md

Next: /spec-smoke-test $ARGUMENTS
```
