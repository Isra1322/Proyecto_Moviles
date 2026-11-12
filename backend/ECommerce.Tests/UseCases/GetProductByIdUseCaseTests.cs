namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.Common.Exceptions;
using ECommerce.Application.DTOs.Products;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Products;

public class GetProductByIdUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly GetProductByIdUseCase _useCase;

    public GetProductByIdUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _useCase = new GetProductByIdUseCase(_odooServiceMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_WhenProductExists_ReturnsProduct()
    {
        // Arrange
        var product = new ProductDto { Id = 10, Name = "Teclado Mecánico", Price = 75m, Stock = 15 };
        _odooServiceMock
            .Setup(s => s.GetProductByIdAsync(10, It.IsAny<CancellationToken>()))
            .ReturnsAsync(product);

        // Act
        var result = await _useCase.ExecuteAsync(10);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(10);
        result.Name.Should().Be("Teclado Mecánico");
    }

    [Fact]
    public async Task ExecuteAsync_WhenProductDoesNotExist_ThrowsNotFoundException()
    {
        // Arrange
        _odooServiceMock
            .Setup(s => s.GetProductByIdAsync(999, It.IsAny<CancellationToken>()))
            .ReturnsAsync((ProductDto?)null);

        // Act
        var act = async () => await _useCase.ExecuteAsync(999);

        // Assert
        await act.Should().ThrowAsync<NotFoundException>();
    }
}

