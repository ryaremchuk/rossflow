# Decisions

> Append-only ADR log. Never delete or modify. Use `Status: superseded by DEC-NNN` to invalidate.
> Every entry follows the schema below. No table-row decisions.

## DEC-NNN: <one-line title>

**Status:** accepted | proposed | superseded by DEC-XXX
**Date:** YYYY-MM-DD
**Owner:** <person or "team">

**Context:** 1–3 sentences. Forcing function or problem.

**Decision:** 1 sentence.

**Rejected alternatives:**
- <option> — rejected because <reason>

**Consequences:**
- Positive: ...
- Negative: ...
- Neutral: ...

**Affects:** <architectural sections / modules / specs>

**Verifies:** _(strongly preferred — machine-checkable)_
- Rule: <plain-English invariant>
- Check: `<bash command, exit non-zero on violation>`

**Unverifiable:** _(set true only if no machine check possible)_
- Reason: <why review-only>

**Triggers re-evaluation:** <condition to reopen>
