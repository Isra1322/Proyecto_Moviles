namespace ECommerce.Tests.Controllers;

using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Payments;
using ECommerce.WebApi.Controllers;

public class PaymentsControllerTests
{
    private readonly Mock<IConfiguration> _configMock;
    private readonly Mock<ILogger<PaymentsController>> _loggerMock;
    private readonly PaymentsController _controller;

    public PaymentsControllerTests()
    {
        _configMock = new Mock<IConfiguration>();
        _configMock.Setup(c => c["StripeSettings:SecretKey"]).Returns("sk_test_mock_secret_key");
        _configMock.Setup(c => c["StripeSettings:PublishableKey"]).Returns("pk_test_mock_pub_key");

        _loggerMock = new Mock<ILogger<PaymentsController>>();
        _controller = new PaymentsController(_configMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task CreatePaymentIntent_ReturnsBadRequest_WhenDtoIsNull()
    {
        var result = await _controller.CreatePaymentIntent(null!, CancellationToken.None);

        result.Should().BeOfType<BadRequestObjectResult>();
        var badRequest = (BadRequestObjectResult)result;
        var response = badRequest.Value as ApiResponse<object>;
        response.Should().NotBeNull();
        response!.Success.Should().BeFalse();
        response.Message.Should().Contain("monto");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-5)]
    [InlineData(-100)]
    public async Task CreatePaymentIntent_ReturnsBadRequest_WhenAmountIsZeroOrNegative(decimal invalidAmount)
    {
        var dto = new CreatePaymentIntentDto { Amount = invalidAmount };

        var result = await _controller.CreatePaymentIntent(dto, CancellationToken.None);

        result.Should().BeOfType<BadRequestObjectResult>();
        var badRequest = (BadRequestObjectResult)result;
        var response = badRequest.Value as ApiResponse<object>;
        response.Should().NotBeNull();
        response!.Success.Should().BeFalse();
        response.Message.Should().Contain("monto");
    }
}
