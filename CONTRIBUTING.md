# Contributing

## Skill structure

Every skill lives in `skills/<skill-name>/` and must contain:

- **`SKILL.md`** (required) — Skill instructions with YAML frontmatter (`name`, `description`)
- **`README.md`** (required) — Human-facing summary: what the skill does, when it triggers, any prerequisites (e.g., Docker, .NET SDK). This is for contributors and users browsing the repo, not for Claude.

Optional directories:

- `references/` — Supporting docs loaded on demand (format lists, API references)
- `scripts/` — Executable scripts the skill invokes
- `evals/` — Test cases in `evals.json` for verifying skill behavior
- `assets/` — Templates, icons, or other static files used in output

## SKILL.md conventions

Follow the [Anthropic skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

- **Description in third person**: "Converts documents..." not "Convert documents..."
- **Under 500 lines** in the SKILL.md body — split into reference files if longer
- **Forward slashes** in all file paths, even on Windows
- **One level of reference depth** — all reference files link directly from SKILL.md
- **Be concise** — Claude is smart, only add context it doesn't already have
- **Explain why, not what** — prefer reasoning over rigid MUST/NEVER rules

## Adding a new skill

1. Create `skills/<skill-name>/`
2. Write `SKILL.md` with frontmatter and instructions
3. Write `README.md` with a human-readable summary
4. Add the skill to the table in the project `README.md`
5. If the skill has objectively verifiable output, add test cases in `evals/evals.json`
6. Update `.claude-plugin/plugin.json` description if the new skill changes the plugin's scope

## Versioning

Version bumps are automated via [commitizen](https://commitizen-tools.github.io/commitizen/). Install it once:

```
pipx install commitizen
```

When you're ready to release, run from the repo root:

```
cz bump
```

This reads commits since the last tag, determines the semver increment (`feat` → minor, `fix` → patch, breaking → major), updates `.claude-plugin/plugin.json`, and creates a version tag. Push with `git push --follow-tags`.

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

- **type**: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`
- **scope**: skill name or project area (e.g., `pandoc-docker`, `plugin`)
- **summary**: imperative mood, lowercase, no period

Examples:

```
feat(pandoc-docker): add document conversion skill via Docker
fix(dotnet-coding-conventions): correct nullable reference guidance
docs: update README with new skill listing
chore(plugin): bump version to 1.1.0
```

## Code review checklist

Before submitting a skill:

- [ ] `SKILL.md` has valid frontmatter (`name`, `description`)
- [ ] `README.md` exists in the skill directory
- [ ] Skill is listed in the project `README.md` table
- [ ] Description is third person and under 1,536 characters (Claude Code truncates `description` + `when_to_use` at 1,536 chars in the skill listing)
- [ ] File paths use forward slashes
- [ ] No time-sensitive information
- [ ] Tested with at least 2-3 realistic prompts
