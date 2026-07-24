---
name: dotnet-public-api-design
description: Design stable, compatible public APIs using extend-only design. Manage API compatibility, versioning, naming conventions, parameter ordering, and wire format changes for NuGet packages.
---

# Public API Design and Compatibility

Guides design of public APIs for .NET libraries using extend-only principles. Prevents breaking changes that force users to upgrade involuntarily.

## When to Use This Skill

- Designing public APIs for NuGet packages
- Changing existing public APIs
- Planning wire format changes for distributed systems
- Reviewing PRs for accidental breaking changes
- Implementing versioning strategies

---

## The Three Types of Compatibility

Breaking any of these creates forced upgrades for users.

| Type | Definition | Scope |
|------|------------|-------|
| **Source (API)** | Code compiles against new version | Public signatures, types |
| **Binary** | Compiled code runs against new version | Assembly layout, method tokens |
| **Wire** | Serialized data readable across versions | Network protocols, persistence |

---

## Extend-Only Design

Foundation of stable APIs: **never remove or modify, only extend**. This principle governs all breaking-change decisions.

### Three Pillars

1. **Previous functionality is immutable** — Once released, behavior and signatures are locked. Full stop.
2. **New functionality through new constructs** — Add overloads, new types, new methods. Never reuse old names for new things.
3. **Removal only after long deprecation** — Minimum one minor version, preferably 2-3. Users need time to upgrade.

### Removal Timeline Example

```csharp
// v1.0 — original API
[Obsolete("Removed in v1.5. Use ProcessAsync instead.")]
public void Process(Order order) { }

// v1.1 — new replacement
public Task ProcessAsync(Order order, CancellationToken ct = default) { }

// v1.5 — earliest safe removal (users had 5 releases to migrate)
// Process() is removed, but ProcessAsync() has been stable for 4 releases
```

**Key principle**: Announce removal dates in release notes. Let users plan. The Obsolete message should name a specific version and a clear replacement.

### Coexistence Over Replacement

```csharp
// AVOID — breaking change
public void Configure(string setting, int value);  // Was: Configure(string setting, string value)

// CORRECT — extend-only
[Obsolete("Use ConfigureInt instead.", false)]  // false = doesn't break build
public void Configure(string setting, string value) 
    => ConfigureInt(setting, int.Parse(value));

public void ConfigureInt(string setting, int value) 
    => /* actual implementation */;
```

When you need to change behavior, add new members, mark old ones `[Obsolete]`, let them live for a major version, then remove.

### Key Benefits

- Old code continues working in new versions
- Users can upgrade at their own pace — no forced migration
- Upgrades are non-breaking by default
- Your API becomes a contract, not a moving target

---

## Naming Conventions for Public APIs

### Type Naming

| Type | Suffix Pattern | Example |
|------|---------------|---------|
| Base class | `Base` suffix only if abstract | `ValidatorBase` |
| Interface | `I` prefix | `IWidgetFactory` |
| Exception | `Exception` suffix | `WidgetNotFoundException` |
| Attribute | `Attribute` suffix | `RequiredPermissionAttribute` |
| Event args | `EventArgs` suffix | `WidgetCreatedEventArgs` |
| Options/config | `Options` suffix | `WidgetServiceOptions` |
| Builder | `Builder` suffix | `WidgetBuilder` |

### Method Naming

| Pattern | Convention | Example |
|---------|-----------|---------|
| Synchronous | Verb or verb phrase | `Calculate()`, `GetWidget()` |
| Asynchronous | `Async` suffix | `CalculateAsync()`, `GetWidgetAsync()` |
| Boolean query | `Is`/`Has`/`Can` prefix | `IsValid()`, `HasPermission()` |
| Try pattern | `Try` prefix, `out` parameter | `TryGetWidget(int id, out Widget widget)` |
| Factory | `Create` prefix | `CreateWidget()` |
| Conversion | `To`/`From` prefix | `ToDto()`, `FromEntity()` |

**Avoid abbreviations in public APIs** — spell out all words. `GetRecentTransactions(int count)` not `GetRecentTxns(int cnt)`.

---

## Parameter Ordering

Consistent ordering reduces cognitive load. Standard progression:

