# dotnet-public-api-design

Guides design of stable, compatible public APIs for .NET libraries using extend-only design principles.

## What It Does

When designing or modifying public APIs for NuGet packages, this skill helps you:

- Avoid breaking changes that force users to upgrade
- Maintain source, binary, and wire compatibility
- Name types and methods consistently
- Order parameters for clarity and extension
- Choose appropriate return types and error handling
- Evolve serialized formats without breaking readers/writers
- Plan deprecations and version bumping

## When to Use It

Trigger this skill when:
- **Designing new public APIs** for a library or NuGet package
- **Modifying existing public APIs** (adding members, changing signatures)
- **Planning wire format changes** in distributed systems (serialization, protocol changes)
- **Reviewing PRs for breaking changes** — catch accidental API breaks before merge
- **Implementing versioning strategies** — decide whether a change warrants a major version bump

Do NOT trigger for:
- Private or internal API design
- Bug fixes in non-breaking internal code
- One-off utilities or scripts

## Prerequisites

- Working knowledge of .NET/C# (you don't need this if you're not writing .NET code)
- Access to your library's public API surface

## Example Usage

**Design scenario**: "I'm adding a new async method to my library. What should I name it and how should the parameters be ordered?"

**Breaking change review**: "Does this PR introduce any breaking changes to our public API? Our library is at v2.4.1."

**Wire format planning**: "We need to add a new field to our serialized message format. How can we do this without breaking older versions still running in production?"
