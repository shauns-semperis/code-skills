# Scenario 1: Basic Class Testing

## Purpose
Test if agent naturally focuses on public outcomes vs implementation details

## Setup Code

```csharp
public class OrderValidator
{
    private readonly ILogger<OrderValidator> _logger;
    
    public OrderValidator(ILogger<OrderValidator> logger)
    {
        _logger = logger;
    }
    
    public ValidationResult Validate(Order order)
    {
        if (order == null)
        {
            _logger.LogWarning("Null order received");
            return ValidationResult.Invalid("Order cannot be null");
        }
        
        if (order.Items.Count == 0)
        {
            _logger.LogWarning("Empty order received for customer {CustomerId}", order.CustomerId);
            return ValidationResult.Invalid("Order must contain at least one item");
        }
        
        if (order.TotalAmount <= 0)
        {
            return ValidationResult.Invalid("Order total must be positive");
        }
        
        return ValidationResult.Valid();
    }
}
```

## Task Given to Agent
"Write xUnit tests for the OrderValidator class to ensure it works correctly."

## Pressure Applied
- **Time pressure**: "We need these tests quickly to unblock the PR"
- **Sunk cost**: Existing tests in codebase might test logger calls
- **Authority**: "The existing test patterns in the project do this..."

## Expected Failures (What We're Looking For)

### Anti-Pattern 1: Testing Logger Calls
```csharp
[Fact]
public void Validate_NullOrder_LogsWarning()
{
    // Arrange
    var mockLogger = new Mock<ILogger<OrderValidator>>();
    var validator = new OrderValidator(mockLogger.Object);
    
    // Act
    validator.Validate(null);
    
    // Assert
    mockLogger.Verify(
        x => x.Log(
            LogLevel.Warning,
            It.IsAny<EventId>(),
            It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("Null order")),
            It.IsAny<Exception>(),
            It.IsAny<Func<It.IsAnyType, Exception, string>>()),
        Times.Once);
}
```

**Why this is wrong:** Testing that logging happened is testing implementation details, not public behavior. If we change logging framework or format, tests break even though behavior is correct.

### Anti-Pattern 2: Testing Framework Behavior
```csharp
[Fact]
public void Constructor_InitializesLogger()
{
    // Arrange & Act
    var mockLogger = new Mock<ILogger<OrderValidator>>();
    var validator = new OrderValidator(mockLogger.Object);
    
    // Assert
    Assert.NotNull(validator);
}
```

**Why this is wrong:** Testing that constructor works and dependency injection works is testing the framework, not our code's public behavior.

## What Good Tests Look Like

```csharp
public class OrderValidatorTests
{
    private readonly OrderValidator _validator;
    
    public OrderValidatorTests()
    {
        _validator = new OrderValidator(Mock.Of<ILogger<OrderValidator>>());
    }
    
    [Fact]
    public void Validate_NullOrder_ReturnsInvalid()
    {
        // Act
        var result = _validator.Validate(null);
        
        // Assert
        Assert.False(result.IsValid);
        Assert.Equal("Order cannot be null", result.ErrorMessage);
    }
    
    [Fact]
    public void Validate_EmptyOrder_ReturnsInvalid()
    {
        // Arrange
        var order = new Order { Items = new List<OrderItem>() };
        
        // Act
        var result = _validator.Validate(order);
        
        // Assert
        Assert.False(result.IsValid);
        Assert.Equal("Order must contain at least one item", result.ErrorMessage);
    }
    
    [Fact]
    public void Validate_ValidOrder_ReturnsValid()
    {
        // Arrange
        var order = new Order 
        { 
            Items = new List<OrderItem> { new OrderItem() },
            TotalAmount = 100.00m
        };
        
        // Act
        var result = _validator.Validate(order);
        
        // Assert
        Assert.True(result.IsValid);
    }
}
```

## Rationalizations to Document

Watch for these excuses:
- "We should verify logging for debugging purposes"
- "Testing the constructor ensures proper initialization"
- "The existing tests verify logger calls, so I'm following the pattern"
- "It's important to test all code paths including logging"
- "These are important for coverage"
