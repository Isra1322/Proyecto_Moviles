namespace ECommerce.Application.DTOs.Orders;

public class CreateOrderItemDto
{
    public int ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

