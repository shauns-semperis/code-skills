# Scenario 2: Missing Theory Opportunities

## Purpose
Test if agent recognizes when to use `[Theory]` instead of multiple `[Fact]` tests

## Setup Code

```csharp
public class EmailValidator
{
    public bool IsValid(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;
            
        if (!email.Contains("@"))
            return false;
            
        var parts = email.Split('@');
        if (parts.Length != 2)
            return false;
            
        if (string.IsNullOrWhiteSpace(parts[0]) || string.IsNullOrWhiteSpace(parts[1]))
            return false;
            
        if (!parts[1].Contains("."))
            return false;
            
        return true;
    }
}
```

## Task Given to Agent
"Write comprehensive xUnit tests for EmailValidator. Make sure to cover these cases:
- Null emails
- Empty strings
- Whitespace only
- Missing @ symbol
- Multiple @ symbols
- Empty local part (before @)
- Empty domain part (after @)
- Domain without dot
- Valid emails"

## Pressure Applied
- **Time pressure**: "Need test coverage before end of sprint"
- **Exhaustion**: "We've already written 20 tests today, let's keep it simple"
- **Pattern matching**: Existing tests in codebase might use individual Facts

## Expected Failures (What We're Looking For)

### Anti-Pattern: Individual Fact Tests

```csharp
public class EmailValidatorTests
{
    private readonly EmailValidator _validator = new();
    
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
    
    [Fact]
    public void IsValid_MissingAtSymbol_ReturnsFalse()
    {
        var result = _validator.IsValid("invalidemail.com");
        Assert.False(result);
    }
    
    [Fact]
    public void IsValid_MultipleAtSymbols_ReturnsFalse()
    {
        var result = _validator.IsValid("user@@email.com");
        Assert.False(result);
    }
    
    [Fact]
    public void IsValid_EmptyLocalPart_ReturnsFalse()
    {
        var result = _validator.IsValid("@email.com");
        Assert.False(result);
    }
    
    [Fact]
    public void IsValid_EmptyDomainPart_ReturnsFalse()
    {
        var result = _validator.IsValid("user@");
        Assert.False(result);
    }
    
    [Fact]
    public void IsValid_DomainWithoutDot_ReturnsFalse()
    {
        var result = _validator.IsValid("user@emailcom");
        Assert.False(result);
    }
    
    [Fact]
    public void IsValid_ValidEmail_ReturnsTrue()
    {
        var result = _validator.IsValid("user@email.com");
        Assert.True(result);
    }
}
```

**Why this is wrong:** 
- 9 nearly identical tests with the same pattern (Arrange-Act-Assert)
- Hard to see the full test coverage at a glance
- Adding new test case requires full new method
- Duplication makes maintenance harder

## What Good Tests Look Like

```csharp
public class EmailValidatorTests
{
    private readonly EmailValidator _validator = new();
    
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
        // Act
        var result = _validator.IsValid(email);
        
        // Assert
        Assert.False(result);
    }
    
    [Theory]
    [InlineData("user@email.com")]
    [InlineData("test.user@example.org")]
    [InlineData("admin@company.co.uk")]
    public void IsValid_ValidEmails_ReturnsTrue(string email)
    {
        // Act
        var result = _validator.IsValid(email);
        
        // Assert
        Assert.True(result);
    }
}
```

**Benefits:**
- All invalid cases grouped together - easy to see coverage
- Adding new case = one line of `[InlineData]`
- Test runner shows which specific input failed
- Less code duplication

## Rationalizations to Document

Watch for these excuses:
- "Individual tests are clearer and easier to understand"
- "Each test should test one thing"
- "It's easier to see which specific case failed with individual tests"
- "Theory is more complex and harder to maintain"
- "The existing tests use Facts, so I'm following the pattern"
- "We can add descriptive test names with Facts but not with Theory"
