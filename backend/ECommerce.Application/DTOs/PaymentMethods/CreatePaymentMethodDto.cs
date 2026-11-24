namespace ECommerce.Application.DTOs.PaymentMethods;

public class CreatePaymentMethodDto
{
    public string CardNumber { get; set; } = string.Empty;
    public string CardHolderName { get; set; } = string.Empty;
    public string ExpiryDate { get; set; } = string.Empty;
    public string Cvv { get; set; } = string.Empty;
    public bool IsDefault { get; set; } = false;
}
