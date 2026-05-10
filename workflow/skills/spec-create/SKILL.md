---
name: spec-create
description: Generate a new spec via conversational discovery. Reads project context, surfaces affected DECs and candidate implementation paths, gets human alignment, then writes contract spec + implementation plan + draft smoke test (3 artifacts).
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-git.md`

---

Generate spec. Input: `$ARGUMENTS`

⛔ NO FILES WRITTEN until Step 8. Steps 0–7 are read and output only.

---

## Step 0 — Verify active decisions

Invoke `/decision-verify`. Cheap when no DEC has a `Verifies:` block.

- If all checks pass (or there are none) → continue to Step 1.
- If any check fails → STOP. Output the failure list and one of these paths:
  - The failing rule reflects code drift → fix the violation, re-run `/decision-verify`, then resume `/spec-create`.
  - The failing rule reflects an outdated decision → run `/decision-sync` to supersede the DEC, then resume.
- Do NOT bypass with `--allow-failures`. New specs MUST NOT be built on top of violated decisions.

---

## Step 1 — Read context

1. `docs/ARCHITECTURE.md` (full)
2. `docs/DECISIONS.md` (full)
3. `docs/COMPONENT-LIBRARY.md` if exists
4. `docs/DESIGN-SYSTEM.md` if exists
5. `.rossflow/design-source-index.json` if exists
6. `docs/PATTERNS.md` (index, then targeted grep)
7. `docs/MAP.md` — module → file mapping
8. Existing specs (for ordering context)
9. `PROGRESS.md` — current phase, next spec number, in-progress specs
10. `specs/spec-template.md`
11. Most recently completed spec in `specs/`

If `$ARGUMENTS` is a path to existing spec (contains `/` or ends `.md`) → read it. It is input only — will be fully regenerated and overwritten at Step 8.

Determine next spec number from PROGRESS.md automatically.

**In-progress overlap scan (for Step 2):** From PROGRESS.md, identify any specs with status 🔄 In progress. For each, read its plan file `specs/plans/plan-<spec-name>.md` if it exists, and note the file list. Used in Step 2 to flag overlap.

---

## Step 2 — Ask user-perspective question

Output exactly:
```
📋 Next spec slot: spec-phase<N>-<NN>-<placeholder>

👤 **Action needed:**
What are we building? Describe from end-user / business perspective —
what should the user be able to do that they cannot today, and why
does it matter? Any constraints, edge cases, or integrations to know about?

(Or say "use existing" if I should base this on the file you provided.)
```

⛔ STOP. Wait for user response.

---

## Step 3 — Discovery dialogue

⛔ NO FILES WRITTEN. This is a conversation, not a draft.

Based on the user's description + context from Step 1, output a discovery report. Do NOT draft outline yet. Do NOT propose filename yet.

```
🔍 Discovery — what I see

**DECs in play**
- DEC-NNN — [title] — relationship: honors / extends / would supersede / no impact
- DEC-NNN — [title] — relationship: ...

**Modules / interfaces touched** (from docs/MAP.md)
- [module path] — [why touched] — [README at src/.../README.md]
- [module path] — [why touched]

**In-progress spec overlap**
- spec-NNN ([branch_prefix]/spec-NNN) is currently 🔄 In progress and touches files [list overlapping files]. Coordinate before this spec proceeds. (Or: "No overlap with in-progress specs.")

**Candidate implementation paths**

Path A: [name]
- Approach: [one paragraph]
- Tradeoffs: [cost / blast radius / fit with architecture]
- Flag if chosen: ✅ / 🟡 / 🔴 — [reason]

Path B: [name]
- Approach: [one paragraph]
- Tradeoffs: [cost / blast radius / fit with architecture]
- Flag if chosen: ✅ / 🟡 / 🔴 — [reason]

(Path C optional, only if a meaningfully different third path exists.)

