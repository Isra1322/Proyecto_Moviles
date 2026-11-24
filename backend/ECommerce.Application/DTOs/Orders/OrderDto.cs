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

    [JsonPropertyName("itemsCount")]
    public int ItemsCount { get; set; }

    [JsonPropertyName("productsCount")]
    public int ProductsCount => ItemsCount;

    [JsonPropertyName("items_count")]
    public int ItemsCountSnake => ItemsCount;

    [JsonPropertyName("products_count")]
    public int ProductsCountSnake => ItemsCount;

    [JsonPropertyName("totalItemsCount")]
    public int TotalItemsCount { get; set; }

    [JsonPropertyName("total_items_count")]
    public int TotalItemsCountSnake => TotalItemsCount;

    [JsonPropertyName("totalQuantity")]
    public int TotalQuantity => TotalItemsCount;

    [JsonPropertyName("order_line")]
    public int[] OrderLine => Enumerable.Range(0, ItemsCount).ToArray();

    public List<OrderItemDto> Items { get; set; } = new();
    public List<OrderItemDto> OrderLines => Items;
}

