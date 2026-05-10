# Architecture

> Defined during project-init-new Phase 3, written verbatim by project-init-write. Updated only via decision-sync when a new DEC introduces structural change. Every change here MUST link to a DEC entry.

Each section answers: **What we chose / Why / Rejected alternatives / Implications / Triggers re-evaluation.**

## 1. System purpose & design intent
> One paragraph. Problem solved, what optimized for, what deliberately not done.

## 2. Domain model
> Entities + relationships. Diagram or list.

## 3. Layered architecture
> Layers (presentation/state/persistence/data/external). Import direction. What each layer owns. What it must not own.

## 4. State model
> Where state lives. Propagation. Ownership. Single-source-of-truth claims.
> What / Why / Rejected / Implications / Triggers re-eval.

## 5. Navigation model
> Route tree. Transitions. Deep links. Modal stack. Typed-route posture.

## 6. Persistence model
> Storage layers. Schema versioning. Migration. Atomicity. Failure recovery.

## 7. Render model (UI projects)
> Component hierarchy. Design system source-of-truth. Theming. Asset pipeline. Animation policy.

## 8. Performance & scale posture
> Budgets (frame rate, bundle, cold start). Virtualization rules. Memoization rules. Lazy-load rules.

## 9. Error handling & resilience
> Boundaries. Toast/console/throw policy per layer. Retry. Network-failure UX.

## 10. Boundaries & forbidden imports
> Graph rules. Machine-checkable where possible. Each rule maps to a DEC `verifies` field.

## 11. Build & deploy posture
> Code → app pipeline. Env layers. Release cadence. Rollback.

## 12. External constraints
> Legal/perf/integration. The "why we can't change X" log.

## 13. Open questions / deferred
> Non-decisions. Conditions to reopen.
