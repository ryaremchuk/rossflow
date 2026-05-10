---
name: decision-sync
description: Update docs/ARCHITECTURE.md and docs/DECISIONS.md from unprocessed context-update files. Forbidden to write code-mirror docs. Tracks sync state in specs/updates/SYNC-STATUS.md. Run after every clean smoke test.
---

## Step 1 — Read
- All `specs/updates/context-update-*.md` not yet listed in `specs/updates/SYNC-STATUS.md`
- `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/COMPONENT-LIBRARY.md` (if exists), `docs/MAP.md`

## Step 2 — Classify each update

| Type | Output target |
|------|---------------|
| New architectural decision | new DEC entry |
| Supersedes existing DEC | new DEC with `Status: superseded by DEC-NNN` |
| Layer/module added/restructured | ARCHITECTURE.md section update |
| New library component | COMPONENT-LIBRARY.md entry + MAP.md row |
| New per-component README needed | scaffold from `workflow/templates/component-readme.md` with computed frontmatter |
| Implementation summary, file list, signatures | **DROP. AI can read source.** |
| Spec deviation noted | already in PROGRESS.md; do not duplicate |

Hard rule: change doesn't fit a row → drop. Default = "no change."

## Step 3 — Propose patches
Output proposed changes per file before writing. If no changes: `No architectural changes detected. Marking N updates as synced.`

👤 Action needed: independent approval gate.

## Step 4 — Apply
On approval, write patches. Compute frontmatter on any updated/created README/DESIGN-SYSTEM/COMPONENT-LIBRARY:
- `synced_at_sha` = current `git rev-parse HEAD`
- `synced_at_hash` = `find <sources> -type f -print0 | sort -z | xargs -0 cat | sha256sum`
- `last_ai_review` = today

**Autonomy log append:** For each context-update file processed in this run, append one row to `.claude/autonomy-log.md` (create file with header if missing):

```
| date | spec | autonomous_decisions | escalations | DECs_touched |
|------|------|---------------------|-------------|--------------|
| <YYYY-MM-DD> | <spec-name> | <count from "Decisions surfaced" section> | <count of items in spec PROGRESS.md or bug reports marked ⚠️ Escalated for this spec> | <DEC-NNN list from "Architecture / decision impact"> |
```

Counts:
- `autonomous_decisions`: number of bullet items under "Decisions surfaced" in the context-update
- `escalations`: count from `bugs/bug-<spec>-*.md` with `Status: ⚠️ Escalated`, plus any spec deviations marked "escalated" in PROGRESS.md
- `DECs_touched`: comma-separated list of DEC-NNN ids from "Architecture / decision impact" section

Purpose: gives the user a single auditable trail of "where the agent decided autonomously vs where it asked". Reviewable any time; never written to by other skills.

## Step 5 — Drift check
For each `src/<*>/README.md`: recompute current hash of files in `sources` glob. If `current_hash != frontmatter.synced_at_hash`: flag `drift suspected; run /doc-check <component>`.

## Step 6 — Regenerate `docs/MAP.md`
Scan all per-component READMEs and rewrite `docs/MAP.md` from scratch.

```bash
find src -type f -name README.md
```

For each README found, parse its frontmatter for `name` (component name) and use the file's directory as `path`. If the README has no frontmatter `name`, fall back to the directory's basename. Sort rows alphabetically by component name.

Overwrite `docs/MAP.md` with:
- The "GENERATED — do not edit by hand" banner from `workflow/docs-templates/MAP.md` (preserve verbatim).
- The header row `| Component | Path | README |`.
- One row per README in the form `| <name> | <path> | [README](<path>/README.md) |`.

If `find` returns zero matches, write the banner + header with no data rows.

## Step 7 — Update SYNC-STATUS
Append processed update files to `specs/updates/SYNC-STATUS.md` with date.

Next: `/ship` if clean, else address drift first.