1. **Target/subject** — the primary entity being operated on
2. **Required parameters** — essential inputs without defaults
3. **Optional parameters** — inputs with sensible defaults
4. **CancellationToken** — always last (required by analyzer CA1068)

```csharp
public Task<Widget> GetWidgetAsync(
    int widgetId,                                          // 1. Target
    WidgetOptions options,                                 // 2. Required
    bool includeHistory = false,                           // 3. Optional
    CancellationToken cancellationToken = default);        // 4. Always last (CA1068)
```

**Why CA1068 matters**: Async methods can be awaited at callsites, and `CancellationToken` should always be the rightmost parameter so overloads can progressively add optional parameters without forcing callers to specify the token. Placing it elsewhere breaks the overload chain.

---

## Return Type Selection

| Scenario | Return Type | Rationale |
|----------|------------|-----------|
| Single entity, always exists | `Widget` | Throw if not found |
| Single entity, may not exist | `Widget?` | Nullable signals optionality |
| Collection, possibly empty | `IReadOnlyList<Widget>` | Immutable, indexable |
| Streaming results | `IAsyncEnumerable<Widget>` | Avoids buffering entire set |
| Operation result with detail | `Result<Widget>` | Rich error info without exceptions |
| Void with async | `Task` | Never `async void` except event handlers |

**Prefer `IReadOnlyList<T>` over `IEnumerable<T>`** — callers can't tell if the collection is materialized or lazy. Use `IAsyncEnumerable<T>` explicitly for streaming.

---

## Error Reporting

### Exception Hierarchy

```csharp
public class WidgetServiceException : Exception
{
    public WidgetServiceException(string message) : base(message) { }
    public WidgetServiceException(string message, Exception inner) : base(message, inner) { }
}

public class WidgetNotFoundException : WidgetServiceException
{
    public int WidgetId { get; }
    public WidgetNotFoundException(int widgetId)
        : base($"Widget {widgetId} not found.") => WidgetId = widgetId;
}
```

### When to Use Each Strategy

| Approach | Use When |
|----------|----------|
| Exception | Unexpected failures, programming errors, infrastructure problems |
| Return `null` / `default` | "Not found" is a normal, expected outcome |
| Try pattern (`bool` + `out`) | Parsing/validation where failure is common and synchronous |
| Result object | Multiple failure modes users need to distinguish |

---

## Safe and Unsafe Changes

### Safe Changes (Any Release)

```csharp
// ADD new overloads with default parameters
public void Process(Order order, CancellationToken ct = default);

// ADD new optional parameters
public void Send(Message msg, Priority priority = Priority.Normal);

// ADD new types
public interface IOrderValidator { }
public enum OrderStatus { Pending, Complete }

// ADD new members to existing types
public class Order
{
    public DateTimeOffset? ShippedAt { get; init; }  // NEW
}
```

### Unsafe Changes (Never or Major Version Only)

```csharp
// REMOVE or RENAME public members
public void ProcessOrder(Order order);  // Was: Process()

// CHANGE parameter types, order, or count (without default)
public void Process(int orderId);  // Was: Process(Order order)

// CHANGE return types
public Order? GetOrder(string id);  // Was: public Order GetOrder()

// CHANGE access modifiers
internal class OrderProcessor { }  // Was: public

// ADD required parameters without defaults
public void Process(Order order, ILogger logger);  // Breaks callers!
```

### Deprecation Pattern

```csharp
// Step 1: Mark as obsolete with version
[Obsolete("Obsolete since v1.5.0. Use ProcessAsync instead.")]
public void Process(Order order) { }

// Step 2: Add new recommended API
public Task ProcessAsync(Order order, CancellationToken ct = default);

// Step 3: Remove in next major version
```

---

## Wire Format Evolution

For distributed systems, serialized data must work across versions. Require both directions for zero-downtime rolling upgrades:

- **Backward compatibility**: Old writers → New readers (readers must handle old format)
- **Forward compatibility**: New writers → Old readers (writers must avoid new features during rollout)

### Four-Phase Rollout Strategy

**Phase 1: Read-side support** (release v1.1)
Deploy readers that understand BOTH old and new message formats. Old and new writers still produce v1 format.

