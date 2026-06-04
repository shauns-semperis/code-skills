# csharp-scripting

Runs throwaway C# as a .NET 10 file-based app (a single `.cs` file with `#:package` build directives) instead of scaffolding a full project.

## When it triggers

Any throwaway C# task, including inside an existing project, where you'd otherwise scaffold a csproj just to test something trivial: "do this in C#", "use C#", "use Newtonsoft.Json", checking how an API behaves, generating sample data, or naming a NuGet package for a quick experiment.

## Prerequisites

- .NET 10 SDK or later (`dotnet --version` ≥ 10) for file-based app support

## Why it exists

File-based apps run in ~0.19s warm versus ~2.14s for a scaffolded project, and leave no `.csproj`, `bin/`, or `obj/` artifacts behind. The skill also guards against three common failure modes: scaffolding a project anyway, generating output inline instead of executing the code, and claiming C# was used without actually running `dotnet`.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions, directives, workflow, and anti-patterns |
| `evals/evals.json` | Test cases verifying the skill runs a file-based app rather than scaffolding |
