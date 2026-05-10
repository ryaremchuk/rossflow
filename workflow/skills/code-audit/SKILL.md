---
name: code-audit
description: Run SAST + LLM diff scan to surface tech debt, code smells, and security issues. Aggregates by module, drafts refactor spec stubs. Manual trigger every 5–10 specs. Replaces grep-based DEBT-marker aggregation.
---

## Config

Read the following files before executing this skill.

- `.claude/workflow-config.md` — for `sast_cmd`, `backend_dir`, `frontend_dir`, `test_dir`, LOC caps
- `.claude/workflow-git.md` — for `main_branch` (used as diff base)
- `docs/PATTERNS.md` — to know what the project explicitly accepts (do not flag accepted patterns)

---

Audit code health. Manual trigger. Run every 5–10 specs.

⛔ NO FILES WRITTEN until Step 5. Steps 0–4 are read and output only.

---

## Step 0 — Determine scope

Default scope: all source under `[backend_dir]` and `[frontend_dir]` (skip if `none`).

If `$ARGUMENTS` provided: limit to that path or module.

Determine diff base: `[main_branch]`. The "recent diff" is `git diff [main_branch]...HEAD --name-only` for the LLM scan (focused on what's changed); SAST runs across full scope.

---

## Step 1 — SAST pass

If `sast_cmd` is `none` in `.claude/workflow-config.md` → skip this step, output: `SAST: skipped (sast_cmd=none). Falling back to LLM-only scan.`

Else run:
```bash
[sast_cmd]   # with {files} replaced by scope from Step 0
```

Capture findings. Group by:
- **Severity**: critical / high / medium / low (per SAST tool's classification)
- **Category**: security / correctness / style / complexity
- **Module**: top-level dir under `[backend_dir]` / `[frontend_dir]`

Discard findings that match patterns explicitly accepted in `docs/PATTERNS.md` (e.g., if project allows certain `eval` usage in a sandboxed module, don't flag it).

---

## Step 2 — LLM diff scan

Read recent diff: `git diff [main_branch]...HEAD`.

Scan diff hunks for:
- **God functions / files**: function or file exceeds project LOC cap from PATTERNS.md (or 200 LOC default if not specified)
- **Duplication**: near-identical blocks across files
- **Leaky abstractions**: layer boundaries crossed inappropriately (cite ARCHITECTURE.md §10 if applicable)
- **Missing error paths**: external I/O calls without explicit error handling
- **Complex conditionals**: nesting > 3, cyclomatic complexity high
- **Stale code**: dead branches, unreachable code, commented-out blocks
- **Inconsistent naming**: same concept named differently across files
- **`DEBT[...]` markers**: still aggregate these from diff and full-scope grep as one signal among many

For each finding, capture: file:line, category, severity (your judgment: critical / high / medium / low), one-paragraph explanation, suggested remedy.

---

## Step 3 — Aggregate by module

Combine SAST + LLM findings. For each top-level module:
- Count findings by severity
- Compute frequency × severity score
- Identify top 3 issues

Sort modules by score desc.

---

## Step 4 — Output report + propose stubs

Write report to memory (NOT yet to disk). Show user:

```
🔍 Code Audit Report — <date>
Scope: <files scanned count>
SAST findings: <N> (<critical>/<high>/<medium>/<low>)
LLM findings: <N> (<critical>/<high>/<medium>/<low>)

## Top modules by debt score

### 1. <module> — score X
- 🔴 <finding> @ file:line — <one-line>
- 🟡 <finding> @ file:line — <one-line>
- 🟢 <finding> @ file:line — <one-line>
Proposed refactor spec: refactor-<module>-<short-name>
Estimated effort: <S/M/L>

### 2. <module> — score Y
...

## Quick wins (single-file, low-risk fixes)
- <file:line> — <one-line> — <suggested fix>
- ...

## Critical (security or correctness — fix this iteration)
- <file:line> — <description> — <severity rationale>
```

Then output:

```
👤 **Action needed:**
For each proposed refactor spec, choose:
- "draft <name>" → I generate a refactor spec stub via spec-template.md (saved to specs/proposed/)
- "skip <name>" → log as deferred in audit report only
- "draft all" / "skip all" → batch action

For critical findings, decide:
- "fix now" → I propose a hotfix spec drafted immediately
- "track" → log without immediate action
```

⛔ STOP. Wait for user direction.

---

## Step 5 — Write artifacts

✅ FILES WRITTEN HERE.

1. `[docs_dir]/code-audit-<YYYY-MM-DD>.md` — full report (always written, even if user skips all stubs).
2. For each "draft <name>" the user approved:
   - Generate spec stub at `specs/proposed/refactor-<module>-<name>.md` using `workflow/templates/spec-template.md`. Pre-fill: goal (refactor X), out-of-scope, contracts (inferred from current code shape), files (the affected ones), tests (what must keep working).
   - User formalizes the stub via `/spec-create specs/proposed/refactor-<module>-<name>.md` later.
3. For each "fix now" critical finding: generate hotfix stub at `specs/proposed/hotfix-<short-name>.md` similarly.

---

## Step 6 — Output

```
✅ [docs_dir]/code-audit-<YYYY-MM-DD>.md written
✅ <N> refactor stubs in specs/proposed/
✅ <N> hotfix stubs in specs/proposed/
⚠️ <N> findings deferred (not stubbed)

Next:
- For each stub: /spec-create specs/proposed/<filename>
- Re-run /code-audit after next 5–10 specs to track trend
```
