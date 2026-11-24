namespace ECommerce.Domain.Entities;

public class PaymentMethod
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public int PartnerId { get; set; }
    public string CardHolderName { get; set; } = string.Empty;
    public string MaskedCardNumber { get; set; } = string.Empty;
    public string CardType { get; set; } = string.Empty;
    public string ExpiryDate { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
