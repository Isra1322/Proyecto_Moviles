namespace ECommerce.Application.UseCases.Products;

using ECommerce.Application.DTOs.Products;
using ECommerce.Application.Interfaces;

public class GetProductsUseCase
{
    private readonly IOdooService _odooService;

    public GetProductsUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<IReadOnlyList<ProductDto>> ExecuteAsync(int? categoryId = null, CancellationToken cancellationToken = default)
    {
        return await _odooService.GetProductsAsync(categoryId, cancellationToken);
    }
}

