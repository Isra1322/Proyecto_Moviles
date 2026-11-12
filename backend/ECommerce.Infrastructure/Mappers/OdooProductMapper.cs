namespace ECommerce.Infrastructure.Mappers;

using ECommerce.Application.DTOs.Products;
using ECommerce.Domain.Entities;
using ECommerce.Infrastructure.Odoo.Models;

public static class OdooProductMapper
{
    public static ProductDto ToDto(OdooProductModel model)
    {
        var category = OdooJsonHelper.GetMany2One(model.CategId);
        var description = OdooJsonHelper.GetStringOrNull(model.DescriptionSale);
        var barcode = OdooJsonHelper.GetStringOrNull(model.Barcode);
        var defaultCode = OdooJsonHelper.GetStringOrNull(model.DefaultCode);
        var imageUrl = MapImageUrl(model.Image128);

        return new ProductDto
        {
            Id = model.Id,
            Name = model.Name,
            Description = description,
            Price = model.ListPrice,
            Stock = model.QtyAvailable,
            CategoryId = category?.Id,
            CategoryName = category?.Name,
            Barcode = barcode,
            DefaultCode = defaultCode,
            ImageUrl = imageUrl
        };
    }

    public static Product ToEntity(OdooProductModel model)
    {
        var category = OdooJsonHelper.GetMany2One(model.CategId);
        var imageUrl = MapImageUrl(model.Image128);

        return new Product
        {
            Id = model.Id,
            Name = model.Name,
            Description = OdooJsonHelper.GetStringOrNull(model.DescriptionSale),
            Price = model.ListPrice,
            Stock = model.QtyAvailable,
            CategoryId = category?.Id,
            CategoryName = category?.Name,
            ImageUrl = imageUrl,
            Barcode = OdooJsonHelper.GetStringOrNull(model.Barcode),
            DefaultCode = OdooJsonHelper.GetStringOrNull(model.DefaultCode)
        };
    }

    public static string? MapImageUrl(object? imageValue)
    {
        var rawImage = OdooJsonHelper.GetStringOrNull(imageValue);
        if (string.IsNullOrWhiteSpace(rawImage))
        {
            return null;
        }

        rawImage = rawImage.Trim();

        if (rawImage.StartsWith("data:image", StringComparison.OrdinalIgnoreCase) ||
            rawImage.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            rawImage.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return rawImage;
        }

        return $"data:image/png;base64,{rawImage}";
    }
}

