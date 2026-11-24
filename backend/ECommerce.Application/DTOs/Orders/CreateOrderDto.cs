namespace ECommerce.Application.DTOs.Orders;

public class CreateOrderDto
{
    public int CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public string? CustomerEmail { get; set; }
    public Guid? PaymentMethodId { get; set; }
    public string? PaymentReference { get; set; }
    public Guid? ShippingAddressId { get; set; }
    public string? ShippingAddressText { get; set; }
    public List<CreateOrderItemDto> Items { get; set; } = new();
}

