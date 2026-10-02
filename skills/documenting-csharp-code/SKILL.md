---
name: documenting-csharp-code
description: Guides C# developers in writing and reviewing comments and XML documentation that remain useful, durable, contract-focused, and concise
---

# Documenting C# Code

Write for a maintainer who sees the completed code without knowing the task or implementation history. Comments and documentation describe the code as it exists; they are not a changelog.

## When to Use

Use when writing or reviewing C# comments or XML documentation, especially public API documentation.

## Decide Whether to Comment

Prefer self-explanatory code. Before writing a comment, consider whether clearer names, types, structure, or control flow would explain the code better.

Omit a comment when it only:

- Restates a name, type, signature, or obvious control flow.
- Describes what the next line does.
- Documents an obvious property, constructor, or CRUD operation.
- Exists to satisfy documentation coverage.

Add a comment only when it provides durable information a maintainer cannot readily get from the code. Useful subjects include non-obvious constraints, invariants, compatibility requirements, external-system behavior, edge cases, ordering or concurrency guarantees, and externally observable semantics.

## Keep XML Documentation Timeless

XML documentation is read by a consumer with no history: a new cloner, a package user, generated docs, IntelliSense. It must be evergreen on its own, with no session or task context attached.

Do not refer to the current task, prompt, ticket, pull request, implementation history, motivating feature, or a caller or workflow that is not part of the contract. Avoid changelog phrasing such as “adds support for,” “now supports,” “added for,” “needed by,” and “changed to.”

Describe the capability or permanent constraint instead of who requested or uses it. Preserve historical context only when it explains an enduring, technical requirement, such as a wire-compatibility constraint — a fact about the protocol or system that holds regardless of which caller exercises it. Link to an authoritative specification when it is needed to understand or preserve that requirement.

A commercial or compliance rationale is not this kind of requirement, even when it is phrased as a general-sounding fact: a partner's contract terms, a customer's audit requirement, a margin or surcharge calculation, or a specific deal. This applies to shared code as much as to code written for one caller — a rule added for one partner or customer, once it lives in a method every caller shares, must read as a platform rule in its XML documentation, not as that caller's reason for the rule. State the rule the code enforces (the threshold, the condition, the exception) and leave out whose contract, audit, or cost model produced it.

This strictness is specific to XML documentation. Inline comments are a different audience and a different rule — see below.

## Choose the Right Documentation

### XML documentation

Document public API contracts: behavior observable by callers, meaningful parameter or return semantics, side effects, exceptions, idempotency, ordering, concurrency, ownership, and limitations. Do not document private implementation details as public contract.

Do not generate XML for every public symbol mechanically. A self-explanatory signature may need no documentation. In particular, omit parameter text that merely repeats a parameter name or type, and omit boilerplate such as “A task representing the asynchronous operation.” When documentation adds value, keep the summary concise and make each tag add information not already apparent from the signature.

Use XML references where they clarify prose:

- `<see cref="TypeName"/>` for types and members.
- `<paramref name="value"/>` and `<typeparamref name="T"/>` for parameters.
- `<see langword="null"/>`, `<see langword="true"/>`, and other C# keywords.
- `<c>identifier</c>` for code identifiers, protocol values, and literals.

Use `<remarks>` only for contract context that does not belong in the summary. Keep it brief; do not repeat the summary, list implementation steps, or reproduce details already clear from code.

Describe exception conditions directly in `<exception>` text; omit “Thrown when.” Use separate exception tags when the conditions need to be distinguished.

### Inline comments

Inline (`//`) comments are read by a maintainer browsing the same codebase, not by a consumer of generated documentation — a different audience from XML docs, with more latitude. A trailing reference to a ticket, work item, or PR (for example `// see JIRA-1234`) is a legitimate way to link a line to its history and is not a problem to fix.

Explain why the implementation must preserve a non-obvious behavior, not what the next line does. Prefer a concise explanation of the constraint or consequence. If a comment becomes inaccurate when implementation details change but the contract does not, it likely belongs in code or should be removed.

Whatever an inline comment says, do not let it substitute for, or migrate into, the XML documentation on the member it annotates — the strict rule above applies there regardless of what the inline comment nearby says.

## Review Every Comment

For each added or modified **XML documentation** comment, check:

- Would it make sense to a new cloner with no history on this code?
- Does it explain a useful contract, constraint, reason, or edge case?
- Does it merely repeat names, types, code, or control flow?
- Does it expose an implementation detail that is not part of the contract?
- Does it justify a rule by one customer's, partner's, or deal's business terms (margin, surcharge, contract clause, compliance audit) instead of stating the rule itself?
- Could clearer code remove the need for it?
- Will it remain accurate as implementation details evolve?

Delete or rewrite XML documentation that fails these checks. Inline comments only need the lighter bar above. See [examples.md](examples.md) for C# examples, including patterns drawn from application code.
