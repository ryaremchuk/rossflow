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
1. `specs/$ARGUMENTS.md` — full contract spec
2. `specs/plans/plan-$ARGUMENTS.md` — implementation plan (file list, DEC alignment, reuse mapping, risks, rollback). REQUIRED. If missing → abort. Output: `⛔ Plan file missing. Run /spec-create first or generate plan manually.`
3. `smoke-tests/$ARGUMENTS-DRAFT.md` — pre-impl smoke test draft (your acceptance target while coding). REQUIRED. If missing → abort with same instruction.
4. `PROGRESS.md` — if 🔄 In progress, list existing files first
5. `docs/MAP.md` — identify component READMEs / docs for this spec, read them
6. `smoke-tests/template.md` — needed for Step 5 refinement
7. Files listed in plan's **Files to create or modify** + spec's **Depends on**
8. Context Search: Do not read the entirety of `PATTERNS.md` and `DECISIONS.md`. Instead, use your search tools (grep or equivalent) to search those files for keywords related to the current spec to find specific, relevant conventions. (e.g., if the spec is about billing, search for 'billing' or 'stripe').
9. `docs/ARCHITECTURE.md` — context-aware read:
   - If file ≤ 800 lines → read full
   - If file > 800 lines → read section index/TOC first, then read only sections matching the plan's `Architecture-fit statement` (e.g., §3, §10) plus any sections cited in the contract spec
10. `docs/DECISIONS.md` — context-aware read:
    - If file ≤ 800 lines → read full
    - If file > 800 lines → grep for DEC-NNN ids cited in the plan's DEC alignment section, plus search for keywords from the spec scope. Read only matching DEC blocks
11. `docs/COMPONENT-LIBRARY.md` if exists — read entries listed in plan's `Components consumed`
12. `docs/DESIGN-SYSTEM.md` if exists

---

## Step 2 — Plan re-validation + architecture-fit gate

The plan was approved at `/spec-create` time. Re-validate against current state — code may have drifted since then.

Output:
- **Plan file:** `specs/plans/plan-$ARGUMENTS.md` (loaded in Step 1)
- **Re-validation against current state:**
  - Files in plan still exist where expected? (or are flagged for create) ✅ / ⚠️ <diff>
  - DEC alignment still valid? Run targeted check on each DEC the plan cites — any now violated by other recent specs? ✅ / ⚠️ <list>
  - Components consumed still in COMPONENT-LIBRARY.md? ✅ / ⚠️ <missing>
  - In-progress overlap from PROGRESS.md still relevant? ✅ / ⚠️ <new overlaps>
  - Risks from plan still apply? Any new risks surfaced by recent commits? ✅ / additional risks: <list>

If re-validation surfaces any ⚠️: explain what changed, propose plan amendments inline, and request re-approval. If clean: state "Plan re-validated, no drift" and proceed.

👤 Action needed: independent approval gate (apply approval-gate rules). Confirm plan is still right OR confirm proposed amendments.
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

## Step 5 — Refine smoke test from draft

The draft `smoke-tests/$ARGUMENTS-DRAFT.md` was generated at `/spec-create` time as your acceptance target. Refine it into the final runnable smoke test.

1. Read `smoke-tests/$ARGUMENTS-DRAFT.md` (already in context from Step 1).
2. Read `smoke-tests/template.md` for the full executable format.
3. For each draft step, fill in concrete details: exact endpoint paths, exact request/response shapes, exact selectors, exact wait conditions, exact verification SQL.
4. Add any additional steps required by the contract that the draft missed (failure paths, edge cases).
5. Write `smoke-tests/$ARGUMENTS.md` (final, runnable) — do NOT delete the DRAFT (kept as audit trail of pre-impl intent).

Base the final smoke test on the spec contract, NOT on what was built. If implementation deviated, deviation MUST be:
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
