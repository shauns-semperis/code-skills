---
name: dotnet-coding-conventions
description: Use when writing, editing, or reviewing C# / .NET code - enforces project coding conventions that agents commonly get wrong
---

# .NET Coding Conventions

## Overview

Apply these conventions consistently when writing or reviewing C# code. They reflect idiomatic modern C# (12+) and prevent recurring nits in code review.

## Quick Reference

| Convention | Wrong | Right |
|------------|-------|-------|
| Constructor field assignment | `ThrowIfNull(x); _f = x;` | `_f = x ?? throw new ArgumentNullException(nameof(x))` |
| `ThrowIfNull` standalone guard | `ThrowIfNull(value, nameof(value))` | `ThrowIfNull(value)` — no `nameof` needed |
| Collection initializers (C# 12+) | `new string[] { "a", "b" }` | `["a", "b"]` |
| Using directives — position | namespace before usings | usings before namespace |
| Using directives — hygiene | unsorted, unused usings present | sorted, unused removed |
| Braces — always required | `if (x) DoThing();` | `if (x) { DoThing(); }` |
| Magic strings — used 2+ times | `"my-key"` repeated inline | `const string MyKey = "my-key"` |
| Logging | `_logger.LogInformation($"Order {id}")` | `[LoggerMessage]` source-generated method |

---

## Null Guards

Two valid patterns — choose based on whether you're assigning to a field at the same time.

### `ThrowIfNull` — standalone guard

Use when validating a parameter without immediately assigning it. `[CallerArgumentExpression]` captures the argument name automatically — **do not pass `nameof`**.

```csharp
// ❌ Wrong — nameof is redundant; CallerArgumentExpression already captures "value"
ArgumentNullException.ThrowIfNull(value, nameof(value));

// ✅ Correct — compiler captures "value" automatically
ArgumentNullException.ThrowIfNull(value);

// ✅ Correct — only pass a second argument when the displayed name must differ (rare)
ArgumentNullException.ThrowIfNull(options.Connection, nameof(options));
```

Same applies to sibling methods: `ThrowIfNullOrEmpty`, `ThrowIfNullOrWhiteSpace`, `ThrowIfZero`, `ThrowIfNegative`, etc.

### `?? throw` — combined assign + guard

Use in constructors when assigning to a field. This is a single expression that both null-checks and assigns. Because you are constructing the exception manually, **`nameof` is required** — there is no `[CallerArgumentExpression]` here.

```csharp
// ✅ Correct — nameof IS required; no automatic capture with ?? throw
_logger = logger ?? throw new ArgumentNullException(nameof(logger));
_repository = repository ?? throw new ArgumentNullException(nameof(repository));
```

```csharp
// ❌ Wrong — splitting assign and guard when they can be one expression
ArgumentNullException.ThrowIfNull(logger);
_logger = logger;
```

### Choosing between them

| Situation | Pattern |
|-----------|---------|
| Constructor parameter assigned to a field | `_field = param ?? throw new ArgumentNullException(nameof(param))` |
| Validating a parameter mid-method (no assignment) | `ArgumentNullException.ThrowIfNull(param)` |
| Validating before passing to a base constructor | `ArgumentNullException.ThrowIfNull(param)` |

---

## Collection Initializers (C# 12+)

Prefer the concise `[]` collection expression syntax over `new T[] { }` or `new List<T> { }`.

```csharp
// ❌ Wrong
string[] names = new string[] { "Alice", "Bob" };
var ids = new List<int> { 1, 2, 3 };
IEnumerable<string> empty = Enumerable.Empty<string>();

// ✅ Correct
string[] names = ["Alice", "Bob"];
var ids = new List<int> { 1, 2, 3 };   // ok if List<int> is required by type
List<int> ids = [1, 2, 3];             // better — let the initializer infer
IEnumerable<string> empty = [];
```

**Rule:** Use `[]` whenever the target type is known. Applies to arrays, `List<T>`, `IEnumerable<T>`, `IReadOnlyList<T>`, and other collection types.

---

## Using Directives

Four rules, all required:

1. **Usings before namespace** — never inside or after the namespace declaration.
2. **Sorted** — alphabetically, system namespaces first (Roslyn/Rider default order).
3. **No unused usings** — remove any that aren't needed.
4. **Namespace mismatch** — if the file's namespace doesn't match its folder path, add the suppression comment on the line above the namespace.

```csharp
// ✅ Correct structure
using System;
using System.Collections.Generic;
using MyApp.Core;

// ReSharper disable once CheckNamespace  ← only when namespace ≠ folder path
namespace MyApp.Utilities;
```

```csharp
// ❌ Wrong — usings inside namespace, unsorted, unused
namespace MyApp.Utilities
{
    using System.Text;          // unused
    using System;
    using MyApp.Core;

    public class Foo { }
}
```

---

## Braces on Flow Control

Always use braces for `if`, `else`, `for`, `foreach`, `while`, `do`, and `using` statements — even single-line bodies.

```csharp
// ❌ Wrong
if (value == null)
    return;

for (int i = 0; i < count; i++)
    Process(i);

// ✅ Correct
if (value == null)
{
    return;
}

for (int i = 0; i < count; i++)
{
    Process(i);
}
```

**Exception:** Expression-bodied members (`=>`) are fine and do not need braces.

---

## Magic Strings

If a string literal appears more than once, or represents a named concept (a key, a claim type, a route, a header name), extract it to a constant.

```csharp
// ❌ Wrong — "correlation-id" repeated, easy to typo
if (headers.ContainsKey("correlation-id"))
    logger.Log(headers["correlation-id"]);

// ✅ Correct
private const string CorrelationIdHeader = "correlation-id";

if (headers.ContainsKey(CorrelationIdHeader))
    logger.Log(headers[CorrelationIdHeader]);
```

**Where to put constants:**
- Private to one class → `private const` inside the class
- Shared across a feature → `internal static class` in the same assembly
- Public API / SDK → `public static class` with a descriptive name (e.g. `ClaimTypes`, `HeaderNames`)

---

## Logging

Prefer `[LoggerMessage]` source-generated methods over direct `_logger.LogXxx(...)` calls. The source generator produces zero-allocation, level-checked logging with strongly-typed parameters — no boxing, no string formatting when the level is disabled.

```csharp
// ❌ Wrong — string interpolation allocates unconditionally
_logger.LogInformation($"Processing order {orderId} for user {userId}");

// ❌ Wrong — value types (int, Guid, etc.) are boxed into the params object[] array
_logger.LogInformation("Processing order {OrderId} for user {UserId}", orderId, userId);

// ✅ Correct — source-generated, zero allocation, strongly typed
[LoggerMessage(Level = LogLevel.Information, Message = "Processing order {OrderId} for user {UserId}")]
private partial void LogProcessingOrder(int orderId, string userId);

// Then call:
LogProcessingOrder(order.Id, user.Id);
```

**Setup:** The containing class must be `partial`. The `ILogger` is captured from `this._logger` (injected via constructor as usual).

**Allocation rules — apply to ALL log calls (including `[LoggerMessage]`):**
- Never use string interpolation (`$"..."`) in a log message or argument
- Never call `.ToString()` on a value just to pass it to a log method
- Never construct an object or collection solely to log it — log the individual values instead
- Structured logging placeholders (`{Name}`) must be named, not positional (`{0}`)

**When `[LoggerMessage]` is not practical** (e.g. truly one-off dynamic messages), use the generic overloads that avoid boxing — but still no interpolation:

```csharp
// ✅ Acceptable fallback — generic overload avoids boxing for value types
_logger.LogWarning("Retry attempt {Attempt} of {Max}", attempt, maxRetries);
```

### Log levels

Use the right level. Over-logging at `Information` drowns out signal; under-logging leaves incidents blind.

| Level | Use for |
|-------|---------|
| `Trace` | Step-by-step internal flow — dev/troubleshooting only, never enabled in prod |
| `Debug` | Diagnostic detail useful during development — disabled in prod by default |
| `Information` | Key business events: request received, order placed, user authenticated |
| `Warning` | Unexpected but recoverable: retry triggered, fallback used, config missing optional value |
| `Error` | Operation failed and could not recover — needs attention |
| `Critical` | System-level failure — immediate action required |

**Common mistakes:**
- `Information` for every step of a method — use `Debug` or `Trace`
- `Error` for expected domain failures (e.g. validation, not-found) — use `Warning`
- `Warning` for things that should never happen — use `Error`

### Message quality

Logs are often the only context available during an incident. Write messages that are self-contained and actionable.

```csharp
// ❌ Wrong — meaningless without surrounding context
[LoggerMessage(Level = LogLevel.Error, Message = "Failed")]
private partial void LogFailed();

[LoggerMessage(Level = LogLevel.Information, Message = "Processing")]
private partial void LogProcessing();

// ✅ Correct — identifies what failed, with which inputs, and why
[LoggerMessage(Level = LogLevel.Error, Message = "Payment failed for order {OrderId}: {Reason}")]
private partial void LogPaymentFailed(Guid orderId, string reason);

[LoggerMessage(Level = LogLevel.Information, Message = "Processing payment for order {OrderId}, amount {Amount}")]
private partial void LogProcessingPayment(Guid orderId, decimal amount);
```

**Checklist for every log message:**
- Does it identify *what* entity or resource is involved? (include IDs)
- Does it include *why* (for errors/warnings)?
- Could an on-call engineer act on it without reading the code?

### Logging scopes

When multiple log messages within a unit of work share common properties, add them once via a scope rather than repeating them on every message.

```csharp
// ❌ Wrong — OrderId and UserId repeated on every message
LogValidatingPayment(order.Id, user.Id);
LogChargingCard(order.Id, user.Id);
LogSendingConfirmation(order.Id, user.Id);

// ✅ Correct — shared context set once; all messages inside inherit it
using (_logger.BeginScope(new Dictionary<string, object>
{
    ["OrderId"] = order.Id,
    ["UserId"] = user.Id,
}))
{
    LogValidatingPayment();
    LogChargingCard();
    LogSendingConfirmation();
}
```

Scope is appropriate when:
- 3+ messages in the same operation share 2+ properties
- The properties identify the unit of work (order ID, request ID, tenant ID, user ID)

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `ThrowIfNull(x, nameof(x))` standalone | Remove second argument — `[CallerArgumentExpression]` captures it |
| `_f = x ?? throw new ArgumentNullException()` | Add `nameof(x)` — required here, no automatic capture |
| `ThrowIfNull(x); _f = x;` in constructor | Combine: `_f = x ?? throw new ArgumentNullException(nameof(x))` |
| `new List<string> { "a" }` when `List<string>` is the declared type | `["a"]` |
| `new string[0]` or `Array.Empty<string>()` | `[]` |
| Usings declared after or inside namespace block | Move above namespace |
| Namespace doesn't match folder, no suppression | Add `// ReSharper disable once CheckNamespace` |
| `if (x) return;` (no braces) | Add `{ }` |
| Same string literal in 3 places | Extract to `const` |
| `_logger.LogInformation($"Order {id}")` | Use `[LoggerMessage]` source-generated method |
| `_logger.LogXxx("msg {X}", valueType)` where value type is boxed | Use `[LoggerMessage]` with strongly-typed parameter |
| Log method on non-`partial` class | Make the class `partial` |
| `LogInformation("Processing")` — no entity, no ID | Include what, who, with key identifiers |
| `LogError("Failed")` for a validation/not-found result | Use `LogWarning`; `Error` is for unrecoverable failures |
| `LogInformation` for every step inside a method | Use `Debug` or `Trace`; `Information` is for key business events |
| Same `OrderId`/`UserId` on 3+ messages in one operation | Use `_logger.BeginScope(new Dictionary<string, object> { ["OrderId"] = id, ... })` |

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "`nameof` makes the intent clearer" | The compiler already captures it. It's noise, not clarity. |
| "`new List<T>` is more explicit" | C# 12 target-typed collection expressions are idiomatic. Use `[]`. |
| "Braces add visual clutter for simple cases" | They prevent subtle bugs when lines are added later. Always add them. |
| "The string is only used twice, it's fine inline" | Two uses is the threshold. Extract it. |
| "`_logger.LogInformation` is simpler for one-off messages" | It allocates unconditionally if you use interpolation, and boxes value types. Use `[LoggerMessage]`. |
| "The generic overloads avoid boxing so it's fine" | Only for 1–3 args and only if you never use interpolation. `[LoggerMessage]` is always correct. |
| "The class context makes the message obvious" | Logs are read in bulk, out of order, across services. Write every message to stand alone. |
| "Adding IDs is verbose" | Without IDs, the log is noise. An on-call engineer needs to act without reading the code. |
| "I'll use `Information` so it's always visible" | Overlogging buries real events. Use the correct level so `Information` remains meaningful. |
| "Adding scope is extra ceremony" | Three shared properties on three messages = nine repeated values. Scope removes duplication and improves query filtering. |
