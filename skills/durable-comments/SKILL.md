---
name: durable-comments
description: Keeps code comments few and free of session context — the ticket, task, feature, requester, dependency versions, dates or debugging story behind a change. Use whenever writing, editing or reviewing comments in any language or config file (inline comments, doc comments, YAML, Dockerfiles, shell scripts), and especially after fixing a bug, bumping a dependency or implementing a ticket, when it is tempting to explain the change in the code. Also use when asked to "add a comment so we don't lose this" or to clean up comments. Defers to the repo's own comment conventions.
---

# Durable Comments

A comment is read by someone who was not in your session, often long after it, with no access to your task, your ticket or your conversation. Write what is true of the code, not of the session that produced it. Most changes need no comment at all.

**The repo sets the rules.** Read its agent instructions, contributing guide, and the comments already in the files you touch. Match their density, prefixes (`TODO`, `NOTE`) and how they reference tickets. Nothing here overrides those. For C# XML documentation, the `documenting-csharp-code` skill has the details.

This is about comments in code and config. Changelogs, ADRs, release notes and postmortems are dated on purpose; leave their history alone.

## Comment what the code cannot say

Worth a comment: a constraint the code must keep, an invariant, units, ordering, what an external system does, what breaks if someone changes this line. Not worth one: what the next line does, a name restated in prose, or the change you just made.

The task you are on feels like the most important fact in the file. To the next reader it is just how the code is. If your edit reads clearly without a comment, leave it without one.

## Keep the session out

These are true of the session, not the code:

- the ticket, feature, PR or person that prompted the change (*"added for SHOP-881"*, *"per Priya"*)
- the change itself (*"was 30"*, *"now uses"*, *"new:"*, *"changed to fix"*)
- the debugging story: what broke, what was tried, how long it took
- facts that drift: the versions you happen to be on, dates, *"currently"*, *"for now"*, *"as of"*, an issue's status, who calls this, how many callers there are

They belong in the commit message or PR description, which are dated and which `git blame` links to every line. If you are not committing, put them in your report as suggested commit text so the user still has them. Don't drop them silently.

## Facts that change: does the code care?

Ask of every version, date, name or number you are about to write: **if this fact changed tomorrow, would this code have to change?**

- **Yes** — it is a constraint. State the constraint, not its history. *"Needs Node ≥ 22.6 for `--experimental-strip-types`"* is a requirement. A workaround for a specific upstream bug gets a `TODO` with the condition for removing it: `# TODO: drop once acme-http#412 is fixed (cert ignored when verify is a path)`.
- **No** — leave it out. *"Uses Polly 8.4.1"* repeats the lock file and turns false at the next bump, and nobody edits comments during a version bump.

**When your change makes a nearby comment incomplete.** A new version, default or option often adds a requirement the old comment never had to state. "Nothing here is now false" is the wrong check. Ask what is now *required*, and state that, not that it changed.

## Keep it short: what it is, what breaks, where to read more

```text
# <what this is>. <the one thing that breaks if you change it>. See <doc>.
```

Say what breaks instead of giving an order. *"Below TLS 1.3, legacy clients connect without forward secrecy"* tells the reader when it stops applying; *"DO NOT CHANGE"* doesn't.

When the reasoning won't fit in a couple of lines, it belongs in a doc (a README section, a runbook) and the comment points there. That is two edits, not one.

Before:

```yaml
# Messages a single consumer can hold unacked. Not the same as MAX_INFLIGHT
# below, which caps outbound requests only. We ran 20 here from 2022 until
# March, and then one poison message pinned a partition for 40 minutes:
# unacked means held, so 20 lets one bad message block the other nineteen
# while the retry budget burns and nothing moves. Nothing alerts on it
# either -- the consumer is healthy, only the lag is climbing.
# Two consumers per queue, so this cap is per consumer, not per queue.
prefetch: 4
```

After:

```yaml
# Unacked messages one consumer holds; a poison message blocks the rest.
# Cap is per consumer. See README "Queue tuning".
prefetch: 4
```

The poison-message explanation moves to the README section the pointer names. The 2022-to-March history moves to the commit message.

## When the user asks for the story in the code

*"Comment this so we never lose it"*, *"note the version we were on"*, *"this cost me an evening"*: put the durable part, the constraint the incident taught, in the comment. Put the story in the commit message or your report. Then tell the user where each part went, so they know nothing was lost. *"Retries must finish inside the idempotency TTL"* outlives the outage that taught it.

## Read it back

For each comment you added or touched:

- Would it still be true if the ticket closed, the version changed, or a year passed?
- Does it describe the code, or the change?
- Would the code be clear without it?
- Did the session facts land somewhere dated: the commit, the PR, or your report?

## Rationalizations

| Excuse | Reality |
|---|---|
| "The reviewer needs to know why I changed it." | The reviewer reads the PR. The comment is read for years after the PR closes. |
| "It's the version we're on, so it's accurate." | Accurate until the next bump. Bumps don't touch comments, so it goes stale silently. |
| "I wrote 'as of' / 'currently', so it's labeled." | Labels don't stop decay. The reader trusts the fact before noticing the label. |
| "The ticket number helps traceability." | A bare ticket ID is fine where the repo does that. The story around it is not, and `git blame` already links the commit. |
| "It's config; they need the backstory not to break it." | They need the rule and what breaks. The backstory is for the commit. |
| "The user asked me to record all of it." | Record all of it, in the commit message or your report, and say so. Put the constraint in the code. |
| "Shortening it loses information." | It moves to the commit, which `git blame` links to this line. |
