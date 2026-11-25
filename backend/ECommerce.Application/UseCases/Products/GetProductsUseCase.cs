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
        var products = await _odooService.GetProductsAsync(categoryId, cancellationToken);
        return products.Where(p => p.Stock > 0).ToList();
    }
}

