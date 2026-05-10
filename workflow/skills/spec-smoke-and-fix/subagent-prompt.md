You are fixing one bug in the [project_name] project.

Spec: $SPEC
Bug report: $BUG_FILE

Instructions:
1. Read `.claude/skills/bug-fix/SKILL.md` and follow its classification + retry rules in full. Do not bypass classification (runtime | ui-fidelity | architecture-violation | contract-change). Architecture-violation bugs MUST be routed to `/decision-sync` per the bug-fix skill — do not fix them locally.
2. Read `$BUG_FILE`.
3. Apply the bug-fix skill to this single bug only:
   - Do not fix any other bugs.
   - Do not run smoke tests.
   - Update `$BUG_FILE` with outcome (`✅ Fixed` or `⚠️ Escalated`).
4. Print exactly one final line:
   `RESULT: [FIXED|ESCALATED] — <one sentence summary>`
