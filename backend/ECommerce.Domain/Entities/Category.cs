namespace ECommerce.Domain.Entities;

using ECommerce.Domain.Common;

public class Category : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public int? ParentId { get; set; }
    public string? ParentName { get; set; }
}

