---
sources:
  - claude-design-source/**/*.html
  - claude-design-source/**/*.jsx
synced_at_sha: <git sha>
synced_at_hash: <sha256>
last_ai_review: <date>
---

# Component Library

> Reusable components extracted from design source. Specs MUST consume; specs MUST NOT inline duplicates.

| Name | Variants | Props (key) | Source mockup | Implements in spec |

## Usage rules
- Every screen spec must list which library components it consumes.
- New components proposed by a spec must first be added here with user approval, then implemented in spec-001 (primitives) or spec-002 (composites).
- A component is library-worthy if it appears in ≥2 screens or has ≥2 variants.
