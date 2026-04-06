# C# Documentation Examples

Detailed before/after patterns from baseline testing and Microsoft .NET conventions.

## Summary Patterns

### ❌ WRONG: Verbose, Multiple Actions

```csharp
/// <summary>
/// Asynchronously processes data from a stream and returns the results to the caller.
/// </summary>
public async Task<ProcessingResult> ProcessDataAsync(Stream input, CancellationToken cancellationToken)
```

**Problems:**
- "and returns the results" - redundant with `<returns>`
- "to the caller" - obvious filler
- "Asynchronously" - redundant with `async Task<T>` signature

### ✅ CORRECT: Concise, Single Action

```csharp
/// <summary>
/// Processes data from the input stream.
/// </summary>
public async Task<ProcessingResult> ProcessDataAsync(Stream input, CancellationToken cancellationToken)
```

---

## Parameter Descriptions

### ❌ WRONG: Over-Detailed, Lists Properties

```csharp
/// <param name="validationParameters">The token validation parameters containing issuer, audience, signing keys, and other validation settings.</param>
```

**Problem:** Lists internal properties of the parameter type. Those details belong in `TokenValidationParameters` documentation.

### ✅ CORRECT: Purpose-Focused

```csharp
/// <param name="validationParameters">Parameters for token validation.</param>
```

**OR even simpler:**

```csharp
/// <param name="validationParameters">The validation parameters.</param>
```

---

## Return Descriptions

### ❌ WRONG: Redundant Boilerplate

```csharp
/// <returns>
/// A task that represents the asynchronous operation. The task result contains a 
/// TokenValidationResult with the processed data and success status.
/// </returns>
```

**Problems:**
- "A task that represents the asynchronous operation" - boilerplate for all `Task<T>` methods
- "The task result contains" - obvious from signature

### ✅ CORRECT: Value Description Only

```csharp
/// <returns>The validation result and status.</returns>
```

**OR simpler when return type is self-documenting:**

```csharp
/// <returns>The validation result.</returns>
```

---

## Property Documentation

### ❌ WRONG: Obvious "Gets or Sets"

```csharp
/// <summary>
/// Gets or sets the user's name.
/// </summary>
public string Name { get; set; }

/// <summary>
/// Gets or sets the user's email address.
/// </summary>
public string Email { get; set; }
```

**Problem:** "Gets or sets" adds zero value. Property name already communicates purpose.

### ✅ CORRECT: Skip or Be Minimal

```csharp
// Option 1: No documentation (acceptable for obvious DTOs/models)
public string Name { get; set; }
public string Email { get; set; }

// Option 2: Minimal if clarification adds value
/// <summary>Display name.</summary>
public string Name { get; set; }

/// <summary>Primary contact email.</summary>
public string Email { get; set; }
```

---

## Type References

### ❌ WRONG: Plain Text Type Names

```csharp
/// <summary>
/// Sends an HttpRequestMessage and returns HttpResponseMessage.
/// </summary>
public HttpResponseMessage Send(HttpRequestMessage request)
```

**Problem:** Type names as plain text prevent IDE navigation and doc generation tools from creating links.

### ✅ CORRECT: Use `<see cref="">`

```csharp
/// <summary>
/// Sends an HTTP request.
/// </summary>
/// <param name="request">The <see cref="HttpRequestMessage"/> to send.</param>
/// <returns>The <see cref="HttpResponseMessage"/> from the server.</returns>
public HttpResponseMessage Send(HttpRequestMessage request)
```

---

## Keywords and Literals

### ❌ WRONG: Plain Text Keywords

```csharp
/// <returns>
/// true if the value is null or empty; otherwise, false.
/// </returns>
```

**Problem:** Keywords as plain text instead of formatted.

### ✅ CORRECT: Use `<see langword="">`

```csharp
/// <returns>
/// <see langword="true"/> if <paramref name="value"/> is <see langword="null"/> or empty; otherwise, <see langword="false"/>.
/// </returns>
```

### ✅ ALSO CORRECT: Use `<c>` for Identifiers in Prose

```csharp
/// <remarks>
/// The <c>sub</c> claim must be present and the <c>nonce</c> claim must match if provided.
/// </remarks>
```

---

## Remarks Usage

### ❌ WRONG: XML Wall, Restates Code Logic

