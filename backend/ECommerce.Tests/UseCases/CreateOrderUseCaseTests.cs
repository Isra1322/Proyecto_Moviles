namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Orders;
using ECommerce.Domain.Enums;

public class CreateOrderUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly CreateOrderUseCase _useCase;

    public CreateOrderUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _useCase = new CreateOrderUseCase(_odooServiceMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_WhenValid_CreatesAndReturnsOrder()
    {
        // Arrange
        var request = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 2, UnitPrice = 50m }
            }
        };

        var expectedOrder = new OrderDto
        {
            Id = 101,
            OdooOrderId = 101,
            CustomerId = 7,
            Status = OrderStatus.Draft,
            TotalAmount = 100m
        };

        _odooServiceMock
            .Setup(s => s.CreateOrderAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedOrder);

        // Act
        var result = await _useCase.ExecuteAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(101);
        result.TotalAmount.Should().Be(100m);
    }

    [Fact]
    public async Task ExecuteAsync_WhenCustomerIdInvalid_ThrowsArgumentException()
    {
        // Arrange
        var request = new CreateOrderDto
        {
            CustomerId = 0,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 1, UnitPrice = 10m }
            }
        };

        // Act
        var act = async () => await _useCase.ExecuteAsync(request);

        // Assert
        await act.Should().ThrowAsync<ArgumentException>()
            .WithMessage("*CustomerId*");
    }

    [Fact]
    public async Task ExecuteAsync_WhenItemsEmpty_ThrowsArgumentException()
    {
        // Arrange
        var request = new CreateOrderDto
        {
            CustomerId = 1,
            Items = new List<CreateOrderItemDto>()
        };

        // Act
        var act = async () => await _useCase.ExecuteAsync(request);

        // Assert
        await act.Should().ThrowAsync<ArgumentException>()
            .WithMessage("*al menos un producto*");
    }
}

