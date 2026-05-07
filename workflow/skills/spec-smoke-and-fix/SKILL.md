---
name: spec-smoke-and-fix
description: Automated smoke test + bug fix loop for a spec. Runs smoke tests, fixes each bug in its own subagent, repeats until clean or 3 cycles exhausted.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-config.md`

---

Run smoke-and-fix loop for: `$ARGUMENTS`

Max cycles: **3**

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

## Cycle loop

Repeat while `CYCLE <= 3`:

---

### Phase 1 — Smoke Test

Print:
```
🧪 Cycle <CYCLE>/3 — Smoke Test starting...
```

Read `.claude/skills/spec-smoke-test/SKILL.md` and follow all instructions exactly, with `$ARGUMENTS` as the spec name.

This will:
- Ensure Docker is running
- Execute all steps from `smoke-tests/$ARGUMENTS.md`
- Create bug reports in `bugs/` for any failures
- Print the step summary

After smoke test completes, collect results:
- Count steps: total, passed, failed
- Scan `bugs/bug-$ARGUMENTS-*.md` — find all with status `⬜ Open`
- Record open bug list: filename + title + severity

Print:
```
🧪 Cycle <CYCLE>/3 — Smoke Test complete
   Steps: <total> | ✅ <passed> | ❌ <failed>
   Open bugs: <N>
```

If zero open bugs:
```
✅ Cycle <CYCLE>/3 — All steps passing. Spec is clean.
```
Go to **Final Summary** with status CLEAN.

---

### Phase 2 — Bug Fix (subagents)

Print:
```
🔧 Cycle <CYCLE>/3 — Bug Fix starting
   Bugs to fix: <N>
   Order: 🔴 Critical → 🟡 Medium → 🟢 Low
```

Sort open bugs: 🔴 → 🟡 → 🟢 (by severity in bug report header).

For each open bug (sequentially):

#### Spawn subagent

Print:
```
  → Spawning subagent for: <bug-filename> — <title> [severity]
```

Spawn a Task subagent with this prompt (substitute actual values):

```
You are fixing one bug in the [project_name] project.

Spec: $ARGUMENTS
Bug report: bugs/bug-$ARGUMENTS-<NN>.md

Instructions:
1. Read .claude/skills/bug-fix/SKILL.md
2. Read bugs/bug-$ARGUMENTS-<NN>.md
3. Follow the bug-fix skill instructions exactly for this single bug report only.
   - Do not fix any other bugs
   - Do not run smoke tests
   - Update the bug report with outcome (✅ Fixed or ⚠️ Escalated)
4. When done, print one final line:
   RESULT: [FIXED|ESCALATED] — <one sentence summary>
```

Wait for subagent to complete.

#### Read outcome

Read updated `bugs/bug-$ARGUMENTS-<NN>.md` — check status field:
- `✅ Fixed` → record as fixed, print `  ✅ Fixed: <title>`
- `⚠️ Escalated` → add to `ESCALATED_BUGS`, print `  ⚠️ Escalated: <title>`

Continue to next bug regardless of outcome (finish all bugs in this cycle).

#### After all bugs processed

Print:
```
🔧 Cycle <CYCLE>/3 — Bug Fix complete
   ✅ Fixed: <N> | ⚠️ Escalated: <N>
```

If `ESCALATED_BUGS` is not empty, print escalation notice (but do NOT stop — cycle will still repeat for non-escalated bugs):
```
⚠️  Escalated bugs require human review:
    <list of escalated bug filenames>
    These will not be retried in subsequent cycles.
```

---

### Phase 3 — Cycle decision

If `CYCLE < 3`:
- Increment `CYCLE`
- Print:
  ```
  ↩️  Repeating — starting cycle <CYCLE>/3
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```
- Go to **Phase 1**

If `CYCLE == 3`:
- Go to **Final Summary** with status EXHAUSTED

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

Next: /context-sync → /ship
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
  - Do NOT run /context-sync or /ship until all bugs resolved
```
