---
name: screen-implement
description: Implement a UI screen spec. Variant of spec-implement that enforces design-fidelity. Reads DESIGN-SYSTEM.md, COMPONENT-LIBRARY.md, design-source-index.json before plan; rejects inline duplicates; auto-runs ui-fidelity-check at end. Routed to from spec-implement when spec has `type: screen`.
---

## Step 1 — Read
Inherit spec-implement Step 1 reads, plus:
- `docs/DESIGN-SYSTEM.md` (full)
- `docs/COMPONENT-LIBRARY.md` (full)
- `.rossflow/design-source-index.json` — entry for this screen
- HTML mockup file from spec frontmatter `design_source`

## Step 2 — Plan + design-fidelity gate
Extends spec-implement Step 2:
- **Components consumed:** reuse ratio MUST be ≥0.6 (60%).
- **Tokens used:** every Colors/Spacing/Typography/Radius/Shadow/Animation reference. Cross-check `design-tokens.json` — unknown token → propose addition or stop.
- **Asset list:** every PNG/SVG. Cross-check `design-source-index.json[screen].assets_referenced` — list MUST be a superset (no silent drops). Missing → bug.
- **Visual contract:** `design-source-index.json[screen]` verbatim becomes acceptance.

👤 Action needed: independent approval gate.

## Step 3 — Implement
Rules (enforce in plan + verify post-impl):
- Tokens only via `Colors.X` / `Spacing.X` etc. No inline literals.
- Components only via `import { X } from 'src/components/...'`. Inline JSX for COMPONENT-LIBRARY entries is rejected.
- FlatList for lists >10 items.
- `useSafeAreaInsets()` for top/bottom padding.
- Subscribe to shared state via `useStore()`.

## Step 4 — Verify + simplify
Per spec-implement. Auto-invoke `simplify` per LOC/complexity caps.

## Step 5 — UI fidelity check
Auto-invoke `ui-fidelity-check` with: built screen route, source HTML mockup, design-source-index entry.
Failures → file bugs with `type: ui-fidelity`, route to bug-fix.

## Step 6 — Smoke test (per spec-implement)
## Step 7 — Context update (per spec-implement)
## Step 8 — Done
```
✅ screen-implement complete
Components reused: <N> (<ratio>%)
Tokens used: <N>
Assets rendered: <N>/<expected>
ui-fidelity pixel delta: <%>
Smoke: <status>
Next: /spec-smoke-test $ARGUMENTS
```
