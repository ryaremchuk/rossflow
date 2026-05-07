---
name: spec-smoke-test
description: Run smoke tests for a spec. Starts orchestrator if needed, executes HTTP/DB/UI steps, creates bug reports for failures, outputs summary.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-config.md`
- `.claude/workflow-infra.md`
- `.claude/workflow-smoke.md`

---

Run smoke tests for: `$ARGUMENTS`

---

## Step 1 — Read files

1. `smoke-tests/$ARGUMENTS.md` — steps to execute
2. `specs/$ARGUMENTS.md` — interface context for diagnosing failures
3. `bugs/template.md` — bug report structure

If `smoke-tests/$ARGUMENTS.md` missing:
```
❌ No smoke test file: smoke-tests/$ARGUMENTS.md
   Run /spec-implement first.
```
Stop.

---

## Step 2 — Ensure [orchestrator] running

Skip this step if `[orchestrator]` is `none`.

```bash
[orchestrator] ps --format json
```

If any service unhealthy → `[orchestrator] up -d`, wait 15s checking every 3s.

If still unhealthy after 15s:
```
❌ [orchestrator] failed. Run: [orchestrator] logs
```
Stop.

---

## Step 3 — Execute steps

### HTTP
```bash
curl -s -w "\n%{http_code}" -X <METHOD> <URL> -H "Content-Type: application/json" -d '<body>'
```
Capture: status code, full response body.

### DB
Use `[db_query_tool]` (with `[db_url]`) to execute the verification SQL. Skip DB steps if `[db_query_tool]` is `none`.
Capture: row count, actual values returned.

### [ui_driver]
Skip if `[ui_driver]` is `none`. Write temp script to `[tmp_script_prefix]$ARGUMENTS-<step>.[ui_script_lang_ext]` using `[ui_script_lang]`, execute.

Mandatory patterns:
```javascript
await page.waitForLoadState('networkidle');
await page.waitForSelector('[data-testid="..."]', { state: 'visible' });
await page.waitForResponse(resp => resp.url().includes('/api/...') && resp.status() === 200);
await expect(page.locator('...')).toBeVisible();
// Never: waitForTimeout
```

On failure → screenshot:
```javascript
await page.screenshot({ path: 'bugs/screenshots/$ARGUMENTS-<step-id>.png', fullPage: true });
```

### Per step record
- Step ID, title, tag, status ✅/❌
- On fail: full request, response, DB state, logs, screenshot path

Capture logs on failure:
```bash
[orchestrator] logs [backend_service] --tail=[log_tail_backend] --timestamps
[orchestrator] logs [frontend_service] --tail=[log_tail_frontend] --timestamps  # if frontend step; skip if [frontend_service] is none
```

---

## Step 4 — Analyze failures, create bug reports

Group by root cause — same broken component = one report.
Downstream steps blocked by a critical failure → note "blocked by <bug-id>", skip separate reports.

Severity:
- 🔴 Critical: happy-path failed | data not persisted | wrong data | order/position/risk | rollback missing
- 🟡 Medium: failure-path wrong | error message bad | partial breakage
- 🟢 Low: cosmetic | wrong label | non-blocking edge case

**Populate all fields:**
Use `bugs/template.md`. Populate all fields including fix hypothesis.
Save to `bugs/bug-$ARGUMENTS-<NN>.md`.

---

## Step 5 — Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Smoke Test — $ARGUMENTS
Steps: <N> | ✅ <N> | ❌ <N>

  S01 — <title> ✅
  S02 — <title> ❌
  S03 — <title> ❌ blocked by S02

Bug reports:
  bugs/bug-$ARGUMENTS-01.md — <title> [🔴]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

All passed → `Next: /context-sync → /ship`
Failures → `Review bug reports in bugs/. Fix manually or run /bug-fix $ARGUMENTS when ready.`
