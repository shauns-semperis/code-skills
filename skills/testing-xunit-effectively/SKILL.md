---
name: testing-xunit-effectively
description: Use when writing xUnit tests in C# and encountering repetitive test patterns or deciding what to test
---

# Testing xUnit Effectively

## Overview

**Write tests that verify public behavior, not implementation details. Use `[Theory]` for repeated patterns.**

Two core principles:
1. Test WHAT your code does (outcomes), not HOW it does it (implementation)
2. Eliminate duplication with `[Theory]` when testing multiple inputs with identical logic

## When to Use

**Use this skill when:**
- Writing new xUnit tests
- Seeing multiple tests with nearly identical structure
- Deciding whether to test a specific piece of code
- Reviewing tests that feel brittle or overly detailed

**Symptoms you need this:**
- Tests break when you refactor without changing behavior
- Five+ `[Fact]` methods testing the same logic with different inputs
- Testing logger calls, mock interactions, or framework behavior
- Test names like "Method_CallsDependency" or "Constructor_InitializesField"

## Core Pattern

### Before: Testing Implementation Details

```csharp
[Fact]
public void Validate_NullOrder_LogsWarning()
{
    var mockLogger = new Mock<ILogger<OrderValidator>>();
    var validator = new OrderValidator(mockLogger.Object);
    
    validator.Validate(null);
    
    // ❌ Testing HOW - verifies internal logging behavior
    mockLogger.Verify(x => x.Log(
        LogLevel.Warning,
        It.IsAny<EventId>(),
        It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("Null order")),
        It.IsAny<Exception>(),
        It.IsAny<Func<It.IsAnyType, Exception, string>>()),
        Times.Once);
}
```

### After: Testing Public Outcomes

```csharp
[Fact]
public void Validate_NullOrder_ReturnsInvalid()
{
    var validator = new OrderValidator(NullLogger<OrderValidator>.Instance);
    
    var result = validator.Validate(null);
    
    // ✅ Testing WHAT - verifies actual public behavior
    Assert.False(result.IsValid);
    Assert.Equal("Order cannot be null", result.ErrorMessage);
}
```

### Before: Duplicate Test Methods

```csharp
[Fact]
public void IsValid_NullEmail_ReturnsFalse()
{
    var result = _validator.IsValid(null);
    Assert.False(result);
}

[Fact]
public void IsValid_EmptyEmail_ReturnsFalse()
{
    var result = _validator.IsValid("");
    Assert.False(result);
}

[Fact]
public void IsValid_WhitespaceEmail_ReturnsFalse()
{
    var result = _validator.IsValid("   ");
    Assert.False(result);
}

// ❌ ...7 more nearly identical tests
```

### After: Parameterized with Theory

```csharp
[Theory]
[InlineData(null)]
[InlineData("")]
[InlineData("   ")]
[InlineData("invalidemail.com")]
[InlineData("user@@email.com")]
[InlineData("@email.com")]
[InlineData("user@")]
[InlineData("user@emailcom")]
public void IsValid_InvalidEmails_ReturnsFalse(string email)
{
    // ✅ One test, all invalid cases - easy to scan and extend
    var result = _validator.IsValid(email);
    Assert.False(result);
}
```

## Quick Reference

### What to Test (Public Behavior)

| ✅ Test This | ❌ Not This |
|-------------|-------------|
| Return values | Logger calls |
| Thrown exceptions | Mock interactions |
| State changes on objects | Constructor assignments |
| Observable side effects | Framework behavior |
| Error messages | Dependency injection setup |

### Don't Mock Framework Types

- Use `NullLogger<T>.Instance` instead of mocking `ILogger<T>`
- Use `Options.Create(...)` instead of mocking `IOptions<T>`

### When to Use [Theory]

| Pattern | Use Theory? | Why |
|---------|-------------|-----|
| 3+ tests, same assertion, different inputs | ✅ Yes | Eliminate duplication |
| Tests with different assertion logic | ❌ No | Logic differs, keep separate |
| Single test case | ❌ No | No duplication to eliminate |
| Complex objects as test data | ✅ Yes | Use `[MemberData]` or `[ClassData]` instead of `[InlineData]` |

**Note:** `[InlineData]` works for primitives. For complex objects, use `[MemberData]` (method returning test cases) or `[ClassData]` (class implementing `IEnumerable<object[]>`).

## Common Mistakes

### Mistake 1: Test Names Include Fixture/Context Noise

