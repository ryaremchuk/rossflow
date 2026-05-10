---
name: spec-create
description: Generate a new spec file. Describe the feature or pass an existing spec path. Reads project context, proposes filename, shows outline + human summary for approval, validates, then writes files.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-git.md`

---

Generate spec. Input: `$ARGUMENTS`

⛔ NO FILES WRITTEN until Step 7. Steps 0–6 are read and output only.

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

1. docs/ARCHITECTURE.md (full)
2. docs/DECISIONS.md (full)
3. docs/COMPONENT-LIBRARY.md if exists
4. docs/DESIGN-SYSTEM.md if exists
5. .rossflow/design-source-index.json if exists
6. docs/PATTERNS.md (index, then targeted grep)
7. existing specs (for ordering)

Also: `PROGRESS.md` → current phase, next spec number; `specs/spec-template.md`; most recently completed spec in `specs/`.

If `$ARGUMENTS` is a path to existing spec (contains `/` or ends `.md`) → read it. It is input only — will be fully regenerated and overwritten at Step 7.

Determine next spec number from PROGRESS.md automatically.

---

## Step 2 — Derive filename, ask one question

Filename: lowercase kebab-case, strip filler words, max 4 words, format `spec-phase<N>-<NN>-<name>.md`.

Output exactly:
```
📋 Proposed: specs/<filename>

👤 **Action needed:**
What are we building? User/business perspective.
Constraints, edge cases, integrations to know about?
Or say "use existing" if I should base this on the file you provided.
```

⛔ STOP. Wait for user response.

---

## Step 3 — Cross-check existing spec (if provided)

Flag: contracts conflicting with current interfaces | superseded decisions | what needs refresh.
Feed findings into Step 4. Do not preserve old content — full regeneration happens at Step 5.

---

## Step 4 — Show outline + human summary

### Block 1:
```
Scope
- Builds: <what this creates>
- Out of scope: <what it does not>
- Depends on: <required specs>

Interfaces
- <fn>(args) → return type

Failure paths
- <scenario> → <behavior>

Open questions
- <ambiguity>

Flag: 🔴 / 🟡 / ✅ — <reason>
```

The outline MUST include:
- DEC alignment: list every DEC-NNN this spec assumes. If any DEC would be contradicted, STOP and propose supersession via decision-sync first.
- Components consumed: list COMPONENT-LIBRARY.md entries reused. If a library component is being inlined, REJECT outline.
- New components proposed: must be added to COMPONENT-LIBRARY.md first via separate approval.
- Visual acceptance source (screen specs): cite design-source HTML + asset list.

**Flag rules (HARD STOP on 🔴):**
- 🔴 spec touches 2+ existing interfaces | no DEC coverage | new architectural pattern | dependency for 3+ specs
- 🟡 modifies existing interface | external I/O | new third-party dep
- ✅ none of above

If 🔴: skill MUST halt. Require either:
(a) supersede relevant DEC via decision-sync, OR
(b) propose new DEC, get user approval, before resuming.

"Looks good"/"approved" DOES NOT bypass 🔴. User must explicitly say "ignore flag, proceed anyway, accept risk" — and skill warns this is unusual.

### Block 2:
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
Say "approved" to write, or tell me what to change.
```

⛔ STOP. Wait for "approved" / "generate" / "looks good". Do not proceed until explicit confirmation.

---

## Step 5 — Generate spec content (memory only)

⛔ NO FILES WRITTEN IN THIS STEP.

For UI screen specs: route to `workflow/templates/screen-spec.md`. Auto-populate Visual Acceptance from `.rossflow/design-source-index.json`. Set `type: screen` in frontmatter.
For all other specs: use `specs/spec-template.md`.

Fill every section — no TBD.
Contracts: signatures + types only, no bodies.
Every external I/O: at least one failure path.
All signatures consistent with loaded ARCHITECTURE.md, DECISIONS.md, COMPONENT-LIBRARY.md, DESIGN-SYSTEM.md.

**Contracts checklist:**
- Types that configure behavior: document valid ranges/constraints in field comments; specify what the constructor does when constraints are violated.
- Types that represent failure/rejection: must have a machine-readable identifier field (e.g. `code`, `rule`, `type`) separate from any human-readable `reason`/`message`. Single-field error types are not sufficient.

→ Step 6.

---

## Step 6 — Validate

Scan every code block. Strip:
- Method with body (more than `...` or `pass`)
- Implementation logic (loops, conditionals, DB calls, await chains)

✅ `[backend_lang]: function_name(arg: ArgType) -> ReturnType: ...`  (signature only)
❌ `[backend_lang]: function_name(arg) { rows = db.query(...); return rows }`  (has body — not allowed)

Output:
```
🔍 Validation:
  Contracts: ✅ clean / ⚠️ stripped <N> bodies
  Failure paths: ✅ present / ❌ added placeholder
  Done when: ✅ has failure checks / ⚠️ added one
```

Anything stripped → show before/after, ask "save". ⛔ STOP. Wait.
Clean → Step 7.

---

## Step 7 — Write files

✅ FILES WRITTEN HERE ONLY.

1. `specs/<filename>` — full regenerated spec (overwrite if exists)
2. `[specs_dir]/<filename>` — Block 2 only
3. `PROGRESS.md` — add row `| <NN> | <spec-name> | ⬜ Not started | | |`
4. `git checkout [main_branch] && git pull`
   - Branch `[branch_prefix]/<spec-name>` exists → `git checkout [branch_prefix]/<spec-name>`
   - Else → `git checkout -b [branch_prefix]/<spec-name>`

---

## Step 8 — Output

```
✅ specs/<filename>
✅ [specs_dir]/<filename>
✅ PROGRESS.md updated
✅ branch: [branch_prefix]/<spec-name>
```

🔴 → "Review in Claude.ai before /spec-implement. Attach docs/ and spec."
🟡 → "Read spec carefully before /spec-implement."
✅ → "Run: /spec-implement <filename-without-extension>"
