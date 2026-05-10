---
type: screen
design_source: <path to HTML mockup>
---

# Spec: <screen name>

## Depends on
## Goal
## Not in scope
## Assumptions

## DEC alignment
> List DEC-NNN this spec assumes. MUST NOT contradict any.

## Components consumed
> From COMPONENT-LIBRARY.md. MUST NOT inline a library component.

## Visual acceptance
> AUTOFILLED by design-source-extract from `design_source`.

### Layout tree
### Exact text labels
### Exact numeric values
### Token usage
> Machine-checkable: list Colors.X / Spacing.Y / Typography.Z this screen MUST use.
### Asset list
> Every PNG/SVG + intended position.
### Animations
> Name + duration + easing.

## Behaviour
## Failure paths
## Files
## Tests

## Done when
- [ ] Token usage matches Visual Acceptance.
- [ ] No inline `#hex`; only `Colors.*`.
- [ ] All listed components consumed; no inline library duplicates.
- [ ] Smoke test passes.
- [ ] ui-fidelity-check passes (≤5% pixel delta).
- [ ] Asset list 100% present, 0% silent drops.
