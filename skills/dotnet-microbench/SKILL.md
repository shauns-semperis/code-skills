---
name: dotnet-microbench
description: Runs BenchmarkDotNet microbenchmarks from a single .NET 10 file-based app (a `.cs` file with `#:package` directives, run via `dotnet run file.cs -c Release`) instead of scaffolding a benchmark csproj. Use when the user wants to quickly compare the performance of two or more pieces of C# code, asks to "benchmark" or "microbenchmark" something in C#, or wants to check which of several approaches is faster without setting up a full BenchmarkDotNet project.
---

# .NET Microbenchmarking with File-Based Apps

BenchmarkDotNet normally requires a real `.csproj`: it generates a separate project per benchmark run and builds it out-of-process for isolation. That's too much ceremony for "is A faster than B" questions. This skill runs benchmarks from a single `.cs` file instead, using .NET 10's file-based apps (`#:package` directives, `dotnet run file.cs`) plus BenchmarkDotNet's in-process toolchain, which skips project generation entirely.

Only use this for quick, disposable comparisons. For benchmarks you're committing to the repo and running in CI, use a real BenchmarkDotNet project — you get process isolation and more trustworthy numbers.

---

## The Pattern

Default to measuring allocations, not just time — add `[MemoryDiagnoser]` to every benchmark class unless the human says allocations don't matter here. Allocation regressions are usually the more actionable finding, and it's free to collect (no separate run, no extra config).

```csharp
#:package BenchmarkDotNet@0.14.0
#:property PublishAot=false

using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;

BenchmarkRunner.Run<MyBenchmarks>();

[InProcess]
[MemoryDiagnoser]
public class MyBenchmarks
{
    [Benchmark]
    public int ApproachA() { /* ... */ }

    [Benchmark]
    public int ApproachB() { /* ... */ }
}
```

```bash
dotnet run bench.cs -c Release
```

**What matters most**: produce a clear summary table with timing and allocation data, then interpret what it means. Showing the code structure upfront is helpful but the results table is what the human needs.

Verified working: `[MemoryDiagnoser]` reports an `Allocated` column correctly under `InProcessEmitToolchain` in a file-based app — no compatibility issues, no extra directives needed. Only drop it if the human says they don't care about allocations for this comparison.

---

## Two Required Directives/Attributes (and Why)

### 1. `[InProcess]` on the benchmark class

This tells BenchmarkDotNet to use `InProcessEmitToolchain`, which emits IL on the fly and runs the benchmark in the current process instead of generating and building a separate project. Without it, BenchmarkDotNet tries to scaffold a project next to a `.cs` file that has no `.csproj`, and fails.

### 2. `#:property PublishAot=false`

File-based apps run with `RuntimeFeature.IsDynamicCodeSupported = false` by default (an AOT-style mode). `InProcessEmitToolchain` depends on `Reflection.Emit`, which throws `NotSupportedException: Dynamic code generation is not supported on this platform` without this property. This is a default as of .NET SDK 10.0.300, not a guaranteed-forever rule — if a later SDK doesn't set it, the property is harmless.

Always pass `-c Release`. BenchmarkDotNet will warn (and the numbers will be meaningless) if it detects a debug build.

---

## Known Gotcha: Don't Use `ManualConfig.CreateEmpty()`

If you want to override the job (e.g. for a fast sanity-check run before committing to the full default job), start from the default config rather than an empty one:

```csharp
// ❌ silently drops default loggers/exporters/columns
var config = ManualConfig.CreateEmpty()
    .AddJob(Job.Dry.WithToolchain(InProcessEmitToolchain.Instance));

// ✅ keeps default reporting, just overrides the job
var config = ManualConfig.Create(DefaultConfig.Instance)
    .AddJob(Job.Dry.WithToolchain(InProcessEmitToolchain.Instance));
```

`Job.Dry` runs one warmup + one iteration — good for "does this even work and is the direction of the difference sane" checks. Drop it for a real comparison; the default job's warmup/iteration counts give trustworthy numbers.

---

## Full Example (Verified Working)

```csharp
#:package BenchmarkDotNet@0.14.0
#:property PublishAot=false

using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;

BenchmarkRunner.Run<ArraySum>();

[InProcess]
[MemoryDiagnoser]
public class ArraySum
{
    private readonly int[] data = Enumerable.Range(0, 10_000).ToArray();

    [Benchmark]
    public int Loop()
    {
        var sum = 0;
        foreach (var x in data) sum += x;
        return sum;
    }

    [Benchmark]
    public int Linq() => data.Sum();
}
```

```bash
dotnet run bench.cs -c Release
```

Produces a normal BenchmarkDotNet summary table (mean, error, stddev, allocated) and writes `BenchmarkDotNet.Artifacts/` next to the file — clean up both when done.

---

## Workflow

1. Write the `.cs` file: `#:package BenchmarkDotNet@<version>`, `#:property PublishAot=false`
2. Mark the benchmark class `[InProcess]` and `[MemoryDiagnoser]` (default on; drop only if told allocations don't matter)
3. `dotnet run <file>.cs -c Release`
4. Show the benchmark summary table (timing, allocations, error rates)
5. Interpret the results: which approach is faster/uses less memory, and why
6. Clean up: delete the `.cs` file and `BenchmarkDotNet.Artifacts/` directory

---

## Anti-Patterns

### Scaffolding a benchmark project for a quick comparison

❌ `dotnet new console` → add BenchmarkDotNet → write `Program.cs` → run

✅ Single `.cs` file with `#:package`, `[InProcess]`, `dotnet run file.cs -c Release`

### Forgetting `-c Release`

BenchmarkDotNet's numbers from a debug build aren't meaningful — JIT optimizations are disabled and the timings don't reflect real performance.

### Trusting in-process numbers for anything you're publishing

`InProcessEmitToolchain` loses BenchmarkDotNet's normal process isolation, so results are noisier than the default out-of-process runner. Fine for "which of these two is faster," not fine as a number you'd cite in a PR description or a perf report — use a real project for that.
