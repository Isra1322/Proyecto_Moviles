namespace ECommerce.Application.UseCases.Orders;

using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.Interfaces;

public class CreateOrderUseCase
{
    private readonly IOdooService _odooService;

    public CreateOrderUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<OrderDto> ExecuteAsync(CreateOrderDto orderDto, CancellationToken cancellationToken = default)
    {
        if (orderDto.CustomerId <= 0)
        {
            throw new ArgumentException("El identificador del cliente (CustomerId) es obligatorio.", nameof(orderDto));
        }

        if (orderDto.Items == null || orderDto.Items.Count == 0)
        {
            throw new ArgumentException("La orden debe contener al menos un producto.", nameof(orderDto));
        }

        foreach (var item in orderDto.Items)
        {
            if (item.ProductId <= 0)
            {
                throw new ArgumentException("El identificador del producto es inválido.", nameof(orderDto));
            }

            if (item.Quantity <= 0)
            {
                throw new ArgumentException("La cantidad debe ser mayor a cero.", nameof(orderDto));
            }

            if (item.UnitPrice < 0)
            {
                throw new ArgumentException("El precio unitario no puede ser negativo.", nameof(orderDto));
            }
        }

        return await _odooService.CreateOrderAsync(orderDto, cancellationToken);
    }
}

