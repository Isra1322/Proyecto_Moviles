namespace ECommerce.Infrastructure.Mappers;

using ECommerce.Application.DTOs.Products;
using ECommerce.Domain.Entities;
using ECommerce.Infrastructure.Odoo.Models;

public static class OdooCategoryMapper
{
    public static CategoryDto ToDto(OdooCategoryModel model)
    {
        var parent = OdooJsonHelper.GetMany2One(model.ParentId);

        return new CategoryDto
        {
            Id = model.Id,
            Name = model.Name,
            ParentId = parent?.Id,
            ParentName = parent?.Name
        };
    }

    public static Category ToEntity(OdooCategoryModel model)
    {
        var parent = OdooJsonHelper.GetMany2One(model.ParentId);

        return new Category
        {
            Id = model.Id,
            Name = model.Name,
            ParentId = parent?.Id,
            ParentName = parent?.Name
        };
    }
}

