using Xunit;
using Moq;
using System;
using System.Threading.Tasks;

namespace OrderServiceTests
{
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
        public async Task PlaceOrderAsync_ValidOrder_ReturnsSuccess()
        {
            // Arrange
            var order = new Order 
            { 
                Payment = new Payment { Amount = 100.00m },
                Status = OrderStatus.Pending
            };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Success());

            // Act
            var result = await _service.PlaceOrderAsync(order);

            // Assert
            Assert.True(result.Success);
            Assert.NotNull(result.ConfirmationNumber);
            Assert.NotEmpty(result.ConfirmationNumber);
        }

        [Fact]
        public async Task PlaceOrderAsync_ValidOrder_SetsOrderStatusToConfirmed()
        {
            // Arrange
            var order = new Order 
            { 
                Payment = new Payment { Amount = 100.00m },
                Status = OrderStatus.Pending
            };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Success());

            // Act
            await _service.PlaceOrderAsync(order);

            // Assert
            Assert.Equal(OrderStatus.Confirmed, order.Status);
        }

        [Fact]
        public async Task PlaceOrderAsync_ValidOrder_AssignsConfirmationNumber()
        {
            // Arrange
            var order = new Order 
            { 
                Payment = new Payment { Amount = 100.00m }
            };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Success());

            // Act
            await _service.PlaceOrderAsync(order);

            // Assert
            Assert.NotNull(order.ConfirmationNumber);
            Assert.NotEmpty(order.ConfirmationNumber);
            // Verify it's a valid GUID format
            Assert.True(Guid.TryParse(order.ConfirmationNumber, out _));
        }

        [Fact]
        public async Task PlaceOrderAsync_PaymentFails_ReturnsFailure()
        {
            // Arrange
            var order = new Order 
            { 
                Payment = new Payment { Amount = 100.00m }
            };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Failed("Insufficient funds"));

            // Act
            var result = await _service.PlaceOrderAsync(order);

            // Assert
            Assert.False(result.Success);
            Assert.Contains("Payment failed", result.Message);
            Assert.Contains("Insufficient funds", result.Message);
        }

        [Fact]
        public async Task PlaceOrderAsync_PaymentFails_DoesNotChangeOrderStatus()
        {
            // Arrange
            var order = new Order 
            { 
                Payment = new Payment { Amount = 100.00m },
                Status = OrderStatus.Pending
            };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Failed("Card declined"));

            // Act
            await _service.PlaceOrderAsync(order);

            // Assert
            Assert.Equal(OrderStatus.Pending, order.Status);
        }

        [Fact]
        public async Task PlaceOrderAsync_PaymentFails_DoesNotAssignConfirmationNumber()
        {
            // Arrange
            var order = new Order 
            { 
                Payment = new Payment { Amount = 100.00m }
            };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Failed("Card declined"));

            // Act
            await _service.PlaceOrderAsync(order);

            // Assert
            Assert.Null(order.ConfirmationNumber);
        }

        [Fact]
        public async Task PlaceOrderAsync_MultipleOrders_AssignsUniqueConfirmationNumbers()
        {
            // Arrange
            var order1 = new Order { Payment = new Payment { Amount = 100.00m } };
            var order2 = new Order { Payment = new Payment { Amount = 200.00m } };
            
            _mockPaymentProcessor
                .Setup(x => x.ProcessAsync(It.IsAny<Payment>()))
                .ReturnsAsync(PaymentResult.Success());

            // Act
            var result1 = await _service.PlaceOrderAsync(order1);
            var result2 = await _service.PlaceOrderAsync(order2);

            // Assert
            Assert.NotEqual(result1.ConfirmationNumber, result2.ConfirmationNumber);
            Assert.NotEqual(order1.ConfirmationNumber, order2.ConfirmationNumber);
        }
    }
}
