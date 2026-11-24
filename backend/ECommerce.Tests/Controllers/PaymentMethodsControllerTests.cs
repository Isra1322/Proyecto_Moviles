namespace ECommerce.Tests.Controllers;

using System.Security.Claims;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.PaymentMethods;
using ECommerce.Application.Interfaces;
using ECommerce.WebApi.Controllers;

public class PaymentMethodsControllerTests
{
    private readonly Mock<IPaymentMethodService> _serviceMock;
    private readonly Mock<ILogger<PaymentMethodsController>> _loggerMock;
    private readonly PaymentMethodsController _controller;

    public PaymentMethodsControllerTests()
    {
        _serviceMock = new Mock<IPaymentMethodService>();
        _loggerMock = new Mock<ILogger<PaymentMethodsController>>();
        _controller = new PaymentMethodsController(_serviceMock.Object, _loggerMock.Object);

        var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "42"),
            new Claim(ClaimTypes.Email, "cliente@test.com")
        }, "TestAuth"));

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };
    }

    [Fact]
    public async Task GetAll_ReturnsCardsForAuthenticatedUser()
    {
        var sampleCards = new List<PaymentMethodDto>
        {
            new()
            {
                Id = Guid.NewGuid(),
                PartnerId = 42,
                CardHolderName = "CARLOS MENDOZA",
                MaskedCardNumber = "**** **** **** 4242",
                CardType = "Visa",
                ExpiryDate = "12/28",
                IsDefault = true,
                CreatedAt = DateTime.UtcNow
            }
        };

        _serviceMock.Setup(s => s.GetByPartnerIdAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(sampleCards);

        var result = await _controller.GetAll(CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        var apiResponse = okResult.Value as ApiResponse<List<PaymentMethodDto>>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data.Should().HaveCount(1);
        apiResponse.Data!.First().MaskedCardNumber.Should().Be("**** **** **** 4242");
    }

    [Fact]
    public async Task Create_ValidCard_Returns201Created()
    {
        var dto = new CreatePaymentMethodDto
        {
            CardNumber = "4242424242424242",
            CardHolderName = "CARLOS MENDOZA",
            ExpiryDate = "12/28",
            Cvv = "123",
            IsDefault = true
        };

        var createdCard = new PaymentMethodDto
        {
            Id = Guid.NewGuid(),
            PartnerId = 42,
            CardHolderName = "CARLOS MENDOZA",
            MaskedCardNumber = "**** **** **** 4242",
            CardType = "Visa",
            ExpiryDate = "12/28",
            IsDefault = true,
            CreatedAt = DateTime.UtcNow
        };

        _serviceMock.Setup(s => s.CreateAsync(42, dto, It.IsAny<CancellationToken>()))
            .ReturnsAsync(createdCard);

        var result = await _controller.Create(dto, CancellationToken.None);

        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status201Created);
        var apiResponse = objResult.Value as ApiResponse<PaymentMethodDto>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.MaskedCardNumber.Should().Be("**** **** **** 4242");
    }

    [Fact]
    public async Task Create_NullDto_ReturnsBadRequest()
    {
        var result = await _controller.Create(null, CancellationToken.None);
        result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task Delete_ExistingCardBelongingToUser_ReturnsOk()
    {
        var cardId = Guid.NewGuid();
        _serviceMock.Setup(s => s.DeleteAsync(cardId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var result = await _controller.Delete(cardId, CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task Delete_CardNotFoundOrOtherUser_ReturnsNotFound()
    {
        var cardId = Guid.NewGuid();
        _serviceMock.Setup(s => s.DeleteAsync(cardId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var result = await _controller.Delete(cardId, CancellationToken.None);

        result.Should().BeOfType<NotFoundObjectResult>();
    }
}
