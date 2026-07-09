# dotnet-coding-conventions

Keeps your C# consistent with the project's conventions — null guards, collection expressions, using directives, braces, magic strings, and logging — so you don't have to remember them by hand.

## When it triggers

Any time you write, edit, or review C# / .NET code. If you're touching a `.cs` file, this skill has your back.

## Why it exists

Most of these conventions are small, easy to get right one at a time, and easy to drift on across a big codebase. This skill catches the recurring nits before they show up in code review — things like `ThrowIfNull` with a redundant `nameof`, `new string[] { }` instead of `[]`, or a `_logger.LogInformation($"...")` call that allocates a string on every request whether or not anyone's listening.

## Logging, in particular

`[LoggerMessage]` source-generated delegates are the preferred way to log in this project. They skip the boxing and allocation that comes with plain `_logger.LogXxx(...)` calls, so pick them over interpolated strings or `.ToString()` calls every time.

One thing worth knowing: it's tempting to add a new delegate for every place you log, even when two of them are really the same event wearing different words. The skill steers you toward reusing a delegate when the shape of the data matches, and only splitting into separate delegates when the data itself — or something functional like the log level or an `EventId` — genuinely differs.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill instructions, conventions, and examples |
| `evals/evals.json` | Test cases covering the logging conventions |
