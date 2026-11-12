namespace ECommerce.Application.UseCases.Products;

using ECommerce.Application.Common.Exceptions;
using ECommerce.Application.DTOs.Products;
using ECommerce.Application.Interfaces;

public class GetProductByIdUseCase
{
    private readonly IOdooService _odooService;

    public GetProductByIdUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<ProductDto> ExecuteAsync(int id, CancellationToken cancellationToken = default)
    {
        var product = await _odooService.GetProductByIdAsync(id, cancellationToken);
        if (product is null)
        {
            throw new NotFoundException("Product", id);
        }

        return product;
    }
}

