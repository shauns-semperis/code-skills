# Claude Skills

Custom skills for Claude. Version-controlled and shareable.

## Structure

Each skill lives in `.claude/skills/skill-name/skill.md`. Claude auto-discovers them when working in this project.

## Installation

### Claude Code (Plugin Marketplace)

Add this repository as a marketplace in Claude Code:

```
/plugin marketplace add shauns-semperis/code-skills
```

Then browse and install individual skills:

```
/plugin install dotnet-coding-conventions@code-skills
/plugin install testing-xunit-effectively@code-skills
```

Or use the interactive plugin manager:

```
/plugin
```

Go to **Discover** to browse all available skills, then select and install.

Skills are auto-discovered and available immediately.

## Adding Skills

Create a new folder with a `skill.md` file:
```
.claude/skills/my-skill/skill.md
```

Commit and push. Done.

## Skills

| Skill | What It Does |
|-------|--------------|
| **dotnet-coding-conventions** | The nits you'd see and get a brain splinter with during code review. Teaches the beep boops null guards, collection initializers, logging, braces, using directives—all the idiomatic C# stuff. |
| **documenting-csharp-code** | Claude writes XML docs like it's getting paid by the word. This keeps it concise: one sentence, contract over implementation, actual useful docs. |
| **testing-xunit-effectively** | Claude writes ten identical tests instead of one `[Theory]`, and tests how code works instead of what it does. This fixes both. |
| **git-conventional-commits** | Claude's commit messages say "update auth" when they should explain why. This enforces real commit messages that tell a story. |
| **dotnet-ilspy** | Teaches the sand how to dnx peek at source code since it typically prefers to just web search and make stuff up. See how .NET actually works inside. |
| **docs-mailchimp-voice** | Claude writes like a textbook. This makes it write like a helpful teammate—clear, confident, human. |
| **dotnet-nswag** | Teaches the beep boops how to generate API clients from OpenAPI specs using `dotnet dnx` or `nswag`—all the commands and flags, no guessing. |

See `.claude/skills/` for the full list.

