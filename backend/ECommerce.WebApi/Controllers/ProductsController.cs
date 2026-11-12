namespace ECommerce.WebApi.Controllers;

using Microsoft.AspNetCore.Mvc;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Products;
using ECommerce.Application.UseCases.Products;

public class ProductsController : BaseApiController
{
    private readonly GetProductsUseCase _getProductsUseCase;
    private readonly GetProductByIdUseCase _getProductByIdUseCase;

    public ProductsController(
        GetProductsUseCase getProductsUseCase,
        GetProductByIdUseCase getProductByIdUseCase)
    {
        _getProductsUseCase = getProductsUseCase;
        _getProductByIdUseCase = getProductByIdUseCase;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<ProductDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll([FromQuery] int? categoryId, CancellationToken cancellationToken)
    {
        var products = await _getProductsUseCase.ExecuteAsync(categoryId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<ProductDto>>.Ok(products));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
    {
        var product = await _getProductByIdUseCase.ExecuteAsync(id, cancellationToken);
        return Ok(ApiResponse<ProductDto>.Ok(product));
    }
}

