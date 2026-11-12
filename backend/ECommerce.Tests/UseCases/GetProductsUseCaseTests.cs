namespace ECommerce.Tests.UseCases;

using FluentAssertions;
using Moq;
using ECommerce.Application.DTOs.Products;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Products;

public class GetProductsUseCaseTests
{
    private readonly Mock<IOdooService> _odooServiceMock;
    private readonly GetProductsUseCase _useCase;

    public GetProductsUseCaseTests()
    {
        _odooServiceMock = new Mock<IOdooService>();
        _useCase = new GetProductsUseCase(_odooServiceMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_ReturnsProductsFromService()
    {
        // Arrange
        var products = new List<ProductDto>
        {
            new() { Id = 1, Name = "Laptop Gamer", Price = 1200m, Stock = 5 },
            new() { Id = 2, Name = "Mouse Inalámbrico", Price = 30m, Stock = 40 }
        };

        _odooServiceMock
            .Setup(s => s.GetProductsAsync(null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(products);

        // Act
        var result = await _useCase.ExecuteAsync();

        // Assert
        result.Should().NotBeNull();
        result.Should().HaveCount(2);
        result.First().Name.Should().Be("Laptop Gamer");
    }

    [Fact]
    public async Task ExecuteAsync_WithCategoryId_PassesFilterToService()
    {
        // Arrange
        int categoryId = 3;
        _odooServiceMock
            .Setup(s => s.GetProductsAsync(categoryId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<ProductDto>());

        // Act
        var result = await _useCase.ExecuteAsync(categoryId);

        // Assert
        _odooServiceMock.Verify(s => s.GetProductsAsync(categoryId, It.IsAny<CancellationToken>()), Times.Once);
    }
}