```csharp
/// <summary>
/// Validates an ID token.
/// </summary>
/// <remarks>
/// <para>This method performs standard JWT validation and additional OpenID Connect-specific validations:</para>
/// <list type="bullet">
/// <item><description>The 'sub' claim must be present and non-empty.</description></item>
/// <item><description>If expectedNonce is provided, the token's nonce claim must match exactly.</description></item>
/// <item><description>If the token has multiple audiences, the 'azp' claim must equal the validated audience.</description></item>
/// <item><description>If accessToken is provided and the token contains an 'at_hash' claim, the hash must be valid.</description></item>
/// </list>
/// </remarks>
public async Task<TokenValidationResult> ValidateIdTokenAsync(...)
{
    // Code clearly shows these validations with inline comments
}
```

**Problems:**
- Wall of XML tags hard to read
- Four bullet points for what could be 1-2 sentences
- Restates what inline code comments already explain
- Doesn't work out of context (IntelliSense truncates)

### ✅ CORRECT: Concise or Skip Entirely

**Option 1: No `<remarks>` (preferred when code comments are clear)**

```csharp
/// <summary>
/// Validates an OpenID Connect ID token.
/// </summary>
public async Task<TokenValidationResult> ValidateIdTokenAsync(...)
```

**Option 2: Brief context if valuable**

```csharp
/// <summary>
/// Validates an OpenID Connect ID token.
/// </summary>
/// <remarks>
/// Validates standard JWT claims plus OpenID Connect requirements (sub, nonce, azp, at_hash).
/// </remarks>
```

**Option 3: Reference spec for non-obvious context**

```csharp
/// <summary>
/// Validates an OpenID Connect ID token.
/// </summary>
/// <remarks>
/// Implements OpenID Connect Core 1.0 §3.1.3.7 validation requirements.
/// </remarks>
```

---

## Exception Documentation

### ❌ WRONG: Verbose "Thrown when", Multiple Parameters

```csharp
/// <exception cref="ArgumentNullException">Thrown when <paramref name="httpClient"/> is null.</exception>
/// <exception cref="ArgumentException">Thrown when <paramref name="tokenEndpoint"/>, <paramref name="clientId"/>, or <paramref name="refreshToken"/> is null or whitespace.</exception>
```

