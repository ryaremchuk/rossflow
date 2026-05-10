---
name: design-source-extract
description: Parse a design-source folder (HTML mockups, CSS tokens, JSX, system MD/PDF, assets) into machine-readable artifacts (DESIGN-SYSTEM.md, COMPONENT-LIBRARY.md, design-source-index.json, design-tokens.json). Invoked by project-init-new Phase 2.5 and design-diff.
---

## Inputs
- Design source folder path
- Existing `docs/DESIGN-SYSTEM.md` if present (for re-runs)

## Step 1 — Inventory
Walk folder. Categorize: HTML mockups, CSS/token files, JSX scripts, frame/shell, system docs (.md/.pdf in `uploads/` or root), asset folders.
Output manifest. ⛔ Approval gate before extraction.

## Step 2 — Extract design tokens
Parse CSS for: custom properties, color values, typography clusters, spacing/radius/shadow scales, @keyframes.
If system MD/PDF present, parse for explicit token names; system doc names take precedence.
Output `<project_root>/.rossflow/design-tokens.json`:
```json
{
  "colors": { "purple.deep": "#534AB7" },
  "typography": { "title": { "size": 30, "weight": 700, "family": "SF Pro Display" } },
  "spacing": { "xs": 4, "sm": 8, "md": 16, "lg": 24 },
  "radius": { "sm": 6, "md": 12, "lg": 20 },
  "shadow": { "card": "0 2px 8px rgba(0,0,0,0.2)" },
  "animation": { "pulse-amber": { "duration": "2.5s", "easing": "ease-in-out" } }
}
```

## Step 3 — Per-screen index
For each HTML mockup, parse DOM. Output entry:
```json
{
  "screen": "Home",
  "source_html": "claude-design-source/Home.html",
  "viewport": { "width": 390, "height": 844 },
  "layout_tree": [...],
  "text_labels": [...],
  "numeric_values": [...],
  "tokens_used": [...],
  "assets_referenced": [...],
  "components_observed": [...],
  "animations_referenced": [...]
}
```
Compose `<project_root>/.rossflow/design-source-index.json` keyed by screen name.

## Step 4 — Component library proposals
Cross-reference `components_observed` across screens. Pattern in ≥2 screens or ≥2 variants = library-worthy.
Heuristic: single-element (button/badge/pill) → primitives → spec-001. Multi-element (modal/card/scaffold) → composites → spec-002.
For each: name (PascalCase), variants, props, source mockups, target spec.

## Step 5 — Asset audit
Every asset under `assets/**`: note category, check if referenced. Unreferenced → `status: orphan`.
Every asset reference: check existence. Missing → `status: missing`.

## Step 6 — Write artifacts
1. `<project_root>/.rossflow/design-source-index.json`
2. `<project_root>/.rossflow/design-tokens.json`
3. `docs/DESIGN-SYSTEM.md` populated from template
4. `docs/COMPONENT-LIBRARY.md` populated from template

Compute frontmatter on docs: `sources` glob, `synced_at_sha = git rev-parse HEAD`, `synced_at_hash = sha256 of concatenated sorted source files`, `last_ai_review = today`.

## Step 7 — Output summary
```
✅ design-source-extract complete
Tokens: <N> colors, <N> typography, <N> spacing, <N> radius, <N> shadow, <N> animation
Screens indexed: <N>
Components proposed: <N> (<P> primitives, <C> composites)
Assets: <N> total, <N> referenced, <N> orphan, <N> missing
Files written: [list]
⚠️ Issues: <orphan/missing assets, system-doc rules not encoded>
Next: review docs/COMPONENT-LIBRARY.md proposals.
```
