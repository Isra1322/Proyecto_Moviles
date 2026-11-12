namespace ECommerce.Application.UseCases.Orders;

using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.Interfaces;

public class GetOrdersUseCase
{
    private readonly IOdooService _odooService;

    public GetOrdersUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<IReadOnlyList<OrderDto>> ExecuteAsync(int customerId, CancellationToken cancellationToken = default)
    {
        if (customerId <= 0)
        {
            throw new ArgumentException("El identificador del cliente debe ser mayor a cero.", nameof(customerId));
        }

        return await _odooService.GetOrdersByCustomerAsync(customerId, cancellationToken);
    }
}

