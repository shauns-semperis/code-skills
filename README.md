# code-skills

Engineering skills for Claude Code — documentation writing, .NET coding conventions, xUnit testing, OpenAPI client generation, and git commit practices.

## Skills

| Skill | What it does |
|-------|-------------|
| `git-conventional-commits` | Writes commit messages that explain *why* changes exist, following the Conventional Commits spec |
| `docs-mailchimp-voice` | Reviews and rewrites public-facing documentation (READMEs, guides, changelogs) to sound human and helpful |
| `documenting-csharp-code` | Enforces concise C# XML doc comments — one-sentence summaries, proper `<see cref="">` tags, no boilerplate |
| `dotnet-coding-conventions` | Applies idiomatic C# 12+ conventions: null guards, collection expressions, logging with `[LoggerMessage]`, and more |
| `dotnet-ilspy` | Decompiles .NET assemblies with ILSpy to inspect NuGet packages or framework internals |
| `dotnet-nswag` | Generates typed API clients from OpenAPI/Swagger specs using `dotnet dnx` or the `nswag` CLI |
| `testing-xunit-effectively` | Writes xUnit tests that verify public outcomes, not implementation details — with `[Theory]` for repeated patterns |

## Install

### Marketplace install

Add the marketplace, then install the plugin:

```
/plugin marketplace add shauns-semperis/code-skills
/plugin install code-skills@code-skills
/reload-plugins
```

### Local / development

Clone the repo and load it directly with `--plugin-dir`:

```bash
git clone https://github.com/shauns-semperis/code-skills
claude --plugin-dir /path/to/code-skills
```

### Team auto-install

To prompt teammates to install when they open the project, add this to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "code-skills": {
      "source": {
        "source": "github",
        "repo": "shauns-semperis/code-skills"
      }
    }
  },
  "enabledPlugins": {
    "code-skills@code-skills": true
  }
}
```

## Usage

Skills activate automatically when Claude recognises the context, or you can invoke them directly:

```
/code-skills:git-conventional-commits
/code-skills:dotnet-coding-conventions
/code-skills:testing-xunit-effectively
```

Run `/help` to see all available skills from the plugin.
