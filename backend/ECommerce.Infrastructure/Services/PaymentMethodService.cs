namespace ECommerce.Infrastructure.Services;

using ECommerce.Application.DTOs.PaymentMethods;
using ECommerce.Application.Interfaces;

/// <summary>
/// Servicio obsoleto de métodos de pago locales.
/// El almacenamiento de tarjetas en archivos JSON ha sido eliminado permanentemente en favor de Stripe.
/// </summary>
public class PaymentMethodService : IPaymentMethodService
{
    public Task<List<PaymentMethodDto>> GetByPartnerIdAsync(int partnerId, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(new List<PaymentMethodDto>());
    }

    public Task<PaymentMethodDto?> GetByIdAsync(Guid id, int partnerId, CancellationToken cancellationToken = default)
    {
        return Task.FromResult<PaymentMethodDto?>(null);
    }

    public Task<PaymentMethodDto> CreateAsync(int partnerId, CreatePaymentMethodDto dto, CancellationToken cancellationToken = default)
    {
        throw new NotSupportedException("El almacenamiento local de tarjetas ha sido eliminado. Los pagos se procesan exclusivamente a través de Stripe.");
    }

    public Task<bool> DeleteAsync(Guid id, int partnerId, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(false);
    }
}
