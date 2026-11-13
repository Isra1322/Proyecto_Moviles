namespace ECommerce.Application.UseCases.Orders;

using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.Interfaces;

public class GetOrderByIdUseCase
{
    private readonly IOdooService _odooService;

    public GetOrderByIdUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<OrderDto> ExecuteAsync(int orderId, CancellationToken cancellationToken = default)
    {
        if (orderId <= 0)
        {
            throw new ArgumentException("El identificador del pedido debe ser mayor a cero.", nameof(orderId));
        }

        return await _odooService.GetOrderByIdAsync(orderId, cancellationToken);
    }
}