**🔴 watch-list** — what would push the chosen path to hard-stop:
- Touching 2+ existing interfaces — [yes/no for each path]
- No DEC coverage for proposed pattern — [yes/no]
- New architectural pattern — [yes/no]
- Becomes dependency for 3+ specs — [yes/no]

**Open questions for you (human is best positioned)**
- [question 1 — concrete, decidable]
- [question 2]
```

After the report, output:

```
👤 **Action needed:**
1. Pick a path (A / B / C) or describe a different one.
2. Answer the open questions, or say "defer to outline" if you want me to choose defaults and flag in outline.
3. If a path is 🔴 you want to take anyway, say "ignore flag, proceed anyway, accept risk" — and I will warn this is unusual.
```

⛔ STOP. Wait for user direction.

---

## Step 4 — Cross-check existing spec (if provided)

If `$ARGUMENTS` was a spec path: flag contracts conflicting with current interfaces, superseded decisions, what needs refresh.

Feed findings into Step 5. Do not preserve old content — full regeneration happens at Step 6.

If no path provided: skip this step.

---

## Step 5 — Derive filename, show outline

Filename: lowercase kebab-case, strip filler words, max 4 words, format `spec-phase<N>-<NN>-<name>.md`.

### Block 1 — Outline:
```
📋 Filename: specs/<filename>

Scope
- Builds: <what this creates>
- Out of scope: <what it does not>
- Depends on: <required specs>

Interfaces
- <fn>(args) → return type

Failure paths
- <scenario> → <behavior>

Open questions (deferred to impl)
- <ambiguity that did not block planning>

Flag: 🔴 / 🟡 / ✅ — <reason — should match what was negotiated in Step 3 discovery>
```

The outline MUST include:
- DEC alignment: list every DEC-NNN this spec assumes. If any DEC would be contradicted, STOP and propose supersession via decision-sync first.
- Components consumed: list COMPONENT-LIBRARY.md entries reused. If a library component is being inlined, REJECT outline.
- New components proposed: must be added to COMPONENT-LIBRARY.md first via separate approval.
- Visual acceptance source (screen specs): cite design-source HTML + asset list.

**Flag rules (HARD STOP on 🔴):**
- 🔴 spec touches 2+ existing interfaces | no DEC coverage | new architectural pattern | dependency for 3+ specs | overlaps in-progress spec on shared files
- 🟡 modifies existing interface | external I/O | new third-party dep | overlaps in-progress spec on adjacent files
- ✅ none of above

If 🔴: skill MUST halt unless the user explicitly negotiated risk acceptance during Step 3 discovery. Reading "ignore flag, proceed anyway, accept risk" from Step 3 carries forward HERE only — re-check the user's Step 3 message before proceeding. If user did not say it in Step 3, halt now and require:
(a) supersede relevant DEC via decision-sync, OR
(b) propose new DEC, get user approval, before resuming.

"Looks good"/"approved" alone DOES NOT bypass 🔴. The explicit risk-acceptance phrase from Step 3 is the only carry-forward.

### Block 2 — Human summary:
```
## What this builds
<2-3 sentences. What will exist after this spec that didn't exist before.
Written for a technical person who hasn't read the spec.>

## Deliverables
- <concrete thing: file, endpoint, UI screen, process>
- <concrete thing>
- <concrete thing>

