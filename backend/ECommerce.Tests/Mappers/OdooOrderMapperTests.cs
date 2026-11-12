namespace ECommerce.Tests.Mappers;

using FluentAssertions;
using ECommerce.Domain.Enums;
using ECommerce.Infrastructure.Mappers;

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
}

