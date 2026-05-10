---
name: discover-smoke-scenarios
description: Generate fresh smoke-test scenario set for a module/spec by reading current source + DECs + specs. Approved scenarios are frozen as a regression baseline. Re-runs produce diffs against baseline, not regenerations, to keep results deterministic and signal-rich.
---

## Config

Read the following files before executing this skill.

- `.claude/workflow-config.md` — for `backend_dir`, `frontend_dir`
- `.claude/workflow-infra.md` — for service ports, DB url
- `.claude/workflow-smoke.md` — for `ui_driver`, smoke script lang

---

Discover regression scenarios. Input: `$ARGUMENTS` = module path | spec name | `--all`.

Optional flag: `--refresh` to regenerate frozen baseline (default behavior is diff-only against existing baseline).

⛔ NO FILES WRITTEN until Step 5.

---

## Step 0 — Determine scope

Parse `$ARGUMENTS`:
- Path under `[backend_dir]` or `[frontend_dir]` → module mode
- Starts with `spec-` → spec mode (read the spec, scope to its files)
- `--all` → iterate over every per-component README listed in `docs/MAP.md`

Determine baseline file location:
- Module mode: `smoke-tests/regression/<module-path-as-slug>.md`
- Spec mode: `smoke-tests/regression/<spec-name>.md`
- `--all`: process each module in turn

Detect `--refresh` flag in `$ARGUMENTS`. Default = false.

---

## Step 1 — Read current state

For the chosen scope:
1. Source files under scope path
2. `docs/DECISIONS.md` — DECs whose `Affects:` line references files in scope
3. Specs under `specs/` whose Files section overlaps scope
4. Existing `smoke-tests/spec-*.md` for specs in scope (the historical per-spec smokes)
5. Existing baseline file (if any) at the location from Step 0
6. `docs/COMPONENT-LIBRARY.md`, `docs/DESIGN-SYSTEM.md` if scope touches UI

---

## Step 2 — Generate fresh scenario set

⛔ NO FILES WRITTEN.

Derive scenarios from current state, NOT from existing per-spec smoke tests (those were correct at impl time but may have aged):

1. **Public interface contracts**: every exported function / endpoint / component prop in scope → at least one happy-path scenario asserting current behavior, one failure-path scenario for each external I/O.
2. **DEC `Verifies:` rules**: every applicable DEC's invariant → one scenario asserting the invariant holds at runtime (complementing the static `decision-verify` check).
3. **Edge cases from code paths**: branches, error handlers, defensive checks present in current source → one scenario per non-trivial branch.
4. **Cross-module integration**: where scope module calls another module → one scenario asserting the integration contract.

Format: same as `workflow/templates/smoke-test-template.md`. Step IDs `R01`, `R02`, ... ("R" for regression). Tags: `happy-path` | `failure-path` | `edge-case` | `invariant`.

For each scenario, capture:
- ID, title, type (HTTP / DB / [ui_driver]), tag
- Action (concrete: exact call, exact selector)
- Expected (concrete: status, response shape, DB state)
- Source: which interface/DEC/branch generated this scenario (one-liner — useful for debugging stale scenarios later)

---

## Step 3 — Diff against baseline (if exists)

If a baseline at `smoke-tests/regression/<scope>.md` exists AND `--refresh` was NOT specified:

Compute diff:
- **Stable**: scenarios in both, unchanged
- **Modified**: same ID, behavior or assertions differ
- **Added**: in fresh set, not in baseline (new behavior introduced since baseline was frozen)
- **Removed**: in baseline, not in fresh set (behavior removed or refactored)

Output to user:
```
🧪 Scenario diff vs baseline (smoke-tests/regression/<scope>.md)
  Stable:    N
  Modified:  N (S03, S07 — show details below)
  Added:     N (R12, R13 — new behaviors not in frozen baseline)
  Removed:   N (R04 — behavior gone or moved)

[modified/added/removed details with source attribution]
```

Then:
```
👤 **Action needed:**
The frozen baseline is the regression contract. Choose:
- "approve diff" → update baseline to incorporate Added/Modified, retire Removed (audit-trailed)
- "reject diff" → keep baseline as-is, treat fresh set as advisory only
- "selective" → tell me which Added/Modified/Removed to accept

Or run with `--refresh` to discard the baseline entirely and replace.
```

⛔ STOP. Wait for user direction.

If no baseline exists → skip diff, go to Step 4 (first-time freeze).

If `--refresh` → skip diff, go to Step 4 (full regenerate, with confirmation).

---

## Step 4 — Approval gate for new/refresh baseline

If first-time OR `--refresh`:

Output the full fresh scenario set with source attributions. Then:

```
👤 **Action needed:**
This will be frozen as the regression baseline at smoke-tests/regression/<scope>.md.
Future /smoke-all runs will assert these scenarios.

Review carefully — frozen scenarios are the contract.

Say "freeze" to write, or tell me what to change.
```

⛔ STOP. Wait for "freeze".

---

## Step 5 — Write baseline

✅ FILES WRITTEN HERE.

1. `smoke-tests/regression/<scope>.md` — frozen baseline with frontmatter:
```yaml
---
scope: <module-or-spec>
frozen_at_sha: <git rev-parse HEAD>
frozen_at: <YYYY-MM-DD>
last_diff_review: <YYYY-MM-DD>
---
```

2. If diff was approved (Step 3 path): preserve previous baseline as `smoke-tests/regression/_archive/<scope>-<old-frozen-at>.md` for audit trail.

3. `smoke-tests/regression/CHANGELOG.md` — append one line per freeze: `<date> | <scope> | <action: freeze | refresh | diff-merge> | scenarios: <count>`

---

## Step 6 — Output

```
✅ smoke-tests/regression/<scope>.md frozen (<N> scenarios)
✅ smoke-tests/regression/CHANGELOG.md updated
<old baseline archived if applicable>

Next: /smoke-all to run all baselines + per-spec smokes
```
