---
name: doc-check
description: On-demand AI semantic comparison between a component's source code and its README. Outputs aligned/stale/missing/dead findings, proposes patch, gates approval, updates frontmatter. Use when tier-1 hash flags drift OR user invokes `/doc-check <component>`.
---

## Inputs
- `<component>`: directory name, file path, or component identifier.

## Step 1 — Resolve
Resolve `<component>` to:
- Directory path (e.g. `src/store/`).
- README at `<dir>/README.md`.
- Source file glob (from README frontmatter `sources`, or default `<dir>/**/*`).

If README missing: offer to scaffold from `workflow/templates/component-readme.md` with empty content.

## Step 2 — Read
- README full text.
- Every source file in `sources` glob.
- DECISIONS.md entries mentioning this component (grep).
- Bug reports under `bugs/` referencing it.

## Step 3 — Semantic comparison
For each claim in README: verify against source. Mark `aligned` / `stale` / `dead`.
For each significant behavior in source: cross-reference. Mark `missing` if non-obvious + undocumented.

**Content rule (CRITICAL):** "non-obvious only." Do NOT mark as `missing` if behavior is derivable from reading source in 30 seconds (signatures, prop types, file structure). Only flag truly non-obvious behavior contracts, footguns, cross-module contracts, perf constraints.

## Step 4 — Propose patch
Unified diff against existing README:

```
=== Removals (stale / dead) ===
- <line>
=== Additions (missing non-obvious) ===
+ <new section>
=== Reorganizations ===
~ <changed section>
```

Include source file references for additions (e.g. `see src/store/useUser.ts:awardGems`).

## Step 5 — Approval

```
README review for <component>:
Aligned: <N> | Stale: <N> | Missing: <N> | Dead: <N>
Apply patch? (yes / edit / skip / mark-intentionally-stale)
```

⛔ STOP. Independent approval gate.

## Step 6 — Apply
On approval:
- Write patched README.
- Update frontmatter: `synced_at_sha = git rev-parse HEAD`, `synced_at_hash = sha256 of concat sorted sources`, `last_ai_review = today`.

If `mark-intentionally-stale`: write frontmatter `intentionally_stale_until: <reason>`. Skip update.

## Step 7 — Output

```
✅ doc-check complete: <component>
Patch applied: <yes/no>
Frontmatter updated: <yes/no>
```
