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
        var product = OdooJsonHelper.GetMany2One(line.ProductId);

        return new OrderItemDto
        {
            Id = line.Id,
            ProductId = product?.Id ?? 0,
            ProductName = product?.Name ?? line.Name,
            Quantity = line.ProductUomQty,
            UnitPrice = line.PriceUnit,
            Subtotal = line.PriceSubtotal
        };
    }

    public static OrderDto ToDto(OdooOrderModel order, List<OdooOrderLineModel>? lines = null)
    {
        var partner = OdooJsonHelper.GetMany2One(order.PartnerId);
        var dateString = OdooJsonHelper.GetStringOrNull(order.DateOrder);
        DateTime.TryParse(dateString, out var orderDate);

        var itemDtos = lines != null && lines.Count > 0
            ? lines.Select(ToItemDto).ToList()
            : OdooJsonHelper.GetIntList(order.OrderLine).Select(id => new OrderItemDto { Id = id }).ToList();

        return new OrderDto
        {
            Id = order.Id,
            OdooOrderId = order.Id,
            CustomerId = partner?.Id ?? 0,
            CustomerName = partner?.Name ?? string.Empty,
            OrderDate = orderDate != default ? orderDate : DateTime.UtcNow,
            Status = MapStatus(order.State),
            TotalAmount = order.AmountTotal,
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
            var p = OdooJsonHelper.GetMany2One(l.ProductId);
            return new OrderItem
            {
                Id = l.Id,
                OrderId = order.Id,
                ProductId = p?.Id ?? 0,
                ProductName = p?.Name ?? l.Name,
                Quantity = l.ProductUomQty,
                UnitPrice = l.PriceUnit
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
            TotalAmount = order.AmountTotal,
            Items = items
        };
    }
}

