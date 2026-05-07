> Values in [brackets] are read from `.claude/workflow-infra.md` and `.claude/workflow-smoke.md` at runtime.

# Smoke Test — {{spec-name}}
_Generated: {{date}}_
_Spec: specs/{{spec-name}}.md_

---

## Environment

- Backend:  http://localhost:[backend_port]
- Frontend: http://localhost:[frontend_port]  <!-- omit if [frontend_lang] is none -->
- DB:       [db_url]

---

## Prerequisites

<!-- DB state or data required before tests run. Be explicit. -->
<!-- Examples: -->
<!--   - Clean slate — no imports for BTC/USDT 1h must exist -->
<!--   - At least 100 rows of BTC/USDT 1h data must exist in ohlcv table -->
<!--   - No open positions in positions table -->

---

## Steps

<!-- Each step follows this structure. Repeat for every step. -->
<!-- Tags: happy-path | failure-path | edge-case -->
<!-- Type: HTTP | [ui_driver] | DB -->

### S01 — {{short title}} [HTTP] [happy-path]

**Action:**
```
POST http://localhost:[backend_port]/api/{{endpoint}}
Body: {
  "field": "value"
}
```

**Expect:**
- HTTP status: 200
- Response: `{"status": "ok", "rows_inserted": <N>}`

**Verify DB:**
```sql
SELECT COUNT(*) FROM {{table}} WHERE {{condition}};
-- Expected: > 0
```

---

### S02 — {{short title}} [HTTP] [failure-path]

**Action:**
```
POST http://localhost:[backend_port]/api/{{endpoint}}
Body: {
  "field": "invalid_value"
}
```

**Expect:**
- HTTP status: 200
- Response: `{"status": "failed", "error": "<non-null string>"}`

**Verify DB:**
```sql
SELECT COUNT(*) FROM {{table}} WHERE {{condition}};
-- Expected: 0 (no rows inserted on failure)
```

---

### S03 — {{short title}} [[ui_driver]] [happy-path]

<!-- [ui_driver] step — adapt syntax to your chosen driver. Skip if [ui_driver] is none. -->

**Action:** [describe the UI action — e.g. navigate to route, fill form field, click submit]

**Assert:** [describe what to verify — e.g. success element visible, text matches expected value]

---

### S04 — {{short title}} [[ui_driver]] [failure-path]

<!-- [ui_driver] step — adapt syntax to your chosen driver. Skip if [ui_driver] is none. -->

**Action:** [describe the UI action that triggers failure]

**Assert:** [describe what to verify — e.g. error element visible, success element absent]

---

### S05 — {{short title}} [DB] [edge-case]

<!-- DB step. Skip if [db_type] is none. -->

**Action:**
```sql
{{setup SQL if needed}}
```
Then trigger: `{{HTTP call or action}}`

**Verify DB:**
```sql
{{verification SQL}};
-- Expected: {{exact expected result}}
```
