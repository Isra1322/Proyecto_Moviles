namespace ECommerce.Tests.Mappers;

using System.Text.Json;
using FluentAssertions;
using ECommerce.Domain.Enums;
using ECommerce.Infrastructure.Mappers;
using ECommerce.Infrastructure.Odoo.Models;

public class OdooOrderMapperTests
{
    [Theory]
    [InlineData("draft", OrderStatus.Draft)]
    [InlineData("sent", OrderStatus.Sent)]
    [InlineData("sale", OrderStatus.Confirmed)]
    [InlineData("done", OrderStatus.Done)]
    [InlineData("cancel", OrderStatus.Cancelled)]
    [InlineData("unknown", OrderStatus.Draft)]
    [InlineData(null, OrderStatus.Draft)]
    public void MapStatus_MapsOdooStatesCorrectly(string? odooState, OrderStatus expectedStatus)
    {
        // Act
        var result = OdooOrderMapper.MapStatus(odooState);

        // Assert
        result.Should().Be(expectedStatus);
    }

    [Fact]
    public void ToItemDto_WhenProductIsArray_ExtractsNameAndPricesSafely()
    {
        // Arrange
        using var doc = JsonDocument.Parse("{\"id\": 10, \"product_id\": [5, \"Laptop Dell\"], \"name\": \"Dell\", \"product_uom_qty\": 2.5, \"price_unit\": 500.0, \"price_subtotal\": 1250.0}");
        var lineModel = JsonSerializer.Deserialize<OdooOrderLineModel>(doc.RootElement.GetRawText())!;

        // Act
        var dto = OdooOrderMapper.ToItemDto(lineModel);

        // Assert
        dto.Id.Should().Be(10);
        dto.ProductId.Should().Be(5);
        dto.ProductName.Should().Be("Laptop Dell");
        dto.Quantity.Should().Be(2.5m);
        dto.UnitPrice.Should().Be(500.0m);
        dto.Subtotal.Should().Be(1250.0m);
    }

    [Fact]
    public void ToItemDto_WhenProductIsFalse_UsesFallbackName()
    {
        // Arrange
        using var doc = JsonDocument.Parse("{\"id\": 11, \"product_id\": false, \"name\": \"Servicio de Envío\", \"product_uom_qty\": 1, \"price_unit\": 10, \"price_subtotal\": 10}");
        var lineModel = JsonSerializer.Deserialize<OdooOrderLineModel>(doc.RootElement.GetRawText())!;

        // Act
        var dto = OdooOrderMapper.ToItemDto(lineModel);

        // Assert
        dto.Id.Should().Be(11);
        dto.ProductId.Should().Be(0);
        dto.ProductName.Should().Be("Servicio de Envío");
        dto.Quantity.Should().Be(1m);
        dto.UnitPrice.Should().Be(10m);
        dto.Subtotal.Should().Be(10m);
    }

    [Fact]
    public void ToSummaryDto_DoesNotIncludeLines_AndMapsNumericTotal()
    {
        // Arrange
        using var doc = JsonDocument.Parse("{\"id\": 99, \"name\": \"SO099\", \"partner_id\": [7, \"Ana\"], \"date_order\": \"2026-11-13\", \"state\": \"sale\", \"amount_total\": 350.75, \"order_line\": [1, 2, 3]}");
        var orderModel = JsonSerializer.Deserialize<OdooOrderModel>(doc.RootElement.GetRawText())!;

        // Act
        var dto = OdooOrderMapper.ToSummaryDto(orderModel, defaultCustomerId: 7);

        // Assert
        dto.Id.Should().Be(99);
        dto.CustomerId.Should().Be(7);
        dto.CustomerName.Should().Be("Ana");
        dto.Status.Should().Be(OrderStatus.Confirmed);
        dto.TotalAmount.Should().Be(350.75m);
        dto.AmountTotal.Should().Be(350.75m);
        dto.Items.Should().BeEmpty(); // Garantizar que la lista resumida no contiene líneas
    }
}