```csharp
// ❌ BAD: Name locked to specific test data ("json-data")
[Theory]
[InlineData("{\"name\":\"Alice\"}")]
[InlineData("{\"name\":\"Bob\"}")]
public void Parse_JsonData_ReturnsUser(string json, string expectedName)
{
    var result = _parser.Parse(json);
    
    Assert.Equal(expectedName, result.Name);
}

// ❌ STILL BAD: Name includes fixture context ("WithJsonString")
// Sounds like we're testing JSON-specific behavior, but we're testing deserialization generally
[Theory]
[InlineData("{\"name\":\"Alice\"}")]
[InlineData("{\"name\":\"Bob\"}")]
public void Parse_WithJsonString_ReturnsUser(string json, string expectedName)
{
    var result = _parser.Parse(json);
    
    Assert.Equal(expectedName, result.Name);
}

// ✅ GOOD: Name describes the actual behavior - correct deserialization
// "JsonData" and "JsonString" are test fixtures. The actual behavior is parsing/deserializing.
[Theory]
[InlineData("{\"name\":\"Alice\"}")]
[InlineData("{\"name\":\"Bob\"}")]
public void Parse_ValidInput_ReturnsDeserializedObject(string json, string expectedName)
{
    var result = _parser.Parse(json);
    
    Assert.Equal(expectedName, result.Name);
}
```

**Why:** Strip away fixture context from test names. The test data is already visible in `[InlineData]` — you don't need to repeat it. The method name should describe what behavior is verified, not the format or type of test data used.

### Mistake 2: Testing Logging

```csharp
// ❌ BAD: Fragile, tests implementation
mockLogger.Verify(x => x.Log(...), Times.Once);

// ✅ GOOD: Test the business outcome instead
Assert.Equal("expected error message", result.ErrorMessage);
```

**Why:** If you switch logging frameworks or format, tests break even though behavior is correct.

### Mistake 3: Testing Mock Calls

```csharp
// ❌ BAD: Verifies HOW method works
_mockRepository.Verify(x => x.SaveAsync(order), Times.Once);

// ✅ GOOD: Test the RESULT of the save operation
Assert.Equal(OrderStatus.Confirmed, order.Status);
Assert.NotNull(order.ConfirmationNumber);
```

**Why:** Tests should survive refactoring. If you change save mechanism, business behavior hasn't changed.

### Mistake 4: Copy-Paste Instead of Theory

```csharp
// ❌ BAD: Nine methods with identical logic
[Fact] public void Test_Case1() { /* same pattern */ }
[Fact] public void Test_Case2() { /* same pattern */ }
// ...7 more

// ✅ GOOD: One Theory with all cases
[Theory]
[InlineData(case1)]
[InlineData(case2)]
// ...7 more
public void Test_AllCases(input) { /* shared logic */ }
```

**Why:** Easier to see full coverage, add cases, maintain logic.

## Red Flags - STOP and Reconsider

If you're about to:
- Name a test after test data or fixture values (`Evaluate_authz_allow_...` when "authz/allow" is the policy being evaluated)
- Verify a mock was called (`mockService.Verify(...)`)
- Test that a logger logged something
- Mock `ILogger<T>` or `IOptions<T>` (use `NullLogger<T>.Instance` or `Options.Create(...)`)
- Write a 5th test with identical logic but different input
- Test constructor initialization
- Verify dependency injection setup works
- Test framework behavior (like "Assert works correctly")

**These are ALL signs you're testing the wrong thing or using the wrong pattern.**

**When writing or reviewing tests:** Check for missing edge cases, null inputs, boundary conditions, and invalid inputs. Add them with `[Theory]` where appropriate.

## Common Rationalizations (and Why They're Wrong)

| Excuse | Reality |
|--------|---------|
| "Individual tests are clearer" | Theory with good test names is equally clear. Duplication hides patterns. |
| "Each test should test one thing" | One Theory tests one behavior with multiple inputs. Still focused. |
| "Test names show what failed" | Theory shows BOTH test name AND failing input parameter in output. |
| "Copy-paste is faster under deadline" | Adding 9 tests takes longer than 1 Theory with 9 `[InlineData]`. |
| "It's the existing pattern" | Following bad patterns makes codebase worse, not better. |
| "We need to verify logging" | Test observable outcomes. If error message is right, logging is working. |
| "Need to test all code paths" | Test public behavior. Internal paths are implementation details. |

## Real-World Impact

**Theory benefits:**
- 9 test methods → 1 Theory = 60% less code
- Add new case = 1 line vs new method
- Test runner shows exactly which input failed
- Full coverage visible at a glance

**Public outcome benefits:**
- Tests survive refactoring
- Focus on business requirements
- Faster to write (no mock setup complexity)
- Clearer test failures (actual behavior broke, not implementation changed)
