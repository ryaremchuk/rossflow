---
name: smoke-all
description: Run all per-spec smoke tests and all frozen regression baselines in sequence. Files bug reports for failures. Manual trigger — not auto-invoked by /ship. Use when you want to verify nothing has regressed before shipping.
---

## Config

Read the following files before executing this skill.

- `.claude/workflow-config.md` — for `bugs_dir`, `smoke_tests_dir`
- `.claude/workflow-infra.md` — for orchestrator, services, ports, DB
- `.claude/workflow-smoke.md` — for `ui_driver`, smoke script lang

---

Run full regression suite. Input: `$ARGUMENTS` (optional) = `--quick` to skip baselines, run per-spec only.

⛔ Do NOT mask failures. Failures are signal.

---

## Step 0 — Ensure orchestrator running

If `[orchestrator]` is `none` → skip.

Else verify services up:
```bash
[orchestrator] ps
```

If any required service is down: start it (`[orchestrator] up -d`) and wait for ready check per `.claude/workflow-infra.md`.

---

## Step 1 — Discover smoke files

1. Per-spec smokes: list `smoke-tests/spec-*.md` (exclude `*-DRAFT.md` and any under `regression/` or `_archive/`).
2. Regression baselines: list `smoke-tests/regression/*.md` (skip if `--quick` flag set, or if directory is empty).

Total count = per-spec + baseline. Output:
```
🧪 Smoke-all run
  Per-spec smokes:  <N>
  Regression baselines: <N>
  Total: <N>
```

If total is 0 → output `No smoke tests found. Nothing to run.` and exit clean.

---

## Step 2 — Execute in order

Order: regression baselines first (they assert invariants — fail fast on architectural drift), then per-spec smokes (in spec-number order).

For each smoke file: invoke `/spec-smoke-test <file>` (delegate to existing skill — do NOT duplicate execution logic). Capture per-step pass/fail.

Track:
- Total steps run
- Steps passed
- Steps failed (with file + step ID)
- Any execution errors (e.g., service unreachable, DB connection failed)

If a regression baseline fails: continue to remaining smokes (gather full picture) but mark severity 🔴 in summary.

---

## Step 3 — Aggregate failures

For each failure, classify:
- **Critical (🔴)**: regression baseline scenario failed (architectural invariant broken) OR happy-path step in a per-spec smoke failed
- **Medium (🟡)**: failure-path step asserted wrong outcome
- **Low (🟢)**: edge-case scenario failed

Group failures by smoke file. For each group, file a bug report at `[bugs_dir]/bug-smoke-all-<date>-<short-name>.md` using `workflow/templates/bug-template.md`. Reuse existing bugs (don't duplicate) by checking `[bugs_dir]/` for matching `Spec` + step IDs already 🟦 Open.

---

## Step 4 — Summary output

```
🧪 /smoke-all results — <date>

Total scenarios: <N>
  Passed: <N>
  Failed: <N>
    🔴 Critical: <N>
    🟡 Medium:   <N>
    🟢 Low:      <N>

Regression baselines:
  ✅ <baseline> — <N>/N pass
  ❌ <baseline> — <N>/N pass — see bug-smoke-all-<date>-<name>.md

Per-spec smokes:
  ✅ <spec> — clean
  ❌ <spec> — <N> failures — see bug-smoke-all-<date>-<name>.md

Bug reports filed: <N> at [bugs_dir]/

Decision:
  - All clean → safe to /ship if you want
  - Failures present → consider running /spec-smoke-and-fix or /bug-fix on failing specs before /ship. Your call — /ship does NOT auto-block.
```

---

## Step 5 — Exit status

If any failure: exit non-zero (signal only — useful if scripted, but no skill auto-reads this).

If all pass: exit 0.
