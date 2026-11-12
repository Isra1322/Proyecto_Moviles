namespace ECommerce.Domain.Entities;

using ECommerce.Domain.Common;
using ECommerce.Domain.Enums;

public class Order : BaseEntity
{
    public int? OdooOrderId { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public DateTime OrderDate { get; set; } = DateTime.UtcNow;
    public OrderStatus Status { get; set; } = OrderStatus.Draft;
    public decimal TotalAmount { get; set; }
    public List<OrderItem> Items { get; set; } = new();
}

