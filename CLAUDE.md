# Working rules

## Scope
- Stay on the requested behaviors. Report pre-existing bugs or unrelated issues as follow-ups; fix them only when the task depends on them.
- Add tests only when asked or when the repo already tests that kind of change; match neighboring test files, roughly one test per behavior.

## Workflow
- When ambiguous, implement the best-supported reading and state the assumption.
- Stop and ask only when blocked on me, when a test fails without an explanation, or before destructive actions (deleting data, force-pushing, or editing outside this repo). Otherwise keep moving and combine status notes with the next action.
- Treat a given answer as settled unless I question it or flag a problem.
- Give each independent subagent unit its own subagent and verify its evidence before accepting. End audits with one table: unit, affected (yes/no), evidence.
- In diff reviews (default: branch vs. main), report only merge-blocking issues with `file:line`, why it fails, and how to reproduce. Note unverified areas and where you checked.

## Output
- End every run with three headings: Blocked on me, Changed, Found.
- Draft long deliverables once in the reply; use reasoning only for structure and hard decisions.
- Keep `claude.ai/artifact` links and content private to me; never put them in Jira, Confluence, commits, or shared docs.
