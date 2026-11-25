namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Auth;

public class RegisterUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly Mock<IPendingRegistrationService> _pendingRegistrationServiceMock;
    private readonly Mock<IEmailService> _emailServiceMock;
    private readonly RegisterUseCase _useCase;

    public RegisterUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _pendingRegistrationServiceMock = new Mock<IPendingRegistrationService>();
        _emailServiceMock = new Mock<IEmailService>();

        _useCase = new RegisterUseCase(
            _odooServiceMock.Object,
            _pendingRegistrationServiceMock.Object,
            _emailServiceMock.Object
        );
    }

    [Fact]
    public async Task ExecuteAsync_WithValidRequest_SavesPendingAndSendsVerificationEmailWithoutCreatingOdooPartner()
    {
        var request = new RegisterRequestDto
        {
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            Password = "Password123!",
            Phone = "0991234567"
        };

        _odooServiceMock
            .Setup(s => s.CheckEmailExistsAsync(request.Email, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        _pendingRegistrationServiceMock
            .Setup(p => p.RegisterPendingAsync(request.Name, request.Email, request.Password, request.Phone))
            .ReturnsAsync("verify_token_123");

        var result = await _useCase.ExecuteAsync(request);

        result.Should().NotBeNull();
        result.Success.Should().BeTrue();
        result.RequiresVerification.Should().BeTrue();
        result.Email.Should().Be("carlos@example.com");
        result.Message.Should().Contain("correo de confirmación");

        _pendingRegistrationServiceMock.Verify(
            p => p.RegisterPendingAsync(request.Name, request.Email, request.Password, request.Phone),
            Times.Once
        );

        _emailServiceMock.Verify(
            e => e.SendVerificationEmailAsync(request.Email, request.Name, "verify_token_123", It.IsAny<CancellationToken>()),
            Times.Once
        );

        // Regla obligatoria: NO crear res.partner en Odoo en este momento
        _odooServiceMock.Verify(
            s => s.RegisterCustomerAsync(It.IsAny<RegisterRequestDto>(), It.IsAny<CancellationToken>()),
            Times.Never
        );
    }

    [Fact]
    public async Task ExecuteAsync_WhenEmailAlreadyExists_ReturnsFailureWithoutSendingEmail()
    {
        var request = new RegisterRequestDto
        {
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            Password = "Password123!",
            Phone = "0991234567"
        };

        _odooServiceMock
            .Setup(s => s.CheckEmailExistsAsync(request.Email, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var result = await _useCase.ExecuteAsync(request);

        result.Should().NotBeNull();
        result.Success.Should().BeFalse();
        result.Message.Should().Be("El correo ya se encuentra registrado.");

        _pendingRegistrationServiceMock.Verify(
            p => p.RegisterPendingAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()),
            Times.Never
        );

        _emailServiceMock.Verify(
            e => e.SendVerificationEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never
        );
    }

    [Theory]
    [InlineData("", "correo@valido.com", "123456")]
    [InlineData("Juan", "correoinvalido", "123456")]
    [InlineData("Juan", "correo@valido.com", "123")]
    public async Task ExecuteAsync_WithInvalidFields_ReturnsFailureWithoutCallingService(string name, string email, string password)
    {
        var request = new RegisterRequestDto
        {
            Name = name,
            Email = email,
            Password = password
        };

        var result = await _useCase.ExecuteAsync(request);

        result.Success.Should().BeFalse();
        _odooServiceMock.Verify(s => s.CheckEmailExistsAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
        _odooServiceMock.Verify(s => s.RegisterCustomerAsync(It.IsAny<RegisterRequestDto>(), It.IsAny<CancellationToken>()), Times.Never);
        _pendingRegistrationServiceMock.Verify(p => p.RegisterPendingAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenEmailSendingFails_RemovesPendingRegistrationAndRethrows()
    {
        var request = new RegisterRequestDto
        {
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            Password = "Password123!",
            Phone = "0991234567"
        };

        _odooServiceMock
            .Setup(s => s.CheckEmailExistsAsync(request.Email, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        _pendingRegistrationServiceMock
            .Setup(p => p.RegisterPendingAsync(request.Name, request.Email, request.Password, request.Phone))
            .ReturnsAsync("verify_token_123");

        _emailServiceMock
            .Setup(e => e.SendVerificationEmailAsync(request.Email, request.Name, "verify_token_123", It.IsAny<CancellationToken>()))
            .ThrowsAsync(new System.Net.Mail.SmtpException("SMTP connection timeout"));

        var act = async () => await _useCase.ExecuteAsync(request);

        await act.Should().ThrowAsync<System.Net.Mail.SmtpException>();

        _pendingRegistrationServiceMock.Verify(
            p => p.RemovePendingAsync("verify_token_123"),
            Times.Once
        );
    }
}
