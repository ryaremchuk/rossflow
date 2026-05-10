## v0.7.0 — 2026-05-10

Patterns + injection cleanup. Skill hygiene.

### Patterns subsystem
- Renamed framework index: `workflow/patterns/PATTERNS.md` → `workflow/patterns/INDEX.md`. Removes name collision with project's `docs/PATTERNS.md`.
- Deleted `workflow/docs-templates/PATTERNS.md`. Project's `docs/PATTERNS.md` is now generated inline by `project-init-write` from `patterns_include`. One source of truth.
- State management restructured: `state-management.md` is now library-agnostic principles only. Added `state-redux-toolkit.md` and `state-zustand.md`. `project-init-new` Phase 4 asks which library when frontend has React/RN.
- Renamed `asyncstorage.md` → `client-persistence.md`. Generalized to KV / secure / structured / filesystem with adapter examples (AsyncStorage, MMKV, SecureStore, SQLite). Auto-included for RN; ask for non-RN client storage.
- Trimmed `principles.md` to 145 lines (was 254). All 10 rules + 4 anti-patterns + hard caps preserved.

### CLAUDE.md injection scope
- `workflow-init` now injects ONLY the `workflow-instructions.md` reference into `CLAUDE.md`. The 4 config files (`workflow-config`, `workflow-git`, `workflow-infra`, `workflow-smoke`) live at their paths and are loaded on-demand by skills — not inlined every turn.
- Added "Project config files" section to `workflow-instructions.md` listing the four paths and what each carries.

### MAP.md auto-generation
- `docs/MAP.md` is now marked GENERATED. `decision-sync` regenerates it from `find src -name README.md` on every sync.
- Stop hand-editing MAP.md. To add a row, create the component README, then run `/decision-sync`.

### Skill hygiene
- `spec-smoke-and-fix` rewritten as a thin orchestrator that **invokes** `/spec-smoke-test` (no longer recites its steps). Subagent prompt extracted to `workflow/skills/spec-smoke-and-fix/subagent-prompt.md`. Bug classification stays in `/bug-fix`. Down 33 lines.
- `decision-verify` clarified: auto-invoked by `/spec-create` Step 0 as a pre-spec gate. Cheap when no DEC has a `Verifies:` block. Also runnable manually after refactors / before `/ship`.
- `project-init-new` trimmed 422 → 349 lines; `project-init-write` trimmed 240 → 164 lines. All approval gates, write order, and validation rules preserved.
- `workflow-instructions.md` skill table now lists `/decision-verify` (was missing) and notes `decision-sync` regenerates `MAP.md`.

### Migration notes (existing rossflow projects on v0.6.0)
- Existing `docs/patterns/PATTERNS.md` files keep working as-is. New projects get `docs/patterns/INDEX.md` instead. If you want to rename in-place: `mv docs/patterns/PATTERNS.md docs/patterns/INDEX.md`.
- Existing `asyncstorage.md` files keep working. New projects get `client-persistence.md`. To migrate: `mv docs/patterns/asyncstorage.md docs/patterns/client-persistence.md` and replace its contents with the new file from `workflow/patterns/`.
- Existing `MAP.md` files: add the GENERATED banner once, then let `decision-sync` take over. Manual edits will be overwritten on next sync.
- Re-run `/workflow-init` is safe — it skips files that already exist.

## v0.6.0 — 2026-05-10
- v2: design-source-first workflow + UI-fidelity infrastructure
- New skills: design-source-extract, screen-implement, ui-fidelity-check, design-diff, doc-check, decision-verify
- Renamed: context-sync → decision-sync
- Deleted: workflow/templates/ctx-template.md (deprecated)
- Templates: ARCHITECTURE/DECISIONS/PATTERNS/MAP/DESIGN-SYSTEM/COMPONENT-LIBRARY/screen-spec/component-readme rewritten
- Patterns: typescript, asyncstorage, state-management added; principles + reactnative augmented with hard caps
- workflow-instructions.md: approval-gate independence rule
- /simplify: now uses Claude Code built-in (no custom skill)
