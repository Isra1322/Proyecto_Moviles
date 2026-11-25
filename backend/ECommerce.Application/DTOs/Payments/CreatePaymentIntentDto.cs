namespace ECommerce.Application.DTOs.Payments;

public class CreatePaymentIntentDto
{
    public decimal Amount { get; set; }
    public string? Currency { get; set; } = "usd";
    public string? CustomerEmail { get; set; }
    public string? CustomerName { get; set; }
}

public class PaymentIntentResultDto
{
    public string? ClientSecret { get; set; }
    public string? PaymentIntentId { get; set; }
    public string? CustomerId { get; set; }
    public string? EphemeralKeySecret { get; set; }
    public string? PublishableKey { get; set; }
}
