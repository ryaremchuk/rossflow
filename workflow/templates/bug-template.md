> Values in [brackets] are read from `.claude/workflow-infra.md` at runtime.

# Bug Report — {{spec-name}} — {{short title}}
_Created: {{date}}_
_Spec: specs/{{spec-name}}.md_
_Smoke test step(s): {{S01, S02}}_
_Status: ⬜ Open_

---

## Severity
🔴 Critical / 🟡 Medium / 🟢 Low — {{one line reason}}

---

## What failed
{{One paragraph. What the test did, what went wrong. Plain English.}}

---

## Expected vs Actual

| | Expected | Actual |
|---|---|---|
| HTTP status | {{200}} | {{500}} |
| Response body | `{{expected json}}` | `{{actual json}}` |
| DB rows | {{> 0}} | {{0}} |
| UI state | {{visible / hidden}} | {{actual state}} |

---

## Request
```
{{METHOD}} {{URL}}
Headers: {{relevant headers}}
Body: {{full request body}}
```

---

## Response
```
Status: {{code}}
Body: {{full response JSON}}
```

---

## Logs at failure moment
```
{{[orchestrator] logs [backend_service] --tail=[log_tail_backend] --timestamps output}}
```

{{If [frontend_service] involved:}}
```
{{[orchestrator] logs [frontend_service] --tail=[log_tail_frontend] --timestamps output}}
```

<!-- Add equivalent log blocks for any additional services defined in workflow-infra.md beyond backend and frontend. -->

---

## DB state snapshot
<!-- Skip if [db_type] is none. -->
```sql
-- Query:
{{SQL run to verify state}}

-- Result:
{{actual rows returned}}
```

---

## Screenshot
{{`bugs/screenshots/{{spec-name}}-{{step-id}}.png` | N/A — HTTP step}}

---

## Likely files involved
- `{{module/path/file}}` — {{why likely relevant}}
- `{{module/path/file}}` — {{why likely relevant}}

---

## Fix context
{{Technical hypothesis about root cause based on logs, response, and DB state.
What Claude Code believes is broken and why.}}

---

## Reproduction steps
1. Ensure [orchestrator] is running: `[orchestrator] up -d` (skip if [orchestrator] is none)
2. {{exact curl command or browser action}}
3. {{what to observe}}
