---
name: documenting-csharp-code
description: Use when writing or reviewing C# XML documentation comments - prevents verbose summaries, obvious property docs, XML walls in remarks, ensures proper cref/paramref/langword tags
---

# Documenting C# Code

## Overview

C# XML documentation should be **concise, focused on contract over implementation, and use proper XML cross-reference tags**. Follow Microsoft .NET conventions: one-sentence summaries, readable as plain text, works out of context (IntelliSense), and skip obvious documentation.

## When to Use

Use when:
- Writing XML documentation (`///`) for C# public APIs
- Reviewing C# documentation for verbosity or clarity issues
- Documenting libraries, SDKs, or internal application APIs

When NOT to use:
- Private implementation methods (documentation optional)
- DTOs/models with self-explanatory properties
- Code with comprehensive inline comments that make XML docs redundant

## Core Principles

1. **Concise by default** - One sentence. No filler words.
2. **Contract, not implementation** - What it does for the caller, not how
3. **Use XML tags** - `<see cref="">`, `<paramref>`, `<typeparamref>`, `<see langword="">`
4. **Readable as text** - Avoid XML walls. If you can't read it easily, it's too verbose.
5. **Works out of context** - IntelliSense shows truncated tooltips; essentials go in `<summary>`
6. **Use `<remarks>` sparingly** - Only for non-obvious context. Most methods don't need it.
7. **Skip obvious documentation** - Self-explanatory code needs no comment

## Quick Reference

| Element | Pattern | Example |
|---------|---------|---------|
| Type reference | `<see cref="TypeName"/>` | `<see cref="HttpResponseMessage"/>` |
| Parameter reference | `<paramref name="param"/>` | `<paramref name="request"/>` |
| Type parameter | `<typeparamref name="T"/>` | `<typeparamref name="TSource"/>` |
| Keywords | `<see langword="keyword"/>` | `<see langword="null"/>`, `<see langword="true"/>` |
| Inline code/identifiers | `<c>code</c>` | `<c>sub</c>`, `<c>at_hash</c>` |
| Summary | One sentence, period | `/// <summary>Validates the token.</summary>` |
| Returns | Describe value, not "returns" | `/// <returns>The validation result.</returns>` |
| Exception | **NEVER "Thrown when"** | `/// <exception cref="ArgumentNullException"><paramref name="value"/> is <see langword="null"/>.</exception>` |
| Remarks | Rare; non-obvious context only | `/// <remarks>Implements RFC 6749 §6.</remarks>` |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Gets or sets the X" | Skip docs or use "X." |
| "Returns a Y that contains Z" | "Z result." |
| "Asynchronously does X and returns Y" | "Does X." (async/returns obvious) |
| "Does X and returns Y" | "Does X." (return type shows Y) |
| "A task representing the asynchronous operation" | Delete; obvious from `Task<T>` signature |
| Plain text type names | Use `<see cref="">` |
| Plain text `null`/`true`/`false` | Use `<see langword="">` |
| Multi-sentence summaries | One sentence maximum |
| Explaining implementation in `<summary>` | Move to `<remarks>` or delete |
| Multi-paragraph `<remarks>` with lists | One sentence or skip entirely |
| `<remarks>` that restate code logic | Delete or reference spec/docs |
| ANY "Thrown when" in exceptions | ALWAYS delete; 100% redundant |
| Multiple params in one `<exception>` tag | Separate for precision |
| Over-detailed param descriptions | Purpose, not properties |

## Red Flags - Stop and Simplify

These indicate documentation is too verbose:

- **More than one sentence in `<summary>`**
- **"Gets or sets" for obvious properties**
- **ANY "and returns" in summary** - Return is obvious from signature and `<returns>` tag
- **"A task representing the asynchronous operation"** - Boilerplate; always delete
- **Lists or multiple `<para>` in `<remarks>`** - Should be one sentence
- **"This method performs..."** - Filler; delete it
- **ANY "Thrown when" in exceptions** - ALWAYS delete; it's 100% redundant
- **Restating method signature in words** - Parameter names already document this

**All of these mean: Simplify. Make it concise.**

## Rationalizations

Agents rationalize violations with these excuses:

| Excuse | Reality |
|--------|---------|
| "But 'and returns X' adds specific info" | No. Return type + `<returns>` tag already document this. Delete "and returns". |
| "The return behavior is non-obvious" | Then explain it in `<returns>`, not `<summary>`. |
| "Async methods need 'A task representing...'" | No. Every `Task<T>` method returns a task. Delete this boilerplate. |
| "One sentence is too limiting" | Microsoft .NET uses one sentence. Follow the pattern. |

**If you're rationalizing verbosity, you're violating the skill. Simplify.**

## Detailed Examples

See [examples.md](examples.md) for detailed before/after comparisons covering:
- Summary patterns
- Parameter descriptions
- Return descriptions
- Property documentation
- Type references
- Keywords and literals
- Remarks usage
- Exception documentation
- Real Microsoft .NET examples
