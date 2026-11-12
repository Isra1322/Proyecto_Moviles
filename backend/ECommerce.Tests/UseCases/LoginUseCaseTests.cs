namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Auth;

public class LoginUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly LoginUseCase _useCase;

    public LoginUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _useCase = new LoginUseCase(_odooServiceMock.Object);
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

