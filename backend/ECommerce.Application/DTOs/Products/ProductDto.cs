namespace ECommerce.Application.DTOs.Products;

public class ProductDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public decimal Stock { get; set; }
    public int? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public string? Barcode { get; set; }
    public string? DefaultCode { get; set; }
}

