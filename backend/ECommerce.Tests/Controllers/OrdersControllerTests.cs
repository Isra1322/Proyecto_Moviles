namespace ECommerce.Tests.Controllers;

using System.Security.Claims;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using ECommerce.Application.Common.Exceptions;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Orders;
using ECommerce.Domain.Enums;
using ECommerce.WebApi.Controllers;

public class OrdersControllerTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly Mock<ILogger<OrdersController>> _loggerMock;
    private readonly OrdersController _controller;

    public OrdersControllerTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _loggerMock = new Mock<ILogger<OrdersController>>();

        var createUseCase = new CreateOrderUseCase(_odooServiceMock.Object);
        var getUseCase = new GetOrdersUseCase(_odooServiceMock.Object);

        _controller = new OrdersController(createUseCase, getUseCase, _loggerMock.Object);

        // Configurar ClaimsPrincipal simulando usuario autenticado (partner_id = 7)
        var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "7"),
            new Claim(ClaimTypes.Email, "test@correo.com")
        }, "TestAuth"));

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };
    }

    [Fact]
    public async Task Create_WhenValidRequest_Returns201Created()
    {
        // Arrange
        var request = new CreateOrderDto
        {
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 2, UnitPrice = 50m }
            }
        };

        var createdOrder = new OrderDto
        {
            Id = 101,
            CustomerId = 7,
            Status = OrderStatus.Confirmed,
            TotalAmount = 100m
        };

        _odooServiceMock
            .Setup(s => s.CreateOrderAsync(It.IsAny<CreateOrderDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(createdOrder);

        // Act
        var result = await _controller.Create(request, CancellationToken.None);

        // Assert
        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status201Created);

        var apiResponse = objResult.Value as ApiResponse<OrderDto>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Id.Should().Be(101);
    }

    [Fact]
    public async Task Create_WhenBodyNull_Returns400BadRequest()
    {
        // Act
        var result = await _controller.Create(null, CancellationToken.None);

        // Assert
        result.Should().BeOfType<BadRequestObjectResult>();
        var badRequest = (BadRequestObjectResult)result;
        var apiResponse = badRequest.Value as ApiResponse<object>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
        apiResponse.Message.Should().Contain("vacío");
    }

    [Fact]
    public async Task Create_WhenOdooFails_Returns502BadGateway()
    {
        // Arrange
        var request = new CreateOrderDto
        {
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 1, UnitPrice = 10m }
            }
        };

        _odooServiceMock
            .Setup(s => s.CreateOrderAsync(It.IsAny<CreateOrderDto>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new OdooIntegrationException("Fallo de conexión"));

        // Act
        var result = await _controller.Create(request, CancellationToken.None);

        // Assert
        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status502BadGateway);

        var apiResponse = objResult.Value as ApiResponse<object>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
    }

    [Fact]
    public async Task Create_WhenTimeout_Returns408RequestTimeout()
    {
        // Arrange
        var request = new CreateOrderDto
        {
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 1, UnitPrice = 10m }
            }
        };

        _odooServiceMock
            .Setup(s => s.CreateOrderAsync(It.IsAny<CreateOrderDto>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new OperationCanceledException());

        // Act
        var result = await _controller.Create(request, CancellationToken.None);

        // Assert
        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status408RequestTimeout);
    }

    [Fact]
    public async Task GetMyOrders_WhenValidRequest_Returns200OkWithOrders()
    {
        // Arrange
        var orders = new List<OrderDto>
        {
            new() { Id = 1, CustomerId = 7, TotalAmount = 150m, Status = OrderStatus.Confirmed }
        };

        _odooServiceMock
            .Setup(s => s.GetOrdersByCustomerAsync(7, It.IsAny<CancellationToken>()))
            .ReturnsAsync(orders);

        // Act
        var result = await _controller.GetMyOrders(null, CancellationToken.None);

        // Assert
        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        var apiResponse = okResult.Value as ApiResponse<IReadOnlyList<OrderDto>>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data.Should().HaveCount(1);
        apiResponse.Data![0].Id.Should().Be(1);
    }

    [Fact]
    public async Task GetMyOrders_WhenTimeoutException_Returns408RequestTimeout()
    {
        // Arrange
        _odooServiceMock
            .Setup(s => s.GetOrdersByCustomerAsync(7, It.IsAny<CancellationToken>()))
            .ThrowsAsync(new TimeoutException("Timeout excedido"));

        // Act
        var result = await _controller.GetMyOrders(null, CancellationToken.None);

        // Assert
        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status408RequestTimeout);
        var apiResponse = objResult.Value as ApiResponse<object>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
        apiResponse.Message.Should().Contain("tiempo");
    }

    [Fact]
    public async Task GetMyOrders_WhenOperationCanceled_Returns408RequestTimeout()
    {
        // Arrange
        _odooServiceMock
            .Setup(s => s.GetOrdersByCustomerAsync(7, It.IsAny<CancellationToken>()))
            .ThrowsAsync(new OperationCanceledException());

        // Act
        var result = await _controller.GetMyOrders(null, CancellationToken.None);

        // Assert
        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status408RequestTimeout);
    }

    [Fact]
    public async Task GetMyOrders_WhenOdooFails_Returns502BadGateway()
    {
        // Arrange
        _odooServiceMock
            .Setup(s => s.GetOrdersByCustomerAsync(7, It.IsAny<CancellationToken>()))
            .ThrowsAsync(new OdooIntegrationException("Error de conexión con Odoo"));

        // Act
        var result = await _controller.GetMyOrders(null, CancellationToken.None);

        // Assert
        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status502BadGateway);
        var apiResponse = objResult.Value as ApiResponse<object>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
    }
}
