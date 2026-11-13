namespace ECommerce.Application.DTOs.Orders;

using System.Text.Json.Serialization;
using ECommerce.Domain.Enums;

public class OrderDto
{
    public int Id { get; set; }
    public int? OdooOrderId { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public DateTime OrderDate { get; set; }
    public OrderStatus Status { get; set; }
    public string StatusName => Status.ToString();
    public decimal TotalAmount { get; set; }

    [JsonPropertyName("amount_total")]
    public decimal AmountTotal => TotalAmount;

    public List<OrderItemDto> Items { get; set; } = new();
    public List<OrderItemDto> OrderLines => Items;
}