## How to smoke test (manual reference)
1. <exact step — what to run or click>
2. <what you should see if it works>
3. <one failure scenario — what to do and what you should see>
```

After both blocks:

Output:
```
👤 **Action needed:**
Say "approved" to generate spec + plan + draft smoke test, or tell me what to change.
```

⛔ STOP. Wait for "approved" / "generate" / "looks good". Do not proceed until explicit confirmation.

---

## Step 6 — Generate three artifacts (memory only)

⛔ NO FILES WRITTEN IN THIS STEP.

Generate, in memory, three artifacts:

### 6a — Contract spec

For UI screen specs: route to `workflow/templates/screen-spec.md`. Auto-populate Visual Acceptance from `.rossflow/design-source-index.json`. Set `type: screen` in frontmatter.
For all other specs: use `specs/spec-template.md`.

Fill every section — no TBD.
Contracts: signatures + types only, no bodies.
Every external I/O: at least one failure path.
All signatures consistent with loaded ARCHITECTURE.md, DECISIONS.md, COMPONENT-LIBRARY.md, DESIGN-SYSTEM.md.

**Contracts checklist:**
- Types that configure behavior: document valid ranges/constraints in field comments; specify what the constructor does when constraints are violated.
- Types that represent failure/rejection: must have a machine-readable identifier field (e.g. `code`, `rule`, `type`) separate from any human-readable `reason`/`message`. Single-field error types are not sufficient.

### 6b — Implementation plan

Use `workflow/templates/plan-template.md`.

Fill every section based on Step 3 discovery direction + Step 5 outline. Capture:
- File list with create/modify markers + LOC delta estimate
- DEC alignment (per DEC the plan touches)
- Components consumed from COMPONENT-LIBRARY.md (reuse ratio for screen specs ≥ 0.6)
- New patterns introduced (if any)
- Architecture-fit statement (one paragraph)
- Risks and mitigations (at least one risk per external I/O)
- Rollback plan
- Ambiguities resolved during discovery (cite Step 3 user resolutions)
- Open questions deferred to implementation

### 6c — Draft smoke test

Use `workflow/templates/smoke-test-draft.md`.

Generate ONE happy-path + ONE failure-path step per external I/O described in 6a contract. Mark file `Status: DRAFT — pre-implementation`. Acknowledge in each step: "Refinement needed at impl: ...".

→ Step 7.

---

## Step 7 — Validate

Scan every code block in 6a contract spec. Strip:
- Method with body (more than `...` or `pass`)
- Implementation logic (loops, conditionals, DB calls, await chains)

✅ `[backend_lang]: function_name(arg: ArgType) -> ReturnType: ...`  (signature only)
❌ `[backend_lang]: function_name(arg) { rows = db.query(...); return rows }`  (has body — not allowed)

Check 6b plan for: at least one risk listed, rollback plan complete, architecture-fit statement present.

Check 6c draft smoke for: one happy + one failure per external I/O in contract.

Output:
```
🔍 Validation:
  Contract spec
    Contracts: ✅ clean / ⚠️ stripped <N> bodies
    Failure paths: ✅ present / ❌ added placeholder
    Done when: ✅ has failure checks / ⚠️ added one
  Implementation plan
    Risks: ✅ <N> listed / ⚠️ none
    Rollback: ✅ present / ⚠️ missing
    Arch-fit statement: ✅ / ❌
  Draft smoke
    External I/O coverage: ✅ N happy + N failure / ⚠️ <gap>
```

Anything stripped or missing → show before/after, ask "save". ⛔ STOP. Wait.
Clean → Step 8.

---

## Step 8 — Write files

✅ FILES WRITTEN HERE ONLY.

1. `specs/<filename>` — full regenerated contract spec (overwrite if exists)
2. `specs/plans/plan-<filename>` — implementation plan (create dir if needed)
3. `smoke-tests/<filename-without-ext>-DRAFT.md` — draft smoke test (create `smoke-tests/` if needed)
4. `PROGRESS.md` — add row `| <NN> | <spec-name> | ⬜ Not started | | |`
5. `git checkout [main_branch] && git pull`
   - Branch `[branch_prefix]/<spec-name>` exists → `git checkout [branch_prefix]/<spec-name>`
   - Else → `git checkout -b [branch_prefix]/<spec-name>`

---

## Step 9 — Output

```
✅ specs/<filename>
✅ specs/plans/plan-<filename>
✅ smoke-tests/<filename-without-ext>-DRAFT.md
✅ PROGRESS.md updated
✅ branch: [branch_prefix]/<spec-name>
```

🔴 → "Review in Claude.ai before /spec-implement. Attach docs/, spec, and plan."
🟡 → "Read spec + plan carefully before /spec-implement."
✅ → "Run: /spec-implement <filename-without-extension>"
