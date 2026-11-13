namespace ECommerce.Infrastructure.Mappers;

using ECommerce.Application.DTOs.Orders;
using ECommerce.Domain.Entities;
using ECommerce.Domain.Enums;
using ECommerce.Infrastructure.Odoo.Models;

public static class OdooOrderMapper
{
    public static OrderStatus MapStatus(string? odooState)
    {
        return odooState?.ToLowerInvariant() switch
        {
            "draft" => OrderStatus.Draft,
            "sent" => OrderStatus.Sent,
            "sale" => OrderStatus.Confirmed,
            "done" => OrderStatus.Done,
            "cancel" => OrderStatus.Cancelled,
            _ => OrderStatus.Draft
        };
    }

    public static OrderItemDto ToItemDto(OdooOrderLineModel line)
    {
        var lineName = OdooJsonHelper.GetStringOrNull(line.Name);
        var (productId, productName) = OdooJsonHelper.ExtractProductIdAndName(line.ProductId, lineName);

        var quantity = OdooJsonHelper.SafeToDecimal(line.ProductUomQty, 0m);
        var priceUnit = OdooJsonHelper.SafeToDecimal(line.PriceUnit, 0m);
        var priceSubtotal = OdooJsonHelper.SafeToDecimal(line.PriceSubtotal, 0m);

        var subtotal = priceSubtotal != 0m
            ? priceSubtotal
            : (quantity * priceUnit);

        return new OrderLineDto
        {
            Id = line.Id,
            ProductId = productId,
            ProductName = productName,
            Quantity = quantity,
            UnitPrice = priceUnit,
            Subtotal = subtotal
        };
    }

    public static OrderDto ToSummaryDto(OdooOrderModel order, int defaultCustomerId = 0)
    {
        var partner = OdooJsonHelper.GetMany2One(order.PartnerId);
        var dateString = OdooJsonHelper.GetStringOrNull(order.DateOrder);
        DateTime.TryParse(dateString, out var orderDate);

        var customerId = partner?.Id ?? 0;
        if (customerId <= 0 && defaultCustomerId > 0)
        {
            customerId = defaultCustomerId;
        }

        var totalAmount = OdooJsonHelper.SafeToDecimal(order.AmountTotal, 0m);

        return new OrderDto
        {
            Id = order.Id,
            OdooOrderId = order.Id,
            CustomerId = customerId,
            CustomerName = partner?.Name ?? string.Empty,
            OrderDate = orderDate != default ? orderDate : DateTime.UtcNow,
            Status = MapStatus(order.State),
            TotalAmount = totalAmount,
            Items = new List<OrderItemDto>()
        };
    }

    public static OrderDto ToDto(OdooOrderModel order, List<OdooOrderLineModel>? lines = null)
    {
        var partner = OdooJsonHelper.GetMany2One(order.PartnerId);
        var dateString = OdooJsonHelper.GetStringOrNull(order.DateOrder);
        DateTime.TryParse(dateString, out var orderDate);

        var itemDtos = lines != null && lines.Count > 0
            ? lines.Select(ToItemDto).ToList()
            : new List<OrderItemDto>();

        var totalAmount = OdooJsonHelper.SafeToDecimal(order.AmountTotal, 0m);

        return new OrderDto
        {
            Id = order.Id,
            OdooOrderId = order.Id,
            CustomerId = partner?.Id ?? 0,
            CustomerName = partner?.Name ?? string.Empty,
            OrderDate = orderDate != default ? orderDate : DateTime.UtcNow,
            Status = MapStatus(order.State),
            TotalAmount = totalAmount,
            Items = itemDtos
        };
    }

    public static Order ToEntity(OdooOrderModel order, List<OdooOrderLineModel>? lines = null)
    {
        var partner = OdooJsonHelper.GetMany2One(order.PartnerId);
        var dateString = OdooJsonHelper.GetStringOrNull(order.DateOrder);
        DateTime.TryParse(dateString, out var orderDate);

        var items = lines?.Select(l =>
        {
            var itemDto = ToItemDto(l);
            return new OrderItem
            {
                Id = itemDto.Id,
                OrderId = order.Id,
                ProductId = itemDto.ProductId,
                ProductName = itemDto.ProductName,
                Quantity = itemDto.Quantity,
                UnitPrice = itemDto.UnitPrice
            };
        }).ToList() ?? new List<OrderItem>();

        return new Order
        {
            Id = order.Id,
            OdooOrderId = order.Id,
            CustomerId = partner?.Id ?? 0,
            CustomerName = partner?.Name ?? string.Empty,
            OrderDate = orderDate != default ? orderDate : DateTime.UtcNow,
            Status = MapStatus(order.State),
            TotalAmount = OdooJsonHelper.SafeToDecimal(order.AmountTotal, 0m),
            Items = items
        };
    }
}

