---
name: dotnet-nswag
description: Use when generating code clients from OpenAPI/Swagger specs using dotnet dnx or nswag CLI
---

# dotnet-nswag

## Overview

Generate typed API clients from OpenAPI specifications using `dotnet dnx` (modern, .NET 6+) or `nswag` (legacy). The tool reads a spec and outputs boilerplate client code in the target language.

## When to Use

- User asks: "generate a client for this OpenAPI spec"
- Need to regenerate client after API spec changes
- Client generation command syntax unclear or failing

## Quick Start

### Minimal (Default to `.gen` directory)

```bash
dotnet dnx <spec-path>
```

This generates output to `.gen/client.<ext>` in the current directory. **Path of least surprise:**
- No flags needed, sensible default location
- All generated files stay in one `.gen` folder
- Easy to clean up or ignore in version control

### With Custom Output Location

### dotnet dnx (Recommended)
```bash
dotnet dnx <spec-path> --output-file <output-path> --namespace <namespace> --classname <classname>
```

### nswag (Legacy)
```bash
nswag openapi2csharp /input:<spec-path> /output:<output-path> /namespace:<namespace> /classname:<classname>
```

Replace:
- `<spec-path>` — local file path (`./openapi.json`) OR URL (`https://api.example.com/openapi.json`)
- `<output-path>` — where tool writes generated code (defaults to `.gen/client.<ext>` if omitted)
- `<namespace>` — code namespace/module wrapper
- `<classname>` — client class name

## Setup (First Time)

### dotnet dnx

Install globally:
```bash
dotnet tool install --global dotnet-dnx
```

Update:
```bash
dotnet tool update --global dotnet-dnx
```

Verify:
```bash
dotnet dnx --help
```

### nswag

Install globally:
```bash
dotnet tool install --global NSwag.ConsoleCore
```

Verify:
```bash
nswag --help
```

## Common Patterns

### Pattern 1: Quick Generation (Uses `.gen` Default)
```bash
dotnet dnx ./openapi.json
```

Generates to `.gen/client.ts` (or appropriate extension). Perfect for one-off client generation.

### Pattern 2: Custom Output Location
```bash
dotnet dnx ./openapi.json --output-file ./src/generated/api-client.ts --namespace MyApi.Generated
```

### Pattern 3: Generate from Remote URL (Defaults to `.gen`)
```bash
dotnet dnx https://api.example.com/openapi.json
```

**Note:** Remote URLs must be accessible without authentication. If URL access fails or requires auth, download the spec file locally first:
```bash
curl -o openapi.json https://api.example.com/openapi.json
dotnet dnx ./openapi.json
```

### Pattern 4: Config File for Repeated Generation

Create `.nswag` file in project root:
```json
{
  "documentGenerator": {
    "fromDocument": {
      "url": "./openapi.json",
      "output": "./Generated/client.ts",
      "namespace": "api"
    }
  }
}
```

Regenerate anytime with:
```bash
nswag run
```

## Common Flags & Options

### Core Flags
- `--output-file <path>` — Where to write generated code (defaults to `.gen/client.<ext>` if omitted)
- `--namespace <name>` — Code namespace/module name (optional)
- `--classname <name>` — Generated client class name (optional)

### Output Language
By default, tool detects from output file extension:
- `.ts` → TypeScript
- `.cs` → C#
- `.java` → Java
- `.go` → Go

Explicitly set with `--language`:
```bash
dotnet dnx spec.json --output-file client.ts --language TypeScript
```

### Behavior Flags
- `--generate-optional-parameters` — Make optional params truly optional
- `--generate-contracts` — Generate request/response contracts separately
- `--generate-async` — Generate async methods (if language supports)
- `--generate-sync` — Generate sync methods (if language supports)

**See full options:**
```bash
dotnet dnx --help
nswag --help
```

## Troubleshooting

### "Command not found: dotnet dnx"

**Fix:** Install the tool:
```bash
dotnet tool install --global dotnet-dnx
```

Or verify it's installed:
```bash
dotnet tool list --global
```

### "Invalid OpenAPI specification"

**Check:**
- Spec syntax: validate at https://editor.swagger.io/
- Format: JSON or YAML (both supported)
- OpenAPI version: 3.0.x or 3.1.x (2.0 Swagger may need migration)

**Validate with:**
```bash
dotnet dnx <spec-path> --validate  # if supported
```

### Remote URL fails to download spec

**Fix:** Download the spec locally first:
```bash
curl -o openapi.json https://api.example.com/openapi.json
dotnet dnx ./openapi.json --output-file ./client.ts --namespace api
```

If curl isn't available on Windows, use PowerShell:
```powershell
Invoke-WebRequest -Uri https://api.example.com/openapi.json -OutFile openapi.json
```

### Generation succeeds but output file missing

**Check:**
- Output directory exists (create if needed: `mkdir Generated`)
- Path is writable (check permissions)
- Use absolute paths if relative paths fail

### Generated code has errors

**Common cause:** Spec contains unsupported features for target language

**Fix:**
- Check for unresolved `$ref` or circular references in spec
- Update spec or tool to latest version
- Run with verbose flag: `dotnet dnx <spec> --verbose`

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Want custom location but forget `--output-file` | Use `--output-file <path>` to override `.gen` default |
| Wrong parameter name (`--out` instead of `--output-file`) | Check flags: use `--help` |
| Remote URL requires authentication | Download spec locally and use file path instead |
| Output goes to console instead of file | Ensure output flag is present (or use `.gen` default) |
| Using `swagger2csharp` (old command) | Use `openapi2csharp` or newer `dotnet dnx` |
| Not validating spec before generation | Invalid specs may produce unusable code |

## What You Get

Generated client includes:
- **Typed client class** for making HTTP calls
- **Model/DTO classes** matching spec schemas
- **Endpoint methods** for each API operation
- **Type safety** on request/response validation
- **Language-specific patterns** (async/await, generics, etc.)

## Workflow: Regenerate After Spec Changes

When the OpenAPI spec changes:

**Simple regeneration (uses `.gen` default):**
```bash
# Download latest spec (if remote)
curl -o openapi.json https://api.example.com/openapi.json

# Regenerate client to .gen/
dotnet dnx ./openapi.json
```

**Custom location regeneration:**
```bash
curl -o openapi.json https://api.example.com/openapi.json
dotnet dnx ./openapi.json --output-file ./src/generated/client.ts --namespace api
```

If using config file (`.nswag`), just:
```bash
nswag run
```
