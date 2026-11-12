namespace ECommerce.Application.Interfaces;

using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.DTOs.Products;

public interface IOdooService
{
    Task<LoginResponseDto> AuthenticateAsync(string username, string password, CancellationToken cancellationToken = default);
    Task<RegisterResponseDto> RegisterCustomerAsync(RegisterRequestDto request, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ProductDto>> GetProductsAsync(int? categoryId = null, CancellationToken cancellationToken = default);
    Task<ProductDto?> GetProductByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<CategoryDto>> GetCategoriesAsync(CancellationToken cancellationToken = default);
    Task<OrderDto> CreateOrderAsync(CreateOrderDto orderDto, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<OrderDto>> GetOrdersByCustomerAsync(int customerId, CancellationToken cancellationToken = default);
}