**Problems:**
- "Thrown when" is redundant (that's what `<exception>` means)
- Multiple parameters in one exception tag loses precision
- "is null" instead of `<see langword="null"/>`

### ✅ CORRECT: Concise, One Exception Per Parameter

```csharp
/// <exception cref="ArgumentNullException"><paramref name="httpClient"/> is <see langword="null"/>.</exception>
/// <exception cref="ArgumentException"><paramref name="tokenEndpoint"/> is <see langword="null"/> or empty.</exception>
/// <exception cref="ArgumentException"><paramref name="clientId"/> is <see langword="null"/> or empty.</exception>
/// <exception cref="ArgumentException"><paramref name="refreshToken"/> is <see langword="null"/> or empty.</exception>
```

### ✅ ACCEPTABLE: Grouped When Many Similar Validations

```csharp
/// <exception cref="ArgumentException">A required parameter is <see langword="null"/> or empty.</exception>
```

**Use grouped exceptions only when:**
- Many similar validations (5+)
- Precision isn't critical to API understanding
- Keeps documentation scannable

---

## Real Microsoft .NET Examples

### String.IsNullOrEmpty

```csharp
/// <summary>
/// Indicates whether the specified string is <see langword="null"/> or an empty string ("").
/// </summary>
/// <param name="value">The string to test.</param>
/// <returns>
/// <see langword="true"/> if the <paramref name="value"/> parameter is <see langword="null"/> or an empty string (""); otherwise, <see langword="false"/>.
/// </returns>
public static bool IsNullOrEmpty([NotNullWhen(false)] string? value)
{
    return value == null || value.Length == 0;
}
```

**Key points:**
- One-sentence summary
- Uses `<see langword="null"/>`
- Uses `<paramref>` to reference parameter
- Return description is precise
- No `<remarks>` - not needed

---

### Enumerable.SelectMany

```csharp
/// <summary>
/// Projects each element to an <see cref="IEnumerable{T}"/> and flattens the result.
/// </summary>
/// <typeparam name="TSource">The type of elements in <paramref name="source"/>.</typeparam>
/// <typeparam name="TResult">The type of elements returned by <paramref name="selector"/>.</typeparam>
/// <param name="source">The sequence to project.</param>
/// <param name="selector">The transform function.</param>
/// <returns>A flattened sequence of results.</returns>
/// <exception cref="ArgumentNullException">
/// <paramref name="source"/> is <see langword="null"/>.
/// -or-
/// <paramref name="selector"/> is <see langword="null"/>.
/// </exception>
public static IEnumerable<TResult> SelectMany<TSource, TResult>(
    this IEnumerable<TSource> source,
    Func<TSource, IEnumerable<TResult>> selector)
```

**Key points:**
- Uses `<typeparam>` for generics
- Uses `<typeparamref>` in type parameter descriptions
- Uses `<see cref="">` for type references
- Concise parameter and return descriptions
- Exception uses "-or-" to separate multiple conditions

---

### String.CopyTo

```csharp
/// <summary>
/// Copies the contents of this string into the destination span.
/// </summary>
/// <param name="destination">The span into which to copy this string's contents.</param>
/// <exception cref="ArgumentException">The destination span is shorter than the source string.</exception>
public void CopyTo(Span<char> destination)
```

**Key points:**
- One sentence summary
- Exception describes the condition, not "Thrown when"
- No `<remarks>` needed

---

## Before/After: Real-World Example

### Before (Baseline Agent Output - Too Verbose)

```csharp
/// <summary>
/// Validates an OpenID Connect ID token according to the OpenID Connect Core 1.0 specification.
/// </summary>
/// <param name="idToken">The ID token to validate.</param>
/// <param name="validationParameters">The token validation parameters containing issuer, audience, signing keys, and other validation settings.</param>
/// <param name="expectedNonce">The nonce value sent in the original authentication request. If provided, the ID token must contain a matching nonce claim.</param>
/// <param name="accessToken">The access token issued alongside the ID token. If provided, the at_hash claim will be validated if present.</param>
/// <param name="cancellationToken">A token to monitor for cancellation requests.</param>
/// <returns>
/// A <see cref="TokenValidationResult"/> indicating whether the token is valid. If validation fails, the result contains details about the failure.
/// </returns>
/// <remarks>
/// <para>This method performs standard JWT validation and additional OpenID Connect-specific validations:</para>
/// <list type="bullet">
/// <item><description>The 'sub' claim must be present and non-empty.</description></item>
/// <item><description>If <paramref name="expectedNonce"/> is provided, the token's nonce claim must match exactly.</description></item>
/// <item><description>If the token has multiple audiences, the 'azp' claim must equal the validated audience.</description></item>
/// <item><description>If <paramref name="accessToken"/> is provided and the token contains an 'at_hash' claim, the hash must be valid.</description></item>
/// </list>
/// </remarks>
public async Task<TokenValidationResult> ValidateIdTokenAsync(...)
```

**Problems:**
- Over-detailed parameter descriptions listing properties
- Verbose `<returns>` with redundant context about failures
- XML wall in `<remarks>` with bullet list
- `<remarks>` restates what code already shows with inline comments

### After (Following Skill - Concise and Clear)

```csharp
/// <summary>
/// Validates an OpenID Connect ID token.
/// </summary>
/// <param name="idToken">The token to validate.</param>
/// <param name="validationParameters">Parameters for token validation.</param>
/// <param name="expectedNonce">Optional nonce to verify against the token's <c>nonce</c> claim.</param>
/// <param name="accessToken">Optional access token for <c>at_hash</c> validation.</param>
/// <param name="cancellationToken">Cancellation token.</param>
/// <returns>The validation result.</returns>
/// <remarks>
/// Implements OpenID Connect Core 1.0 §3.1.3.7 ID Token Validation requirements.
/// </remarks>
public async Task<TokenValidationResult> ValidateIdTokenAsync(...)
```

**Improvements:**
- Summary shortened (spec reference moved to remarks)
- Parameter descriptions concise, purpose-focused
- `<returns>` minimal (return type is self-documenting)
- `<remarks>` is one sentence referencing spec (non-obvious context)
- Uses `<c>` for claim names in prose
- Readable as plain text
- Works out of context in IntelliSense

---

## When to Skip Documentation Entirely

These don't need XML documentation:

### Obvious Properties in DTOs/Models

```csharp
public class User
{
    public string Name { get; set; }
    public string Email { get; set; }
    public int Age { get; set; }
}
```

### Private Implementation Methods

```csharp
private void InternalHelper() { }
```

### Methods Where Code + Inline Comments Are Sufficient

```csharp
public void Process()
{
    // Validate input - ensures all required fields are present
    ValidateInput();
    
    // Transform data - converts to internal format
    TransformData();
    
    // Persist - saves to database with transaction
    PersistData();
}
```

If inline comments clearly explain the logic and there's no public API contract to document, XML docs add no value.
