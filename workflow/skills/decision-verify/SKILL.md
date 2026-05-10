---
name: decision-verify
description: Run all DEC `verifies` rules in DECISIONS.md as machine checks. Fails on violation. Auto-invoked by /spec-create at Step 0; also runnable manually after refactors or before /ship.
---

## When to run

- **Auto-invoked** at the start of `/spec-create` (Step 0) — cheap when no DEC has a `Verifies:` block. Blocks new specs that would build on top of violated decisions.
- **Manual invocation** after a large refactor, before `/ship`, or as a CI gate.
- DECs without a `Verifies:` block (or marked `Unverifiable: true`) are skipped.

If you only have `principles`/`arch` decisions and no machine-checkable rules yet, this skill is effectively a no-op — that is fine.

## Step 1 — Read
`docs/DECISIONS.md` — parse every DEC entry.

## Step 2 — Run checks
For each DEC with `Verifies:` block: execute `Check:` shell command. Capture exit code + output.
Skip DECs with `Status: superseded` or `Unverifiable: true`.

## Step 3 — Report

```
DEC verification report
=======================
Checked: <N> | Skipped (superseded): <N> | Skipped (unverifiable): <N>
Passed: <N> | Failed: <N>
Failures:
- DEC-NNN: <title>
  Rule: <text>
  Output: <command stdout/stderr>
```

Exit non-zero if any failures.

## Step 4 — Action
On failures:
- Recommend either fixing code violation, OR superseding DEC via decision-sync.
- Block downstream skills (spec-create, spec-implement) until resolved unless `--allow-failures`.

## Notes
- Designed for pre-commit hook OR CI.
- Invokable manually as `/decision-verify`.
- DEC `Check:` commands MUST be portable bash, idempotent. Use `rg`, `jq`, AST-grep.
