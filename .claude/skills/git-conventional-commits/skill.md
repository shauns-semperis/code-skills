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

**DON'T write task lists:**
```
❌ Bad:
- Added PDF service
- Updated API endpoint
- Wrote tests
```

**DO explain intent:**
```
✅ Good:
This allows users to export reports offline, addressing feedback that 
stakeholders need print-friendly formats.

Implementation adds PDF generation service with /api/reports/export endpoint
and tests covering error handling.
```

## Commit Types

| Type | When to Use |
|------|-------------|
| feat | New feature for users |
| fix | Bug fix |
| docs | Documentation only |
| style | Formatting, no behavior change |
| refactor | Code cleanup, no behavior change |
| perf | Performance improvement |
| test | Adding/fixing tests |
| build | Build system or dependency changes |
| ci | CI configuration changes |
| chore | Maintenance or cleanup |
| revert | Undoing previous commit |

## Scopes (Optional)

Use short nouns to identify subsystem:

✅ Good: `fix(auth): handle missing claims`

❌ Too verbose: `fix(authentication-handler): handle missing claims`

Common scopes: auth, api, db, ui, ci, docs

## Breaking Changes

Mark breaking changes with `!` after type/scope:

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

This allows users to export reports offline, addressing stakeholder 
feedback for print-friendly formats.

Implementation includes PDF generation service, /api/reports/export 
endpoint, and frontend export button with comprehensive test coverage.
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
| Task list in body | Explain problem/goal, not activities |
| Vague summary ("update auth") | Be specific ("add token refresh rotation") |
| Breaking change not marked | Add `!` or BREAKING CHANGE footer |
| Description restates diff | Explain WHY, not what files changed |

## The Bar

A good commit message helps future-you understand:
- What problem were we solving?
- Why this approach?

**Test:** If the body could be replaced by reading the diff, rewrite it.
If it's a checklist of files, rewrite it.
If it feels human and clear, it's good.
