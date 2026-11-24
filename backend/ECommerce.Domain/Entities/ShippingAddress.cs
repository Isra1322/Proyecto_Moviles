namespace ECommerce.Domain.Entities;

public class ShippingAddress
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public int PartnerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Street { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string StateOrProvince { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public string? Reference { get; set; }
    public string Phone { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
