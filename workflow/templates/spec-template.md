> Values in [brackets] are read from `.claude/workflow-config.md` at runtime.

# Spec: [Feature Name]
**Phase:** X | **Order:** X-XX | **File:** `specs/spec-phaseX-XX-feature-name.md`

---

## Depends on
- `spec-phaseX-XX-name` — [what it provides]

---

## Goal
[2–4 sentences. What is being built and why it matters to the system.]

---

## Not in scope
- [item] — covered in spec X-XX
- [item] — Phase N

---

## Assumptions
- [what already exists in the codebase or environment]

---

## Contracts

<!-- ⚠️  SIGNATURES AND TYPES ONLY. No function bodies, no implementation logic, no ...  -->
<!-- ⚠️  If you are writing more than a signature + docstring, you are doing it wrong.  -->
<!-- ⚠️  Wrong:  function fetch(...) {             -->
<!--                 return db.query(...)          -->
<!--             }                                 -->
<!-- ⚠️  Right:  function fetch(...): ReturnType   -->

```
# [backend_lang] — signatures only
[backend_lang] function signature: function_name(arg: Type) -> ReturnType
```

```
// [frontend_lang] — types and interfaces only (omit block if [frontend_lang] is none)
[frontend_lang] type definition: ResponseShape { field: string; status: "ok" | "failed" }
```

**API shapes** (if applicable):
```
POST /api/endpoint
Body:     { field: type }
Response: { status: "ok" | "failed", error: string | null }
```

**DB models** (if applicable — column names and types only):
```
table_name: column_name type, column_name type
```

---

## Behaviour
<!-- What the system does, in plain steps. No code. Reference DEC-XXX where applicable. -->

1. [First thing that happens]
2. [Second thing]
3. [What happens on the happy path]

**Rules:**
- [Invariant — reference DEC-XXX if applicable]
- [Edge case and how it is handled]

---

## Failure paths

<!-- Every external I/O must have at least one failure path defined. -->
<!-- Format: trigger → expected system behaviour -->

- [exchange API timeout] → [status: "failed", error: "timeout", 0 rows written, transaction rolled back]
- [malformed input] → [status: "failed", error: "parse_error", no side effects]
- [DB unavailable] → [status: "failed", error: "db_error", transaction rolled back]

---

## Files
```
[backend_dir]/path/to/file             — [what it contains]
[backend_dir]/tests/unit/path/test_file — [what it tests]
```

---

## Tests
- `test_name` — [trigger/input] → [expected output]
- `test_name` — [trigger/input] → [expected output]
- `test_failure_name` — [failure trigger] → [expected error behaviour]

---

## Done when
- [ ] `[backend_dir]/path/to/file` created with [specific thing]
- [ ] All N tests pass
- [ ] `[typecheck_cmd]` — no errors
- [ ] `[lint_cmd]` — no errors
- [ ] [happy path command] → expected: [output]
- [ ] [failure path command] → expected: [error output, not success]
