namespace ECommerce.Application.UseCases.Categories;

using ECommerce.Application.DTOs.Products;
using ECommerce.Application.Interfaces;

public class GetCategoriesUseCase
{
    private readonly IOdooService _odooService;

    public GetCategoriesUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<IReadOnlyList<CategoryDto>> ExecuteAsync(CancellationToken cancellationToken = default)
    {
        return await _odooService.GetCategoriesAsync(cancellationToken);
    }
}

