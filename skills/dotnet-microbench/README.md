# dotnet-microbench

Runs quick BenchmarkDotNet comparisons from a single `.cs` file instead of scaffolding a full benchmark project.

## What It Does

Quick performance comparisons between two or more pieces of C# code using BenchmarkDotNet's in-process toolchain. No project file needed—just a `.cs` file with `#:package` directives and `dotnet run file.cs -c Release`.

## When to Use It

Trigger this skill when:
- The user asks to **benchmark** or **compare the performance** of C# code
- They want to test "is approach A or approach B faster?"
- They explicitly mention **microbenchmark** or **BenchmarkDotNet**
- They want a quick perf check without setting up a full project

Do NOT trigger for:
- Benchmarks being committed to a repo (use a real BenchmarkDotNet project)
- Load testing or stress testing
- Performance profiling with Perfview, Speedscope, or flamegraphs
- CI/CD benchmark gates (those need process isolation)

## Prerequisites

- .NET 10 SDK or later
- Basic familiarity with C# (you're writing benchmark code)

## Example Usage

**Scenario**: "Which is faster—looping or LINQ for summing an array?"

This skill will create a `.cs` file with BenchmarkDotNet setup, run both approaches with measurements, and show you timing and allocation differences.
