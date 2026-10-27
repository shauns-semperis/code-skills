# durable-comments

Keeps code comments few, and keeps the session that wrote them out of them: the ticket, the requester, the versions in use, dates, and the debugging story. Comments state the constraint the code depends on; the story goes in the commit message, PR, or the agent's report.

## When it triggers

Writing, editing or reviewing comments in any language or config file (YAML, Dockerfiles, shell), especially right after a bug fix, a dependency bump, or a ticket, or when asked to "add a comment so we don't lose this" or to clean up comments.

## Core test

For each version, date, name or number in a comment: if it changed tomorrow, would the code have to change? If yes, state it as a constraint, or as a `TODO` with a removal condition. If no, leave it out.

## Related skills

- `documenting-csharp-code` covers C# XML documentation in detail.
- `git-conventional-commits` covers the commit message where the session context ends up.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions |
| `evals/evals.json` | Behavioural test cases: comments after an incident, a ticket, a version bump, an upstream workaround, and a cleanup pass |
| `evals/fixtures/` | Small repos each eval runs against |
