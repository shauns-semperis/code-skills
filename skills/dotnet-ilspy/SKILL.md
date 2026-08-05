---
name: dotnet-ilspy
description: Understand implementation details of .NET code by decompiling assemblies. Use when you want to see how a .NET API works internally, inspect NuGet package source, view framework implementation, or understand compiled .NET binaries.
allowed-tools: Bash(ilspycmd:*), Bash(dnx ilspycmd:*), Bash(which ilspycmd), Bash(find:*), Bash(dotnet --list-runtimes), Bash(dotnet --list-sdks), Bash(dotnet --version), Bash(*ilspy-find.sh:*), Bash(dotnet run *refs.cs*)
---

# .NET Assembly Decompilation with ILSpy

Use this skill to understand how .NET code works internally by decompiling compiled assemblies.

## Prerequisites

- .NET SDK installed

Run ILSpy with `dnx ilspycmd`. `dnx` downloads and runs the `ilspycmd` NuGet package on demand, so there's no install step and nothing to check first — go straight to `dnx ilspycmd`.

Always put a `--` before ilspycmd's own arguments: `dnx ilspycmd -- <ilspycmd args>`. Without it, `dnx` parses flags it recognizes itself — most importantly `-h`/`--help` and `-v`/`--version` — and swallows them instead of forwarding to ilspycmd, which looks like the tool is broken when it isn't.

If `dnx` isn't available (older SDK), fall back in this order:
1. `which ilspycmd` — check whether the tool is already installed globally
2. If not found, `dotnet tool install --global ilspycmd`, then call `ilspycmd` directly

> Note: ILSpyCmd options may vary slightly by version.  
> Always verify supported flags with `dnx ilspycmd -- -h`.

## Quick start

```bash
# Decompile an assembly to stdout
dnx ilspycmd -- MyLibrary.dll

# Decompile to an output folder
dnx ilspycmd -- -o output-folder MyLibrary.dll
```

## Common .NET Assembly Locations

### NuGet packages

```bash
~/.nuget/packages/<package-name>/<version>/lib/<tfm>/
```

### .NET runtime libraries

```bash
dotnet --list-runtimes
```

### .NET SDK reference assemblies

```bash
dotnet --list-sdks
```

> Reference assemblies do not contain implementations.

### Project build output

```bash
./bin/Debug/net8.0/<AssemblyName>.dll
./bin/Release/net8.0/publish/<AssemblyName>.dll
```

## Core workflow

1. Identify what you want to understand
2. Locate the assembly
3. List types
4. Decompile the target

## Keeping token usage low

A decompiled class can run to hundreds or thousands of lines. Dumping a whole type or a whole assembly straight into the conversation burns tens of thousands of tokens on code you'll only read a few lines of. Use this skill's bundled script, `<skill-dir>/scripts/ilspy-find.sh`, instead of raw `ilspycmd` calls for anything beyond a quick look:

```bash
# Find the type you actually need (cheap — just lists names)
<skill-dir>/scripts/ilspy-find.sh list MyLibrary.dll "JsonSerializer"

# Decompile only that type and print just the matching method with context,
# instead of the whole class. The pattern is a regex, so search several
# things in one call with alternation: "Deserialize|GetTypeInfo"
<skill-dir>/scripts/ilspy-find.sh grep MyLibrary.dll Namespace.JsonSerializer "SerializeObject" 15

# Just want to see a type's shape (fields, method signatures)? Peek at the
# first N lines instead of decompiling it in full
<skill-dir>/scripts/ilspy-find.sh peek MyLibrary.dll Namespace.SomeSmallClass 60

# Or get just the public/protected/internal member declarations, no bodies
<skill-dir>/scripts/ilspy-find.sh api MyLibrary.dll Namespace.SomeSmallClass

# Find every place a name is used across the WHOLE assembly, not just one
# type you already picked — e.g. "where is CashRegister referenced?" This
# is plain text search, so comments and XML doc mentions count as hits too.
<skill-dir>/scripts/ilspy-find.sh search MyLibrary.dll "CashRegister" 10

# Like search, but only real code references, not comments or XML doc
# (<see cref="...">) mentions — often a third of search's raw hits are
# doc-only. Parses the decompiled source with Roslyn instead of grepping
# text, so it's precise without needing the assembly's dependencies.
<skill-dir>/scripts/ilspy-find.sh refs MyLibrary.dll CashRegister
```

All six subcommands decompile to a temp file (or, for `search`/`refs`, a temp directory — one file per type) and print only a bounded slice of it (`grep`/`search`/`refs` cap output at 150 lines no matter how broad the search pattern is — a catch-all pattern like `.` gets truncated, not a full dump). The temp path is always printed, so if you genuinely need more than what was shown, read it directly with a bounded line range (the Read tool's offset/limit, or `peek` with a bigger line count) — don't decompile the same type again, and don't follow up a `grep`/`peek`/`api` call by also `Read`-ing the whole temp file for content you already saw; that shows the model the same code twice for nothing.

Repeat calls against the same type or assembly reuse a cache (keyed by the file's path, size, and modification time, so a rebuilt DLL at the same path decompiles fresh instead of returning stale results) — decompiling the same type five times across five calls, which is the common pattern, costs one real decompile instead of five.

There is no case where a bare, unpiped `dnx ilspycmd -- -t Type file.dll` is the right move, including for small utility types and generic classes like `JsonConverter\`1`. Even a genuine "read this whole type" need is bounded: bump `peek`'s line count, or decompile to a file and read it with the Read tool's offset/limit. A raw dump with no cap puts the whole class in context whether you meant to or not.

## Commands

### Basic decompilation

```bash
dnx ilspycmd -- MyLibrary.dll
dnx ilspycmd -- -o ./decompiled MyLibrary.dll
dnx ilspycmd -- -p -o ./project MyLibrary.dll
```

### Targeted decompilation

```bash
dnx ilspycmd -- -t Namespace.ClassName MyLibrary.dll
dnx ilspycmd -- -lv CSharp12_0 MyLibrary.dll
```

### View IL code

```bash
dnx ilspycmd -- -il MyLibrary.dll
```

If you fell back to a global tool install, drop the `dnx ` prefix from these commands.

## Notes on modern .NET builds

- ReadyToRun images may reduce readability
- Trimmed or AOT builds may omit code
- Prefer non-trimmed builds

## Legal note

Decompiling assemblies may be subject to license restrictions.
