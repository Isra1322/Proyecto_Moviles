namespace ECommerce.Tests.Mappers;

using System.Text.Json;
using FluentAssertions;
using ECommerce.Infrastructure.Mappers;
using ECommerce.Infrastructure.Odoo.Models;

public class OdooProductMapperTests
{
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("false")]
    public void MapImageUrl_WithNullOrEmptyOrFalseString_ReturnsNull(string? input)
    {
        var result = OdooProductMapper.MapImageUrl(input);
        result.Should().BeNull();
    }

    [Fact]
    public void MapImageUrl_WithBooleanFalse_ReturnsNull()
    {
        var result = OdooProductMapper.MapImageUrl(false);
        result.Should().BeNull();
    }

    [Fact]
    public void MapImageUrl_WithPureBase64String_FormatsAsDataUri()
    {
        const string pureBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";
        var result = OdooProductMapper.MapImageUrl(pureBase64);

        result.Should().Be($"data:image/png;base64,{pureBase64}");
    }

    [Fact]
    public void MapImageUrl_WithDataUriPrefix_PreservesFormat()
    {
        const string dataUri = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD";
        var result = OdooProductMapper.MapImageUrl(dataUri);

        result.Should().Be(dataUri);
    }

    [Fact]
    public void MapImageUrl_WithHttpUrl_PreservesUrl()
    {
        const string httpUrl = "https://example.com/images/product.png";
        var result = OdooProductMapper.MapImageUrl(httpUrl);

        result.Should().Be(httpUrl);
    }

    [Fact]
    public void MapImageUrl_WithOdooObjectContent_ExtractsAndFormatsDataUri()
    {
        const string base64Payload = "iVBORw0KGgoAAAANSUhEUg==";
        var json = $"{{\"content\":\"{base64Payload}\",\"size\":23840}}";
        using var doc = JsonDocument.Parse(json);

        var result = OdooProductMapper.MapImageUrl(doc.RootElement);

        result.Should().Be($"data:image/png;base64,{base64Payload}");
    }

    [Fact]
    public void ToDto_MapsImageAndPropertiesCorrectly()
    {
        var model = new OdooProductModel
        {
            Id = 1,
            Name = "Camiseta Deportiva",
            ListPrice = 25.0m,
            QtyAvailable = 10.0m,
            Image128 = "iVBORw0KGgo=="
        };

        var dto = OdooProductMapper.ToDto(model);

        dto.Id.Should().Be(1);
        dto.Name.Should().Be("Camiseta Deportiva");
        dto.Price.Should().Be(25.0m);
        dto.Stock.Should().Be(10.0m);
        dto.ImageUrl.Should().Be("data:image/png;base64,iVBORw0KGgo==");
    }

    [Fact]
    public void ToEntity_MapsImageUrlCorrectly()
    {
        var model = new OdooProductModel
        {
            Id = 1,
            Name = "Camiseta Deportiva",
            ListPrice = 25.0m,
            QtyAvailable = 10.0m,
            Image128 = "iVBORw0KGgo=="
        };

        var entity = OdooProductMapper.ToEntity(model);

        entity.Id.Should().Be(1);
        entity.Name.Should().Be("Camiseta Deportiva");
        entity.Price.Should().Be(25.0m);
        entity.Stock.Should().Be(10.0m);
        entity.ImageUrl.Should().Be("data:image/png;base64,iVBORw0KGgo==");
    }
}
