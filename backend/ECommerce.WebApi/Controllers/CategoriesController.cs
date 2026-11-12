namespace ECommerce.WebApi.Controllers;

using Microsoft.AspNetCore.Mvc;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Products;
using ECommerce.Application.UseCases.Categories;

public class CategoriesController : BaseApiController
{
    private readonly GetCategoriesUseCase _getCategoriesUseCase;

    public CategoriesController(GetCategoriesUseCase getCategoriesUseCase)
    {
        _getCategoriesUseCase = getCategoriesUseCase;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<CategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var categories = await _getCategoriesUseCase.ExecuteAsync(cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<CategoryDto>>.Ok(categories));
    }
}

