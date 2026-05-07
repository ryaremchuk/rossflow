# ctx-{{component-name}}
_Last updated: {{date}} by context-sync_

---

## Purpose
One paragraph: what this component does and why it exists in the system.

---

## Public interface
What other components can call or import from this one. List key functions, endpoints, events, or exports with one-line descriptions.

```
function_or_endpoint — what it does
function_or_endpoint — what it does
```

---

## Internal structure
Key files and what each contains. 2–3 lines per file max.

```
path/to/file  — what it contains or does
path/to/file  — what it contains or does
```

---

## State and data
What data this component owns or mutates. Include schema if relevant (column names and types, not ORM syntax).

```
table_name: column_name type, column_name type
```

---

## Dependencies
What this component depends on — other components, external services, or shared infrastructure.

- `{{component}}` — why this component depends on it
- `{{external-service}}` — what it provides

---

## Known constraints
Decisions or limitations that affect how this component must behave. Reference DECISIONS.md entries by ID.

- DEC-NNN — {{constraint description}}

---

## Recent changes
Append-only. Most recent first.

- {{date}}: {{what changed and why}}
