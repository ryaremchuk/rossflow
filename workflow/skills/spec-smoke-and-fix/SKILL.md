---
name: spec-smoke-and-fix
description: Orchestrate the smoke-test → bug-fix → repeat loop for a spec. Invokes /spec-smoke-test, then spawns one /bug-fix subagent per open bug, repeats until clean or 3 cycles exhausted.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-config.md`

---

Run smoke-and-fix loop for: `$ARGUMENTS`

Max cycles: **3**

This skill is a thin orchestrator. It does NOT execute smoke-test steps itself — it invokes `/spec-smoke-test`. It does NOT classify bugs — each bug is delegated to a `/bug-fix` subagent which owns classification and routing.

---

## Startup

Print:
```
🔄 spec-smoke-and-fix — $ARGUMENTS
Max cycles: 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Initialize:
- `CYCLE = 1`
- `ESCALATED_BUGS = []`

---

## Cycle loop (repeat while `CYCLE <= 3`)

### Phase 1 — Smoke test

Print:
```
🧪 Cycle <CYCLE>/3 — Smoke Test starting...
```

Invoke `/spec-smoke-test $ARGUMENTS`. Wait for it to finish.

After it returns, collect results from the filesystem:
- Scan `bugs/bug-$ARGUMENTS-*.md` for entries with status `⬜ Open`.
- Record open bug list: filename + title + severity.

Print:
```
🧪 Cycle <CYCLE>/3 — Smoke Test complete
   Open bugs: <N>
```

If zero open bugs:
```
✅ Cycle <CYCLE>/3 — All steps passing. Spec is clean.
```
Go to **Final Summary** with status CLEAN.

### Phase 2 — Bug fix (subagents)

Print:
```
🔧 Cycle <CYCLE>/3 — Bug Fix starting
   Bugs to fix: <N>
   Order: 🔴 Critical → 🟡 Medium → 🟢 Low
```

Sort open bugs: 🔴 → 🟡 → 🟢 (by severity in bug report header).

For each open bug (sequentially):

Print:
```
  → Spawning subagent for: <bug-filename> — <title> [severity]
```

Spawn a Task subagent. The prompt body lives in `.claude/skills/spec-smoke-and-fix/subagent-prompt.md` — read it, substitute:
- `$SPEC` → `$ARGUMENTS`
- `$BUG_FILE` → the bug's full path (`bugs/bug-$ARGUMENTS-<NN>.md`)

Do NOT inline different instructions. Any classification or routing logic belongs in `/bug-fix`, not here.

Wait for subagent to complete.

Read the updated bug file's status field:
- `✅ Fixed` → record as fixed, print `  ✅ Fixed: <title>`.
- `⚠️ Escalated` → add to `ESCALATED_BUGS`, print `  ⚠️ Escalated: <title>`.

Continue to next bug regardless of outcome.

After all bugs processed:
```
🔧 Cycle <CYCLE>/3 — Bug Fix complete
   ✅ Fixed: <N> | ⚠️ Escalated: <N>
```

If `ESCALATED_BUGS` is not empty (do NOT stop — cycle still repeats for non-escalated bugs):
```
⚠️  Escalated bugs require human review:
    <list of escalated bug filenames>
    These will not be retried in subsequent cycles.
```

### Phase 3 — Cycle decision

If `CYCLE < 3`:
- Increment `CYCLE`.
- Print:
  ```
  ↩️  Repeating — starting cycle <CYCLE>/3
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```
- Go to **Phase 1**.

If `CYCLE == 3`:
- Go to **Final Summary** with status EXHAUSTED.

---

## Final Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
spec-smoke-and-fix — $ARGUMENTS — DONE
Cycles run: <N>/3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If status CLEAN:
```
✅ All smoke test steps passing. No open bugs.

Next: /decision-sync → /ship
```

### If status EXHAUSTED:
Scan all `bugs/bug-$ARGUMENTS-*.md` — count by final status.
```
⚠️  3 cycles exhausted. Remaining issues:

  Open bugs (not fixed):
    bugs/bug-$ARGUMENTS-<NN>.md — <title> [severity]

  Escalated bugs (need human review):
    bugs/bug-$ARGUMENTS-<NN>.md — <title> [severity]

Next steps:
  - Review escalated bugs in Claude.ai (Deep Spec Dive)
  - For open bugs: add context and run /bug-fix $ARGUMENTS manually
  - Do NOT run /decision-sync or /ship until all bugs resolved
```
