---
name: ship
description: Commit all changes, push to current branch, open PR to main branch.
---

## Config

Read the following files before executing this skill. All commands, paths, tool names, and service identifiers used below come from these files.

- `.claude/workflow-git.md`

---

Commit, push, open PR.

`/smoke-all` is NOT auto-invoked. Run it manually when you want to gate a ship on regression results.

---

## Step 1 — Understand changes

Run in parallel:
- `git status`
- `git diff`
- `git log --oneline -10`
- `git branch --show-current`

---

## Step 2 — Stage and commit

Stage relevant files only. Never `.env`, `*.key`, credentials.

Commit format:
```
<type>(<scope>): <short description>
# type: feat | fix | refactor | test | docs | chore
# scope: [commit_scopes] (from workflow-git.md)
```

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Step 3 — Push

```bash
git push -u origin <current-branch>
```

---

## Step 4 — Open PR

Skip this step if `[pr_tool]` is `none`.

Use numbered list in Summary. Generate items from actual changes.

```bash
[pr_tool] pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
1. <change>

## Test plan
- [ ] <step>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Return PR URL.
