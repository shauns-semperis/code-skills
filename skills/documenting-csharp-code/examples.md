# C# Documentation Examples

Prefer no comment unless it gives a maintainer information that is not clear from the code. The examples below include patterns based on real application code: documenting external-system semantics and explaining why a particular implementation is required.

## Omit Obvious Documentation

❌ **Redundant:** The signature already says that the method deletes a widget by identifier.

```csharp
/// <summary>
/// Deletes a widget by its ID.
/// </summary>
Task DeleteAsync(Guid id);
```

❌ **Task-specific:** Do not document the motivating task or consumer.

```csharp
/// <summary>
/// Deletes widgets so the cleanup service can remove expired records.
/// </summary>
Task DeleteAsync(Guid id);
```

✅ **Contract-focused:** If the behavior has important semantics, document those instead.

```csharp
/// <summary>
/// Permanently deletes the widget.
/// </summary>
/// <remarks>
/// Deletion is idempotent. Deleting an identifier that does not exist succeeds.
/// </remarks>
Task DeleteAsync(Guid id);
```

❌ **Narrates the code:** Skip comments that translate an identifier or operation into prose.

```csharp
// Gets the customer by ID.
var customer = await repository.GetByIdAsync(customerId);
```

✅ **Better:** Omit the comment. Add an inline comment only if there is a non-obvious reason for the operation.

## Document Observable External-System Semantics

An API summary can state the operation while remarks explain surprising behavior callers need to know:

```csharp
/// <summary>
/// Terminates a running or pending workflow instance.
/// </summary>
/// <remarks>
/// The workflow engine may complete this call without error when the instance does not exist or is
/// already terminal. Check the instance status when the outcome must be confirmed.
/// </remarks>
Task TerminateInstanceAsync(string instanceId, string reason);
```

The remarks describe behavior observable by callers and the consequence for their use of the API. They do not narrate the implementation or its history.

## Explain Why, Not What

✅ **Explains why:** Useful inline comments explain why a less careful implementation would be incorrect.

```csharp
// IsInRole, not HasClaim: a role claim counts only when its identity uses the configured role
// claim type, which is what role authorization checks.
var missingRoles = roles.Where(role => !principal.IsInRole(role)).ToList();
```

❌ **Narrates what:** This only describes the call.

```csharp
// Check whether the principal has each role.
var missingRoles = roles.Where(role => !principal.IsInRole(role)).ToList();
```

If a comment is needed to explain a surprising choice, keep the explanation close to the code it constrains.

## Keep Constraints Timeless

❌ **Historical:** Avoid comments that record when or why code was introduced.

```csharp
// We now use ordinal comparison to fix duplicate key handling.
```

✅ **Timeless:** If the reason is a durable constraint, describe that constraint.

```csharp
// Keys are protocol identifiers and must be compared independently of the current culture.
```

Similarly, avoid references to a feature, ticket, or current consumer. State permanent contract or compatibility requirements directly.

## A Business Rule Is Not a Technical Constraint

A rule's reason can read as a general-sounding fact and still be someone's commercial or compliance rationale rather than a durable fact about the system. This is easy to miss in a shared method: the code genuinely becomes general (every caller gets the rule), but the XML documentation explaining *why* the rule exists stays tied to the one customer, partner, or deal that caused it to be added. This matters for XML documentation specifically — it is read by a consumer with no history on the code. An inline comment making the same point, or linking to the ticket that introduced the rule, is normal and not a problem; see "Inline Comments Have More Latitude" below.

❌ **The XML doc reads as general, but states one partner's contract terms:** This is a shared eligibility check used by every checkout channel, not only the partner integration that needed this rule added.

```csharp
/// <remarks>
/// An order of $250 or more does not qualify when it ships to a PO box, because the
/// carrier surcharge for PO box deliveries above that value outweighs the shipping margin.
/// </remarks>
public static bool IsEligibleForFreeShipping(Order order)
{
    if (order.Subtotal < 50m)
    {
        return false;
    }

    if (order.ShippingAddress.IsPoBox && order.Subtotal >= 250m)
    {
        return false;
    }

    return true;
}
```

✅ **The XML doc states the rule, not the deal behind it:** The dollar threshold and the condition are the contract; the surcharge economics that produced them belong in a commit message or linked ticket, not in documentation a new cloner reads with no history.

```csharp
/// <remarks>
/// Free shipping does not apply to orders of $250 or more that ship to a PO box.
/// </remarks>
public static bool IsEligibleForFreeShipping(Order order)
{
    if (order.Subtotal < 50m)
    {
        return false;
    }

    // Carrier surcharges on PO box deliveries make this unprofitable above the threshold (see PART-3307).
    if (order.ShippingAddress.IsPoBox && order.Subtotal >= 250m)
    {
        return false;
    }

    return true;
}
```

Note what moved and what didn't: the `<remarks>` dropped the surcharge/margin rationale entirely, but the inline comment keeps it, including the ticket reference — that's fine, because it's there for a maintainer reading this file, not for a consumer of generated docs.

## Inline Comments Have More Latitude

Inline comments are for whoever is reading this file, not for a package consumer or generated docs. A reference to a ticket, work item, or PR for traceability is normal and welcome, not a defect to fix.

```csharp
// Per SEC-771, enterprise SSO accounts must have non-essential categories muted by
// default before activation, for the customer's security compliance audit.
private static readonly IReadOnlySet<NotificationCategory> EnterpriseDefaultMutedCategories = ...
```

This inline comment is fine as written. What would not be fine is the same sentence inside the class's or member's XML `<summary>`, since that is what a new cloner sees with no history:

```csharp
/// <summary>
/// Default mute policy mapping each account tier to its non-essential notification categories.
/// </summary>
public sealed class DefaultNotificationMutePolicy : IDefaultNotificationMutePolicy
```

An inline comment, a commit message, a design doc, or a linked ticket are all fine places for the business reason behind a threshold or a tier's default. The XML doc is not, since every future caller of the shared code — including ones with no access to that ticket or history — reads it as a statement about the system itself.

## XML Documentation That Adds Meaning

✅ **Adds contract information:** Use XML references to connect useful prose to API symbols. Document parameter constraints and result semantics when they are not apparent from the signature.

```csharp
/// <summary>
/// Parses a TCP port number.
/// </summary>
/// <param name="value">The decimal port number, from 1 through 65535.</param>
/// <returns>The parsed port.</returns>
/// <exception cref="FormatException"><paramref name="value"/> is not a valid decimal port number.</exception>
public static int ParsePort(string value);
```

❌ **Boilerplate:** For a self-explanatory method, omit obvious parameter and return documentation.

```csharp
/// <param name="customerId">The customer ID.</param>
/// <returns>A task representing the asynchronous operation.</returns>
Task<Customer?> GetAsync(Guid customerId);
```

✅ **Precise exception condition:** Use `<exception>` to state the condition without “Thrown when.”

```csharp
/// <exception cref="ArgumentNullException">
/// <paramref name="value"/> is <see langword="null"/>.
/// </exception>
void Process(string value);
```

## Before Adding `<remarks>`

✅ **Useful remarks:** Use remarks only when necessary to understand a contract or preserve a non-obvious constraint. Prefer a short explanation or an authoritative specification reference over a list of implementation steps.

❌ **Implementation narration:** Avoid a list that duplicates validation already evident in the implementation.

```csharp
/// <remarks>
/// The method checks that the subject exists, compares the nonce, validates the audience,
/// and checks the access-token hash.
/// </remarks>
```

If those checks are part of an external contract, describe the contract or cite its specification; otherwise, let the code explain its own steps.
