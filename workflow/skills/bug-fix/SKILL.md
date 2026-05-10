---
name: bug-fix
description: Fix open bugs for a spec. Reads bug reports, fixes in severity order, re-runs failed steps to verify. Max 3 attempts per bug. Updates bug reports with outcome.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-config.md`
- `.claude/workflow-infra.md`

---

Fix bugs for: `$ARGUMENTS`

Max attempts per bug: **3**

---

## Step 1 — Read context

1. All `bugs/bug-$ARGUMENTS-*.md` with status ⬜ Open
2. `specs/$ARGUMENTS.md` — contracts (must not be violated)
3. `docs/MAP.md` → load relevant component READMEs / docs for this spec

Check if `smoke-tests/$ARGUMENTS.md` exists — note for Step 2c.

Classify bug type before fixing:

| Type | Behavior |
|------|----------|
| `runtime` | Standard fix in code; existing flow. |
| `ui-fidelity` | Cross-check against design-source-index.json. Fix MUST restore visual contract; verify with `ui-fidelity-check` after. |
| `architecture-violation` | Spec implementation contradicts a DEC. Route to `decision-sync` to either fix code or supersede DEC. NEVER patch symptom in place. |
| `contract-change` | Existing flow: stop, escalate. |

Bug type MUST be set in the bug-fix attempt log.

No open bugs found:
```
✅ No open bugs for $ARGUMENTS.
   Run /spec-smoke-test $ARGUMENTS to verify.
```
Stop.

Otherwise:
```
📋 <N> open bug(s):
   bugs/bug-$ARGUMENTS-01.md — <title> [🔴/🟡/🟢]

Smoke test file: [found | not found — using bug report steps]
Fixing: Critical → Medium → Low
```

---

## Step 2 — Fix each bug

Order: 🔴 → 🟡 → 🟢

### 2a — Analyze

Read bug report fully. Form fix plan:
```
🔧 bugs/bug-$ARGUMENTS-<NN>.md — <title>

Root cause: <one sentence>
Files: <list>
Approach: <one paragraph>
Verify via: [smoke test step <S0X> | bug report steps]
```

**Contract check:** if fix requires changing public interface, DB schema, or behavior another spec depends on:
```
⛔ Spec contract change required.
What: <description>
Contract: <interface/endpoint/schema>
Affected specs: <list>
Bring to Claude.ai. Do not fix until approved.
```
Stop. Wait for user.

### 2b — Apply fix

Minimal change only. No refactor, no scope creep.
After each [backend_lang] file: `[typecheck_cmd]` + `[lint_cmd]`. After each [frontend_lang] file: `[frontend_typecheck_cmd]` (skip if `none`).

### 2c — Verify

Ensure [orchestrator] running (skip if `[orchestrator]` is `none`): `[orchestrator] ps --format json`
If unhealthy → `[orchestrator] up -d`, wait 15s.

If `smoke-tests/$ARGUMENTS.md` exists → re-run specific failed step(s) from bug report.
If not → execute bug report's reproduction steps exactly.

- Pass → go to 2d
- Fail, attempts < 3 → revise, retry from 2a
- Fail, attempts == 3 → escalate (2e)

### 2d — Mark fixed

Update bug report: status `✅ Fixed`, add:
```markdown
## Fix applied
Attempts: <N>
Verified via: [smoke test <S0X> | reproduction steps]

### Changes
- `<file>` — <description>

### Verification
✅ PASS
```

### 2e — Escalate

Update bug report: status `⚠️ Escalated`, add:
```markdown
## Exhausted
Attempts: 3

### Tried
1: <what + why failed>
2: <what + why failed>
3: <what + why failed>

### Hypothesis
<best current root cause understanding>

### Suspected issue
<why may need spec review or architectural change>
```

Output:
```
⚠️ bugs/bug-$ARGUMENTS-<NN>.md — could not fix after 3 attempts.

Hypothesis: <one sentence>

Options:
  a) Give more context, I'll retry
  b) Claude.ai Deep Spec Dive if design issue
  c) Skip — run /spec-smoke-test to see remaining failures
```
Wait for response before next bug.

---

## Step 3 — Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Bug Fix — $ARGUMENTS
✅ Fixed: <N> | ⚠️ Escalated: <N> | Total: <N>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

All fixed → `Next: /spec-smoke-test $ARGUMENTS`
Escalated → `Resolve escalated bugs before /decision-sync or /ship`
