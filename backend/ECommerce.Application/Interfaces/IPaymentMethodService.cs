namespace ECommerce.Application.Interfaces;

using ECommerce.Application.DTOs.PaymentMethods;

public interface IPaymentMethodService
{
    Task<List<PaymentMethodDto>> GetByPartnerIdAsync(int partnerId, CancellationToken cancellationToken = default);
    Task<PaymentMethodDto?> GetByIdAsync(Guid id, int partnerId, CancellationToken cancellationToken = default);
    Task<PaymentMethodDto> CreateAsync(int partnerId, CreatePaymentMethodDto dto, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid id, int partnerId, CancellationToken cancellationToken = default);
}