```csharp
public object Deserialize(byte[] data, string manifest) => manifest switch
{
    "Heartbeat" => DeserializeHeartbeatV1(data),
    "HeartbeatV2" => DeserializeHeartbeatV2(data),  // Can read new, but not yet producing it
    _ => throw new NotSupportedException()
};
```

**Phase 2: Write-side support** (release v1.2, AFTER all readers upgraded)
Only after all nodes read both formats, enable writers to produce new format. Old format still readable.

**Phase 3: Default to new format** (release v2.0, next major)
Make new format the default. Old format still read for backward compatibility.

**Phase 4: Remove old format** (release v3.0, only in next major)
Drop support for old format entirely.

**Key principle**: Always deploy readers before writers. If a new node writes but old nodes haven't upgraded their readers, you've broken production.

### Defensive Serialization

```csharp
public sealed class WidgetDto
{
    [JsonPropertyName("id")]
    public int Id { get; init; }

    [JsonPropertyName("name")]
    public required string Name { get; init; }

    [JsonPropertyName("category")]
    public string? Category { get; init; }  // Null if missing — gracefully handles removal

    [JsonPropertyName("priority")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public int Priority { get; init; }  // Don't send default — receivers ignore missing

    // When reading old messages, this new field will be null:
    [JsonPropertyName("sku")]
    public string? Sku { get; init; }
}
```

**Critical patterns:**
1. **Use `[JsonPropertyName]` always** — names your contract separately from code, so renaming code doesn't break wire format
2. **Make new properties nullable** — old messages won't have them
3. **Use `[JsonIgnore(WhenWritingDefault)]`** — don't pollute messages with default values
4. **Test deserialization of old format** — deserialize real v1 messages to confirm new code handles them

**Enum serialization**: Use `[JsonConverter(typeof(JsonStringEnumConverter))]` for string-based enums. Integer-based enums break when members are reordered or a new value is inserted mid-list.

---

## Builder Pattern vs Options

Both allow optional configuration, but differ in versioning safety and discoverability.

### Options Pattern (Preferred for Versioning)

```csharp
public class WidgetServiceOptions
{
    public int MaxRetries { get; set; } = 3;
    public TimeSpan Timeout { get; set; } = TimeSpan.FromSeconds(30);
    public Func<Widget, Task>? OnCreated { get; set; }
}

public Task<Widget> CreateWidgetAsync(WidgetOptions options, CancellationToken ct = default);
```

**Advantages:**
- Adding new properties is a non-breaking change (they have defaults)
- Immutable if you use `init` or sealed records
- Works well with dependency injection and serialization
- Testable: callers can easily override specific properties

**When to use:** Most scenarios, especially libraries with frequent feature additions.

### Builder Pattern

```csharp
public class WidgetBuilder
{
    private int _maxRetries = 3;
    private TimeSpan _timeout = TimeSpan.FromSeconds(30);

    public WidgetBuilder WithMaxRetries(int count) { _maxRetries = count; return this; }
    public WidgetBuilder WithTimeout(TimeSpan ts) { _timeout = ts; return this; }
    public Task<Widget> BuildAsync(CancellationToken ct = default) { /* ... */ }
}
```

**Advantages:**
- Fluent syntax: chainable method calls
- Intermediate validation per step
- Can enforce state machine (e.g., "must call WithName before Build")

**Disadvantages:**
- Mutable state; harder to thread-safe usage
- Extending with new options requires new methods (more surface area)
- Less suitable for serialization/DI patterns

**When to use:** Complex object construction with interdependent validation or step-wise constraints.

### Recommendation

Start with **Options** (sealed record or class with `init` properties). Adopt **Builder** only if you need strict state validation during construction or fluent chaining matters more than discoverability.

---

## Extension Points

Prefer interfaces over delegates for complex extensions; use delegates for simple hooks.

```csharp
public interface IWidgetValidator
{
    ValueTask<bool> ValidateAsync(Widget widget, CancellationToken ct = default);
}

public class WidgetServiceOptions
{
    public Func<Widget, CancellationToken, ValueTask>? OnWidgetCreated { get; set; }
}
```

