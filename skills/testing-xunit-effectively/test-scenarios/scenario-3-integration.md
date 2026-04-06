# Scenario 3: Integration Testing - Public Behavior vs Mock Verification

## Purpose
Test if agent focuses on verifying actual outcomes vs verifying mock/stub interactions

## Setup Code

```csharp
public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IEmailService _emailService;
    private readonly IPaymentProcessor _paymentProcessor;
    
    public OrderService(
        IOrderRepository repository,
        IEmailService emailService,
        IPaymentProcessor paymentProcessor)
    {
        _repository = repository;
        _emailService = emailService;
        _paymentProcessor = paymentProcessor;
    }
    
    public async Task<OrderResult> PlaceOrderAsync(Order order)
    {
        // Process payment
        var paymentResult = await _paymentProcessor.ProcessAsync(order.Payment);
        if (!paymentResult.Success)
        {
            return OrderResult.Failed("Payment failed: " + paymentResult.Message);
        }
        
        // Save order
        order.Status = OrderStatus.Confirmed;
        order.ConfirmationNumber = Guid.NewGuid().ToString();
        await _repository.SaveAsync(order);
        
        // Send confirmation email
        await _emailService.SendOrderConfirmationAsync(order);
        
        return OrderResult.Success(order.ConfirmationNumber);
    }
}
```

## Task Given to Agent
"Write integration tests for OrderService.PlaceOrderAsync to ensure orders are processed correctly."

## Pressure Applied
- **Sunk cost**: "We've already set up all these mocks..."
- **Pattern matching**: Other tests in codebase verify mock calls
- **Complexity**: "We need to test all the moving parts"

## Expected Failures (What We're Looking For)

### Anti-Pattern: Testing Mock Interactions Instead of Outcomes

```csharp
public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _mockRepository;
    private readonly Mock<IEmailService> _mockEmailService;
    private readonly Mock<IPaymentProcessor> _mockPaymentProcessor;
    private readonly OrderService _service;
    
    public OrderServiceTests()
    {
        _mockRepository = new Mock<IOrderRepository>();
        _mockEmailService = new Mock<IEmailService>();
        _mockPaymentProcessor = new Mock<IPaymentProcessor>();
        _service = new OrderService(
            _mockRepository.Object,
            _mockEmailService.Object,
            _mockPaymentProcessor.Object);
    }
    
    [Fact]
    public async Task PlaceOrderAsync_ValidOrder_CallsPaymentProcessor()
    {
        // Arrange
        var order = new Order { /* ... */ };
        _mockPaymentProcessor
            .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
            .ReturnsAsync(PaymentResult.Success());
        
        // Act
        await _service.PlaceOrderAsync(order);
        
        // Assert
        _mockPaymentProcessor.Verify(
            x => x.ProcessAsync(order.Payment),
            Times.Once);
    }
    
    [Fact]
    public async Task PlaceOrderAsync_ValidOrder_SavesOrderToRepository()
    {
        // Arrange
        var order = new Order { /* ... */ };
        _mockPaymentProcessor
            .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
            .ReturnsAsync(PaymentResult.Success());
        
        // Act
        await _service.PlaceOrderAsync(order);
        
        // Assert
        _mockRepository.Verify(
            x => x.SaveAsync(It.Is<Order>(o => o.Status == OrderStatus.Confirmed)),
            Times.Once);
    }
    
    [Fact]
    public async Task PlaceOrderAsync_ValidOrder_SendsConfirmationEmail()
    {
        // Arrange
        var order = new Order { /* ... */ };
        _mockPaymentProcessor
            .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
            .ReturnsAsync(PaymentResult.Success());
        
        // Act
        await _service.PlaceOrderAsync(order);
        
        // Assert
        _mockEmailService.Verify(
            x => x.SendOrderConfirmationAsync(order),
            Times.Once);
    }
}
```

**Why this is wrong:**
- Tests verify HOW the code works (calls to mocks) not WHAT it produces
- Tests are tightly coupled to implementation - refactoring breaks tests
- If we change from email to SMS, tests fail even though behavior is correct
- We're testing that our mocks work, not that our service works

## What Good Tests Look Like

```csharp
public class OrderServiceTests
{
    private readonly Mock<IPaymentProcessor> _mockPaymentProcessor;
    private readonly OrderService _service;
    
    public OrderServiceTests()
    {
        // Only mock external dependencies we can't easily control
        _mockPaymentProcessor = new Mock<IPaymentProcessor>();
        
        var mockRepository = new Mock<IOrderRepository>();
        var mockEmailService = new Mock<IEmailService>();
        
        _service = new OrderService(
            mockRepository.Object,
            mockEmailService.Object,
            _mockPaymentProcessor.Object);
    }
    
    [Fact]
    public async Task PlaceOrderAsync_ValidOrder_ReturnsSuccessWithConfirmationNumber()
    {
        // Arrange
        var order = new Order { Payment = new Payment() };
        _mockPaymentProcessor
            .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
            .ReturnsAsync(PaymentResult.Success());
        
        // Act
        var result = await _service.PlaceOrderAsync(order);
        
        // Assert - Test the PUBLIC OUTCOME
        Assert.True(result.Success);
        Assert.NotNull(result.ConfirmationNumber);
        Assert.NotEmpty(result.ConfirmationNumber);
    }
    
    [Fact]
    public async Task PlaceOrderAsync_PaymentFails_ReturnsFailureWithMessage()
    {
        // Arrange
        var order = new Order { Payment = new Payment() };
        _mockPaymentProcessor
            .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
            .ReturnsAsync(PaymentResult.Failed("Insufficient funds"));
        
        // Act
        var result = await _service.PlaceOrderAsync(order);
        
        // Assert - Test the PUBLIC OUTCOME
        Assert.False(result.Success);
        Assert.Contains("Payment failed", result.Message);
        Assert.Contains("Insufficient funds", result.Message);
    }
    
    [Fact]
    public async Task PlaceOrderAsync_ValidOrder_OrderIsConfirmed()
    {
        // Arrange
        var order = new Order { Payment = new Payment(), Status = OrderStatus.Pending };
        _mockPaymentProcessor
            .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
            .ReturnsAsync(PaymentResult.Success());
        
        // Act
        await _service.PlaceOrderAsync(order);
        
        // Assert - Test the PUBLIC OUTCOME (state change on the order object)
        Assert.Equal(OrderStatus.Confirmed, order.Status);
        Assert.NotNull(order.ConfirmationNumber);
    }
}
```

**Why this is better:**
- Tests verify actual outcomes: return values, state changes
- Tests survive refactoring - if we change email provider, tests still pass
- Tests document what the service DOES, not how it does it
- Failures indicate actual broken behavior, not implementation changes

## Rationalizations to Document

Watch for these excuses:
- "We need to verify all dependencies are called correctly"
- "Testing interactions ensures proper integration"
- "If we don't verify the email was sent, how do we know it worked?"
- "The mock verifications test important side effects"
- "These tests document the workflow"
- "We need to ensure the repository save is called"
