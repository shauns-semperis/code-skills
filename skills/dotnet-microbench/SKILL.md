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
3. `dotnet run <file>.cs -c Release` and capture the results
4. Generate an interactive HTML viewer with:
   - **Left side**: The benchmark code (syntax-highlighted)
   - **Right side**: Benchmark table + analysis/interpretation
5. Save the HTML file (e.g., `bench_results.html`) and open it so the user can review
6. Clean up: delete the `.cs` file and `BenchmarkDotNet.Artifacts/` directory (but keep the HTML for later reference)

---

## Generating the HTML Results Viewer

After running and capturing benchmark output, create a rich HTML5 document showing code and results side-by-side using semantic markup:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="BenchmarkDotNet results with code and analysis">
  <title>Benchmark Results</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html { height: 100%; }
    body { 
      display: grid; grid-template-columns: 1fr 1fr; gap: 1px; 
      height: 100vh; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #0d1117; color: #e6edf3; 
    }
    main { display: contents; }
    section { padding: 32px; overflow-y: auto; background: #0d1117; }
    section:first-of-type { border-right: 1px solid #30363d; }
    h1 { font-size: 16px; font-weight: 700; color: #58a6ff; margin-bottom: 24px; }
    article { margin-bottom: 24px; }
    article h2 { font-size: 13px; font-weight: 600; color: #8b949e; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 12px; }
    code { font-family: "Monaco", "Courier New", monospace; font-size: 12px; }
    pre { 
      background: #161b22; border: 1px solid #30363d; border-radius: 6px;
      padding: 16px; overflow-x: auto; line-height: 1.5; margin-bottom: 16px;
    }
    table { 
      width: 100%; border-collapse: collapse; font-size: 13px; margin: 16px 0;
      border: 1px solid #30363d;
    }
    th { background: #161b22; border: 1px solid #30363d; padding: 10px 12px; text-align: left; font-weight: 600; }
    td { border: 1px solid #30363d; padding: 10px 12px; }
    aside { font-size: 13px; line-height: 1.6; color: #d0d4d9; }
    strong { color: #f0883e; }
  </style>
</head>
<body>
  <main>
    <section id="code-section">
      <h1>Benchmark Code</h1>
      <article>
        <p style="font-size: 12px; color: #8b949e; margin-bottom: 12px;">
          <code>dotnet run bench.cs -c Release</code>
        </p>
        <pre><code><!-- INSERT COMPLETE BENCHMARK CODE HERE --></code></pre>
      </article>
    </section>
    
    <section id="results-section">
      <h1>Results & Analysis</h1>
      
      <article>
        <h2>Summary Table</h2>
        <table>
          <thead>
            <tr>
              <th>Method</th>
              <th>Mean</th>
              <th>Error</th>
              <th>StdDev</th>
              <th>Allocated</th>
            </tr>
          </thead>
          <tbody>
            <!-- INSERT BENCHMARKDOTNET TABLE ROWS HERE -->
          </tbody>
        </table>
      </article>
      
      <article>
        <h2>Key Findings</h2>
        <aside>
          <!-- INSERT ANALYSIS AND INTERPRETATION HERE -->
        </aside>
      </article>
    </section>
  </main>
</body>
</html>
```

**Structure**:
- `<main>` with `display: contents` acts as a layout container for two semantic `<section>` elements
- Left `<section id="code-section">` shows the benchmark code
- Right `<section id="results-section">` shows results table and analysis
- `<article>` groups related content within sections
- `<aside>` wraps interpretation/analysis text
- Proper `<thead>/<tbody>` for the results table
- `<pre><code>` for syntax-highlighted code blocks

Save as `bench_results.html` and open in a browser. The semantic structure is machine-readable and accessible.

---

## Anti-Patterns

### Scaffolding a benchmark project for a quick comparison

❌ `dotnet new console` → add BenchmarkDotNet → write `Program.cs` → run

✅ Single `.cs` file with `#:package`, `[InProcess]`, `dotnet run file.cs -c Release`

### Forgetting `-c Release`

BenchmarkDotNet's numbers from a debug build aren't meaningful — JIT optimizations are disabled and the timings don't reflect real performance.

### Trusting in-process numbers for anything you're publishing

`InProcessEmitToolchain` loses BenchmarkDotNet's normal process isolation, so results are noisier than the default out-of-process runner. Fine for "which of these two is faster," not fine as a number you'd cite in a PR description or a perf report — use a real project for that.