**Extension method guidelines**:
- Place in same namespace as extended type (discoverable without extra `using`)
- Never extend `System` or `System.Linq` (namespace pollution)
- Prefer instance methods when you own the type
- Keep `this` parameter as specific as usable type

### Extending Interfaces Safely

Adding methods to a public interface breaks implementations. Instead:

```csharp
// v1.0
public interface IWidgetFactory
{
    Widget Create(string name);
}

// v2.0 — add new interface instead
public interface IWidgetFactoryV2 : IWidgetFactory
{
    Widget CreateAdvanced(string name, WidgetOptions options);
}

// Or use default implementations (.NET 8+)
public interface IWidgetFactory
{
    Widget Create(string name);

    // New method with default — old implementations still work
    public virtual Widget CreateAdvanced(string name, WidgetOptions options)
        => throw new NotImplementedException("This version doesn't support advanced creation.");
}
```

The second approach (default implementations) is safer if all implementations are within your control.

---

## API Approval Testing

Prevent accidental breaking changes with automated surface testing.

```csharp
[Fact]
public Task ApprovePublicApi()
{
    var api = typeof(MyLibrary.PublicClass).Assembly.GeneratePublicApi();
    return Verify(api);
}
```

PR reviewers see exact API surface changes in `.verified.txt` diffs. Breaking changes are immediately visible.

---

## API Approval Testing

Prevent accidental breaking changes with automated tracking of the public API surface.

### PublicApiGenerator (Community Standard)

Generates a human-readable text dump of your entire public API:

```csharp
[Fact]
public Task ApprovePublicApi()
{
    var publicApi = typeof(MyLibrary.PublicClass).Assembly.GeneratePublicApi();
    return Verify(publicApi);  // Works with Verify, xUnit, ApprovalTests
}
```

Produces a `.verified.txt` file (checked into git) that tracks every public method, property, and type. PRs that change the API surface produce a diff in the test output — reviewers see exactly what changed before approving. This makes API changes visible and reviewable.

### Microsoft.DotNet.ApiCompat (Official, SDK-Built)

The canonical tool for binary compatibility checking. Enable in your project:

```xml
<PropertyGroup>
  <EnablePackageValidation>true</EnablePackageValidation>
  <PackageValidationBaselineVersion>1.0.0</PackageValidationBaselineVersion>
</PropertyGroup>
```

Runs automatically on `dotnet pack` and verifies:
- No breaking changes vs. the baseline version
- Consistent API across all target frameworks (multi-targeting)
- No "applicability holes" between runtime versions

Use both: PublicApiGenerator catches changes at PR time (fast, in test output); ApiCompat gates the release pipeline against shipped baselines (catches binary-only breaks).

---

## Semantic Versioning (Practical)

| Version | Allowed Changes |
|---------|-----------------|
| **Patch** (1.0.x) | Bug fixes, security patches |
| **Minor** (1.x.0) | New features, deprecations, obsolete removal |
| **Major** (x.0.0) | Breaking changes, old API removal |

Never remove without deprecation period. Even major versions should be announced.

---

## Common Mistakes

1. **Do not place CancellationToken before optional parameters** — CA1068 enforces last
2. **Do not return mutable collections** — use `IReadOnlyList<T>` not `List<T>`
3. **Do not use `async void`** — return `Task` or `ValueTask`
4. **Do not add required parameters to existing methods** — add overload or use defaults
5. **Do not change serialized property names without `[JsonPropertyName]`**
6. **Do not abbreviate in public API names** — spell out words completely
7. **Do not design exception hierarchies without a base library exception**
8. **Do not silently change behavior** (e.g., swapping defaults) — it breaks users
9. **Do not put extension methods in `System` namespace**

---

## Resources

- [Framework Design Guidelines](https://learn.microsoft.com/dotnet/standard/design-guidelines/)
- [Breaking changes reference](https://learn.microsoft.com/dotnet/core/compatibility/categories)
- [Extend-Only Design](https://aaronstannard.com/extend-only-design/)
- [OSS Compatibility Standards](https://aaronstannard.com/oss-compatibility-standards/)
- [PublicApiGenerator](https://github.com/PublicApiGenerator/PublicApiGenerator)
