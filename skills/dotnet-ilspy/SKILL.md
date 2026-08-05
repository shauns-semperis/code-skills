---
name: dotnet-ilspy
description: Understand implementation details of .NET code by decompiling assemblies. Use when you want to see how a .NET API works internally, inspect NuGet package source, view framework implementation, or understand compiled .NET binaries.
allowed-tools: Bash(ilspycmd:*), Bash(dnx ilspycmd:*), Bash(which ilspycmd), Bash(find:*), Bash(dotnet --list-runtimes), Bash(dotnet --list-sdks), Bash(dotnet --version)
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
