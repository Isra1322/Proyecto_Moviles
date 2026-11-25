namespace ECommerce.Tests.Controllers;

using System.Text;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Auth;
using ECommerce.WebApi.Controllers;

public class AuthControllerTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly Mock<IPendingRegistrationService> _pendingRegistrationServiceMock;
    private readonly Mock<IEmailService> _emailServiceMock;
    private readonly Mock<ILogger<AuthController>> _loggerMock;
    private readonly LoginUseCase _loginUseCase;
    private readonly RegisterUseCase _registerUseCase;
    private readonly AuthController _controller;

    public AuthControllerTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _pendingRegistrationServiceMock = new Mock<IPendingRegistrationService>();
        _emailServiceMock = new Mock<IEmailService>();
        _loggerMock = new Mock<ILogger<AuthController>>();

        _loginUseCase = new LoginUseCase(_odooServiceMock.Object, _pendingRegistrationServiceMock.Object);
        _registerUseCase = new RegisterUseCase(_odooServiceMock.Object, _pendingRegistrationServiceMock.Object, _emailServiceMock.Object);

        _controller = new AuthController(
            _loginUseCase,
            _registerUseCase,
            _odooServiceMock.Object,
            _pendingRegistrationServiceMock.Object,
            _loggerMock.Object
        );
    }

    [Fact]
    public async Task Register_WhenValid_ReturnsOkWithRequiresVerification()
    {
        var request = new RegisterRequestDto
        {
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            Password = "Password123"
        };

        _odooServiceMock
            .Setup(s => s.CheckEmailExistsAsync(request.Email, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        _pendingRegistrationServiceMock
            .Setup(p => p.RegisterPendingAsync(request.Name, request.Email, request.Password, request.Phone))
            .ReturnsAsync("token123");

        var response = await _controller.Register(request, CancellationToken.None);

        var okResult = response.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<RegisterResponseDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.RequiresVerification.Should().BeTrue();
        apiResponse.Data.Email.Should().Be("carlos@example.com");
    }

    [Fact]
    public async Task Login_WhenEmailIsPendingVerification_ReturnsUnauthorizedWithRequiredMessage()
    {
        var request = new LoginRequestDto
        {
            Username = "unverified@example.com",
            Password = "Password123"
        };

        _pendingRegistrationServiceMock
            .Setup(p => p.IsEmailPendingAsync(request.Username))
            .ReturnsAsync(true);

        var response = await _controller.Login(request, CancellationToken.None);

        var unauthResult = response.Should().BeOfType<UnauthorizedObjectResult>().Subject;
        var apiResponse = unauthResult.Value.Should().BeOfType<ApiResponse<LoginResponseDto>>().Subject;

        apiResponse.Success.Should().BeFalse();
        apiResponse.Message.Should().Be("Debes verificar tu correo antes de iniciar sesión");
    }

    [Fact]
    public async Task VerifyEmail_WhenTokenInvalidOrExpired_ReturnsErrorHtml()
    {
        _pendingRegistrationServiceMock
            .Setup(p => p.GetPendingAsync("invalid_token"))
            .ReturnsAsync((PendingUserRegistration?)null);

        var response = await _controller.VerifyEmail("invalid_token", CancellationToken.None);

        var contentResult = response.Should().BeOfType<ContentResult>().Subject;
        contentResult.ContentType.Should().StartWith("text/html");
        contentResult.Content.Should().Contain("El enlace de confirmación es inválido o ha expirado");
    }

    [Fact]
    public async Task VerifyEmail_WhenTokenValid_CreatesPartnerInOdooAndReturnsSuccessHtml()
    {
        var pending = new PendingUserRegistration
        {
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            Password = "Password123",
            Phone = "0991234567"
        };

        _pendingRegistrationServiceMock
            .Setup(p => p.GetPendingAsync("valid_token_123"))
            .ReturnsAsync(pending);

        _odooServiceMock
            .Setup(s => s.RegisterCustomerAsync(It.Is<RegisterRequestDto>(r => r.Email == pending.Email), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new RegisterResponseDto
            {
                Success = true,
                PartnerId = 99,
                Name = pending.Name,
                Email = pending.Email
            });

        var response = await _controller.VerifyEmail("valid_token_123", CancellationToken.None);

        var contentResult = response.Should().BeOfType<ContentResult>().Subject;
        contentResult.ContentType.Should().StartWith("text/html");
        contentResult.Content.Should().Contain("¡Cuenta Activada!");
        contentResult.Content.Should().Contain("E-Commerce Móvil");

        _odooServiceMock.Verify(s => s.RegisterCustomerAsync(It.IsAny<RegisterRequestDto>(), It.IsAny<CancellationToken>()), Times.Once);
        _pendingRegistrationServiceMock.Verify(p => p.RemovePendingAsync("valid_token_123"), Times.Once);
    }
}
