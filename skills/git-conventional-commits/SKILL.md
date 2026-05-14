---
name: git-conventional-commits
description: Use when writing git commit messages, reviewing commits, or cleaning up commit history - ensures messages follow Conventional Commits spec with clear intent
---

# Git Conventional Commits

## Overview

Write commit messages that explain **why** changes exist, not just what files changed. Follow Conventional Commits specification: `type(scope): summary` with optional body explaining intent.

## When to Use

- Writing any git commit message
- Reviewing commit messages in PRs
- Squashing or cleaning up commit history
- Suggesting improvements to vague commits

**When NOT to use:** Git operations besides commit messages (branching, merging, etc.)

## Quick Reference

| Element | Format | Example |
|---------|--------|---------|
| Summary | `type(scope): verb summary` | `feat(auth): add token refresh` |
| Types | feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert | `fix(api): handle null response` |
| Scope | Short noun (optional) | `(auth)`, `(api)`, `(db)` |
| Breaking | Add `!` or footer | `feat(api)!: change pagination` |
| Body | Blank line, then intent + approach | See examples below |

## Core Pattern

**Summary line rules:**
- Use imperative mood: "add feature" not "added" or "adds"
- Lowercase after colon
- No period at end
- Start with verb
- Explain what changed, not implementation details

**Body format (optional but recommended):**
1. Problem/goal statement
2. Approach taken

**DON'T write task lists** — including task lists disguised as prose. If each clause maps 1:1 to a bullet you could have written, it's still a task list:
```
❌ Bad (bullets):
- Added PDF service
- Updated API endpoint
- Wrote tests

❌ Also bad (same list, commas instead of dashes):
Added PDF generation service, created /api/reports/export endpoint,
and updated frontend with comprehensive test coverage.
```

**DO explain intent** — the problem that motivated the change and why this approach:
```
✅ Good:
Stakeholders need to review reports offline, but the app only supports
on-screen viewing. PDF export addresses this without changing the
existing report rendering pipeline.
```

## Commit Types

| Type | When to Use |
|------|-------------|
| feat | New user-facing feature or behaviour change (users see something different) |
| fix | Something was broken and this corrects it |
| docs | Documentation only |
| style | Formatting, no behavior change |
| refactor | Code cleanup, no behavior change |
| perf | Performance improvement |
| test | Adding/fixing tests |
| build | Build system or dependency changes |
| ci | CI configuration changes |
| chore | Maintenance or cleanup |
| revert | Undoing previous commit |

### Choosing between `feat`, `fix`, and `refactor`

Three-question test:
1. **Was something broken?** → `fix`
2. **Does the user see different behaviour?** → `feat` (new capability, changed defaults, different API shape)
3. **Same external behaviour, different internals?** → `refactor` (swapping libraries, restructuring code, renaming internals)

The key distinction between `feat` and `refactor` is whether **external behaviour changed**. Replacing Newtonsoft.Json with System.Text.Json while preserving the same serialization output is `refactor` — the implementation changed but callers see identical results. Adding a new output format or changing how nulls are serialized would be `feat`.

## Scopes (Optional)

Use short nouns to identify subsystem:

✅ Good: `fix(auth): handle missing claims`

❌ Too verbose: `fix(authentication-handler): handle missing claims`

Common scopes: auth, api, db, ui, ci, docs

## Breaking Changes

Only mark a change as breaking if it affects code that has already been pushed or released. Changing behaviour on a local branch that hasn't been shared can't break anyone — don't add `!` or `BREAKING CHANGE` just because the diff looks significant. Check `git log --oneline @{upstream}..HEAD` or whether the branch has been pushed before deciding.

When a change genuinely breaks existing consumers, mark it with `!` after type/scope:

```
feat(api)!: change pagination to 1-indexed
```

Or use footer:

```
feat(api): change pagination defaults

BREAKING CHANGE: pagination now starts at page=1 instead of page=0
```

## Good vs Bad Examples

### Feature

❌ **Bad** (task list):
```
feat: add PDF export

- Added PDF service
- Created API endpoint
- Updated frontend
```

✅ **Good** (intent + approach):
```
feat(reports): add PDF export functionality

Stakeholders need to review reports offline, but the app only supports
on-screen viewing. PDF export addresses this without changing the
existing report rendering pipeline.
```

### Bug Fix

❌ **Bad** (describes diff):
```
fix: changed X to Y
```

✅ **Good** (problem + solution):
```
fix(auth): normalize email to lowercase before validation

Login form crashed when users entered emails with uppercase letters 
because validation expected lowercase but didn't enforce it.

This normalizes all email input before validation, preventing crashes 
and ensuring consistent behavior.
```

### Refactor

❌ **Bad** (no meaning):
```
refactor: refactor user service
```

✅ **Good** (intent + outcome):
```
refactor(auth): extract token generation into separate service

This improves testability and reduces coupling by isolating token 
generation behind its own service interface.

Previously, token generation was embedded in auth handler, making 
it difficult to test independently. New TokenService handles JWT 
operations, with 15 files updated to use the abstraction.
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Added feature" (past tense) | Use imperative: "add feature" |
| No type prefix | Always start with type: `feat:`, `fix:`, etc. |
| Task list in body (bullets or prose) | Explain problem/goal, not activities — commas don't fix a list |
| Body invents context not in the diff | Only state what you know from the diff, ticket, or conversation |
| Vague summary ("update auth") | Be specific ("add token refresh rotation") |
| Breaking change not marked | Add `!` or BREAKING CHANGE footer |
| `!` on unpushed/unreleased code | Only mark breaking when existing consumers are affected |
| `fix` for a deliberate behaviour change | Use `feat` — `fix` means something was broken |
| `feat` for an internal swap (same output) | Use `refactor` — if users see the same behaviour, it's not a feature |
| Vague filler ("fixes the root issue") | Be specific — name the bug, the behaviour, the cause. If you don't know, ask. |
| Description restates diff | Explain WHY, not what files changed |

## The Bar

A good commit message helps future-you understand:
- What problem were we solving?
- Why this approach?

**Tests:**
- If the body could be replaced by reading the diff, rewrite it.
- If each sentence maps 1:1 to a bullet you could have written, it's still a task list — rewrite it.
- If a claim in the body isn't supported by the diff, the ticket, or context you've actually been given, delete it. Don't invent motivation — a shorter honest body beats a longer fabricated one.
