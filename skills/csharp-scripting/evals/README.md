# csharp-scripting evals

Two kinds of eval live here:

## `evals.json` — behavioural

Checks what the skill *produces* once it runs: does it write a file-based
`.cs` app and execute it with `dotnet run`, rather than scaffolding a project
or generating output inline? Run these against a real .NET 10 SDK.

## `trigger-evals.json` — triggering

Checks *whether the skill fires* for a given user message, and (just as
importantly) that it does **not** fire on near-misses that belong to adjacent
skills (`dotnet-ilspy`, `dotnet-nswag`, `dotnet-coding-conventions`) or to
non-C# scratch tasks.

Format: a flat list of `{query, should_trigger}`. 9 positives, 9 negatives.
The negatives are deliberately tricky — they share keywords with the skill
(C#, NuGet, "one-off", "generate data") but should route elsewhere.

### How to run

On a machine with the `claude` CLI, use skill-creator's description optimizer,
which evaluates each query (3 samples) and can tune the description:

```
python -m scripts.run_loop \
  --eval-set skills/csharp-scripting/evals/trigger-evals.json \
  --skill-path skills/csharp-scripting \
  --model <session-model-id> --max-iterations 5 --verbose
```

Without the CLI, the manual method is one routing subagent per query: give it
the real catalog of available skills plus the user message, and have it decide
whether it would invoke `csharp-scripting`. Compare against `should_trigger`.

### Last manual result

18/18 correct (9/9 positive, 9/9 negative). The one earlier miss — a bare
"generate test data as CSV" with no language named — was fixed by adding the
"requires C# to be named or clearly intended" clause to the description, so a
language-agnostic scratch task no longer triggers on the "generating sample
data" phrase alone.
