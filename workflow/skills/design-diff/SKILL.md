---
name: design-diff
description: Compare a new design source drop vs existing extracted state. Emits delta report and proposes patch specs. Routes to decision-sync for DEC entries on accepted changes.
---

## Inputs
- New design source folder path (e.g. `claude-design-source-v2/`)
- Existing `docs/DESIGN-SYSTEM.md`, `docs/COMPONENT-LIBRARY.md`, `.rossflow/design-source-index.json`, `.rossflow/design-tokens.json`

## Step 1 — Run extraction on new source
Invoke `design-source-extract` with new path → output to `.rossflow/_diff/`.

## Step 2 — Compare
For each artifact, compute diff:
- **Tokens:** added / removed / changed.
- **Screens:** added / removed / changed (sub-classify: trivial=label-or-color-only vs structural=new-section-or-component).
- **Components:** added / removed / changed library proposals.
- **Assets:** added / removed / renamed / changed (same name, different content hash).

## Step 3 — Delta report
Output `.rossflow/_diff/DESIGN-DIFF.md`:

```
# Design diff — <date>
## Token changes
| Token | Old | New | Status |
## Screen changes
| Screen | Status | Sub-class | Affected sections |
## Component changes
| Component | Status | Affected screens |
## Asset changes
| Asset | Status | Affected screens |
## Recommended actions
- Token change → DEC supersession.
- Structural screen change → patch spec spec-NNN-<name>-redesign.
- Component change → updates to spec-001/spec-002 + downstream screens.
- Asset change → assets/ update + lookup refresh.
```

## Step 4 — Approval

```
Found <N> token / <N> screen / <N> component / <N> asset changes.
Proposed: <X> DECs, <Y> patch specs, <Z> updates.
Apply which? (all / list / skip / stop)
```

⛔ STOP. Independent approval gate.

## Step 5 — Apply
On approval:
- Move `.rossflow/_diff/*` to live (overwrite `design-source-index.json`, `design-tokens.json`).
- Update `docs/DESIGN-SYSTEM.md`, `docs/COMPONENT-LIBRARY.md`.
- Generate proposed patch specs as drafts in `specs/proposed/spec-NNN-*.md` (user runs `/spec-create` to formalize).
- Append DEC entries (with `Supersedes: DEC-XXX` if relevant).
- Old design source folder coexists for forensic. Do NOT delete.

Recompute frontmatter on all updated docs.

## Step 6 — Output

```
✅ design-diff applied
- DECs added: [list]
- Patch specs proposed: [list]
- Tokens applied: <N>
- Screens refreshed: <N>
Next: review specs/proposed/, formalize via /spec-create.
```
