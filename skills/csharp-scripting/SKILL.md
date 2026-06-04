---
name: csharp-scripting
description: Runs throwaway C# as a .NET 10 file-based app (a single `.cs` file with `#:package` directives, run via `dotnet run file.cs`) instead of scaffolding a `dotnet new` project. Use whenever C# is the chosen tool for something trivial you'd otherwise spin up a csproj for, including inside an existing project: checking how a C# API behaves, generating sample data in C#, a quick C# experiment, or when the user says "in C#", "use C#", or names a NuGet package for a one-off. Requires C# to be named or clearly intended; a language-agnostic scratch task (plain "generate some test data") is not enough on its own.
---

# C# Scripting with .NET 10 File-Based Apps

.NET 10+ supports **file-based apps**: a single `.cs` file with build directives
in the source. No `.csproj`, no `dotnet new`, no scaffolding.

When the user specifies C# or a NuGet package for a one-off task, use this every time.

It applies inside an existing project too. To check how an API behaves, generate
sample data, or prototype something trivial, write a file-based app instead of
spinning up a throwaway `dotnet new` console project. It's faster and leaves
nothing behind. Save the real project for code you're committing to it.

## Directives

Place these at the top of the `.cs` file, before any `using` statements:

```
#:package Newtonsoft.Json@13.0.3    # NuGet package, version required (use @* for latest)
#:property TargetFramework=net10.0  # MSBuild property (defaults to net10.0)
#:sdk Microsoft.NET.Sdk             # SDK (defaults to Microsoft.NET.Sdk)
```

The only directive you'll normally need is `#:package`. Always give it a
version: a pin (`@13.0.3`) or `@*` for latest. A bare `#:package Newtonsoft.Json`
fails the restore with `NU1015: ... do not have a version specified`.

## Workflow

```
1. Write the .cs file with #:package directives at the top
2. dotnet run <file>.cs -- <args>
3. Read stdout / output file
4. rm <file>.cs   ← clean up when done
```

**Pipe stdin for trivial one-liners:**

```bash
echo 'Console.WriteLine("done");' | dotnet run -
```

## Timing: why this matters

| Approach | Cold | Warm |
|----------|------|------|
| Full project scaffold (`dotnet new` + `add package` + `run`) | 2.89s | 2.14s |
| Single-file app (`dotnet run file.cs`) | 0.83s | **0.19s** |

Single-file is 3.5× faster cold, 11× faster warm, and produces zero artifacts to clean up.

## Anti-patterns to avoid

### 1. Scaffolding a project for a one-off script

❌ `dotnet new console -n foo` → `dotnet add package X` → `dotnet run`
✅ Write a `.cs` file, `#:package X@version`, `dotnet run file.cs`

When the task is a one-off and the user says "don't spend time on setup" or
"quick one-off", scaffolding a project is exactly what they're telling you
to avoid.

### 2. Generating output inline when C# is specified

❌ "I generated the JSON directly rather than using C#"
✅ Write and run the `.cs` file, even if you *could* produce the output inline

If the user says "in C#" or "use Newtonsoft.Json", they want the code to
actually execute. Inline generation bypasses the requirement and the package
they specified. It also can't catch type errors or serialization issues.

### 3. Claiming to have used C# when you didn't

❌ "Serialization: Newtonsoft.Json 13.0.4" but never ran `dotnet`
✅ Actually invoke `dotnet run`; the cache and restore timestamps prove it

Don't fabricate tool usage. If you didn't run `dotnet run file.cs`, don't
say you did. The user can verify.

## Gotchas

### CS8803: top-level statements must precede type declarations

If you define a class or namespace and also have top-level statements, the
top-level statements must come first. Putting a class definition before them
causes `CS8803`.

```csharp
// ✅ top-level statements first, then type definitions
var result = Helper.Greet("world");
Console.WriteLine(result);

class Helper {
    public static string Greet(string name) => $"Hello, {name}!";
}
```

```csharp
// ❌ CS8803 — type declaration before top-level statement
class Helper {
    public static string Greet(string name) => $"Hello, {name}!";
}

var result = Helper.Greet("world"); // error here
Console.WriteLine(result);
```

## Example

User: *"Generate sample JSON in C# using Newtonsoft.Json."*

```csharp
// gen.cs
#:package Newtonsoft.Json@13.0.3

using Newtonsoft.Json;

var data = new { name = "example", value = 42 };
File.WriteAllText("output.json", JsonConvert.SerializeObject(data, Formatting.Indented));
```

```bash
dotnet run gen.cs && rm gen.cs
```
