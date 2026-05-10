---
name: ui-fidelity-check
description: Visual + structural fidelity check vs design source HTML mockup. Runs token AST audit, asset audit, label/numeric audit, screenshot diff (pixelmatch/odiff). Files bug reports for failures. Invoked by screen-implement and spec-smoke-test for type=screen specs.
---

## Inputs
- Screen route
- Source HTML mockup path
- `design-source-index.json` entry for this screen

## Step 1 — Token AST audit
AST-grep / eslint over screen file(s):
- Forbidden: `#[0-9a-fA-F]{3,8}` literal in style positions (must be `Colors.X`).
- Forbidden: numeric literal in `padding`/`margin`/`gap`/`borderRadius` (must be `Spacing.X`/`Radius.X`).
- Forbidden: `fontSize: <literal>`, `fontWeight: '500'|'700'` literals.
Output violations as bug entries. Continue regardless.

## Step 2 — Asset presence audit
For every asset in `design-source-index.json[screen].assets_referenced`:
- Grep screen file for path/constant. Missing → bug.
For every asset rendered: confirm exists on disk. Bundled but unreferenced → warning.

## Step 3 — Text-label audit
Render screen via Maestro/Playwright. Capture all `<Text>` children.
Bag-of-words match against expected labels. Missing → bug.

## Step 4 — Numeric-value audit
For every value in `numeric_values`: match rendered output. Allow ±5% for animated. Mismatch → bug.

## Step 5 — Screenshot diff
1. Render source HTML headlessly at fixed viewport (390×844 iPhone-12). Save `<.rossflow/baselines/<screen>.png>`. Skip if baseline exists.
2. Run app via Maestro/Playwright same viewport. Take screenshot.
3. Run pixel diff (pixelmatch or odiff). Default threshold ≤5% delta.
4. > threshold → bug with side-by-side image attached.

## Step 6 — Output
```
✅ ui-fidelity-check passed
OR
❌ failed:
- Token violations: <N>
- Asset issues: <N>
- Missing labels: <N>
- Numeric mismatches: <N>
- Pixel delta: <%>
Bug reports: [list]
```
Failures → exit non-zero; caller routes to bug-fix.

## Notes
- Bootstrap deps once if missing: `npm i -D pixelmatch pngjs` or equivalent.
- Baselines under `.rossflow/baselines/`. Re-run with `--rebaseline <screen>` after intentional design changes (must pair with DEC).
- Threshold per screen via `.rossflow/fidelity-config.json`.
