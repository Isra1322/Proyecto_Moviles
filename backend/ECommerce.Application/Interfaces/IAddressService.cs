namespace ECommerce.Application.Interfaces;

using ECommerce.Application.DTOs.Addresses;

public interface IAddressService
{
    Task<List<AddressDto>> GetByPartnerIdAsync(int partnerId, CancellationToken cancellationToken = default);
    Task<AddressDto?> GetByIdAsync(Guid id, int partnerId, CancellationToken cancellationToken = default);
    Task<AddressDto> CreateAsync(int partnerId, CreateAddressDto dto, CancellationToken cancellationToken = default);
    Task<AddressDto?> UpdateAsync(Guid id, int partnerId, UpdateAddressDto dto, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid id, int partnerId, CancellationToken cancellationToken = default);
    Task<AddressDto?> SetDefaultAsync(Guid id, int partnerId, CancellationToken cancellationToken = default);
}
