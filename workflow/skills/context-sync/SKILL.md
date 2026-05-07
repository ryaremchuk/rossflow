---
name: context-sync
description: Update docs/ARCHITECTURE.md, docs/ctx/*.md files from unprocessed context-update files. Tracks sync state in specs/updates/SYNC-STATUS.md. Run after every clean smoke test.
---

Sync context from unprocessed spec updates.

---

## Step 1 — Read SYNC-STATUS.md

Read `specs/updates/SYNC-STATUS.md`. If missing, create:
```markdown
# Context Sync Status

| Spec | Context Update File | Status | Synced |
|---|---|---|---|
```

Scan `specs/updates/` for all `context-update-*.md` files.
Build: **Unsynced** (not in status file or not ✅) | **Synced** (skip).

No unsynced files:
```
✅ All context synced. Nothing to do.
```
Stop.

Otherwise:
```
📋 <N> unsynced update(s):
   1. context-update-<spec>.md → targets: <ctx files>
Processing one at a time.
```

---

## Step 2 — Process first unsynced file

Read:
1. The context-update file — check **Target ctx files** section
2. Each listed `docs/ctx/*.md` file
3. `docs/DECISIONS.md` (if decisions surfaced)

Update rules:

**Update `docs/ARCHITECTURE.md` if:**
- A new module, service, or layer was introduced

**Update `docs/ctx/<file>.md` if:**
- New module, interface, or layer introduced
- Existing interface signature changed
- New DB column or API endpoint added
- Data flow changed

**Update `docs/DECISIONS.md` if:**
- New architectural decision made
- Existing decision refined or constrained

**Do NOT update if:** section says `none` | info already exists verbatim | implementation detail not architectural.

Output proposed changes before writing:
```
📄 context-update-<spec>.md


docs/ARCHITECTURE.md — [will update | no changes]
  → <one line: what will be added>

docs/ctx/ctx-backtesting.md — [will update | no changes]
  → <one line: what will be added>

docs/DECISIONS.md — [will update | no changes]
  → <one line: what will be added>

👤 **Action needed:**
Apply? (yes / skip / stop)
```

Wait for explicit response.

---

## Step 3 — Apply

**yes:** apply changes to ctx files — append to relevant sections, never rewrite existing content, match existing style. New decision → next available DEC number.

After applying ctx file changes: check if any ctx file in `docs/ctx/` was created by this sync step and does not yet appear in `docs/MAP.md`. If so, append a row:
```
| [Component] | ctx/ctx-[name].md | unassigned |
```
Derive `[Component]` from the ctx filename (e.g. `ctx-payments.md` → `Payments`).

Update `SYNC-STATUS.md`:
```
| <spec> | context-update-<spec>.md | ✅ Synced | <date> |
```

Output:
```
✅ context-update-<spec>.md synced
   docs/ARCHITECTURE.md — [updated | unchanged]
   docs/ctx/ctx-<x>.md — [updated | unchanged]
   docs/DECISIONS.md   — [updated | unchanged]
   docs/MAP.md         — [updated | unchanged]
```

**skip:** mark ⏭️ Skipped in SYNC-STATUS.md.

**stop:** `⏹️ Stopped. Run /context-sync to resume.` Halt.

---

## Step 4 — Continue or finish

More files → `<N> remaining. Processing: context-update-<spec>.md` → back to Step 2.

All done:
```
✅ Sync complete. Synced: <N> | Skipped: <N>

Next: /ship
```
