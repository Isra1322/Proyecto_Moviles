namespace ECommerce.Application.DTOs.Orders;

public class CreateOrderDto
{
    public int CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public string? CustomerEmail { get; set; }
    public List<CreateOrderItemDto> Items { get; set; } = new();
}

