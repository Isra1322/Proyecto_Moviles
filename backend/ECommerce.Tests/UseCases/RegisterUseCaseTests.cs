namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Auth;

public class RegisterUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly RegisterUseCase _useCase;

    public RegisterUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _useCase = new RegisterUseCase(_odooServiceMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_WithValidRequest_ReturnsSuccess()
    {
        var request = new RegisterRequestDto
        {
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            Password = "Password123!",
            Phone = "0991234567"
        };

        var expectedResponse = new RegisterResponseDto
        {
            Success = true,
            PartnerId = 15,
            Name = "Carlos Mendoza",
            Email = "carlos@example.com",
            AccessToken = "mock.jwt.token",
            Message = "Cliente registrado exitosamente."
        };

        _odooServiceMock
            .Setup(s => s.RegisterCustomerAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedResponse);

        var result = await _useCase.ExecuteAsync(request);

        result.Should().NotBeNull();
        result.Success.Should().BeTrue();
        result.PartnerId.Should().Be(15);
        result.AccessToken.Should().Be("mock.jwt.token");
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
        _odooServiceMock.Verify(s => s.RegisterCustomerAsync(It.IsAny<RegisterRequestDto>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}
