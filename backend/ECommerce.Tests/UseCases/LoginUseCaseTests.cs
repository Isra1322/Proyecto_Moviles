namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Auth;

public class LoginUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly Mock<IPendingRegistrationService> _pendingRegistrationServiceMock;
    private readonly LoginUseCase _useCase;

    public LoginUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _pendingRegistrationServiceMock = new Mock<IPendingRegistrationService>();
        _useCase = new LoginUseCase(_odooServiceMock.Object, _pendingRegistrationServiceMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_WhenCredentialsValid_ReturnsSuccessfulLogin()
    {
        // Arrange
        var request = new LoginRequestDto { Username = "user@example.com", Password = "secret" };
        var expectedResponse = new LoginResponseDto
        {
            IsAuthenticated = true,
            Uid = 10,
            Username = "user@example.com",
            Name = "Test User"
        };

        _pendingRegistrationServiceMock
            .Setup(p => p.IsEmailPendingAsync(request.Username))
            .ReturnsAsync(false);

        _odooServiceMock
            .Setup(s => s.AuthenticateAsync(request.Username, request.Password, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedResponse);

        // Act
        var result = await _useCase.ExecuteAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.IsAuthenticated.Should().BeTrue();
        result.Uid.Should().Be(10);
        result.Username.Should().Be("user@example.com");
    }

    [Fact]
    public async Task ExecuteAsync_WhenEmailIsPendingVerification_ReturnsUnauthorizedMessageWithoutCallingOdoo()
    {
        // Arrange
        var request = new LoginRequestDto { Username = "unverified@example.com", Password = "secret" };

        _pendingRegistrationServiceMock
            .Setup(p => p.IsEmailPendingAsync(request.Username))
            .ReturnsAsync(true);

        // Act
        var result = await _useCase.ExecuteAsync(request);

        // Assert
        result.Should().NotBeNull();
        result.IsAuthenticated.Should().BeFalse();
        result.Message.Should().Be("Debes verificar tu correo antes de iniciar sesión");

        _odooServiceMock.Verify(
            s => s.AuthenticateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never
        );
    }

    [Theory]
    [InlineData("", "password")]
    [InlineData("   ", "password")]
    [InlineData("user", "")]
    [InlineData("user", "   ")]
    public async Task ExecuteAsync_WhenCredentialsEmpty_ReturnsNotAuthenticatedWithoutCallingService(string username, string password)
    {
        // Arrange
        var request = new LoginRequestDto { Username = username, Password = password };

        // Act
        var result = await _useCase.ExecuteAsync(request);

        // Assert
        result.IsAuthenticated.Should().BeFalse();
        result.Message.Should().NotBeNullOrWhiteSpace();
        _odooServiceMock.Verify(s => s.AuthenticateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}
