namespace ECommerce.Infrastructure.Services;

using System.Text.Json;
using ECommerce.Application.DTOs.Addresses;
using ECommerce.Application.Interfaces;
using ECommerce.Domain.Entities;

public class AddressService : IAddressService
{
    private readonly string _filePath;
    private static readonly SemaphoreSlim _semaphore = new(1, 1);

    public AddressService()
    {
        var baseDir = AppDomain.CurrentDomain.BaseDirectory;
        var dataDir = Path.Combine(baseDir, "App_Data");
        if (!Directory.Exists(dataDir))
        {
            Directory.CreateDirectory(dataDir);
        }
        _filePath = Path.Combine(dataDir, "shipping_addresses.json");
    }

    public async Task<List<AddressDto>> GetByPartnerIdAsync(int partnerId, CancellationToken cancellationToken = default)
    {
        var addresses = await LoadAddressesAsync(cancellationToken);
        return addresses
            .Where(a => a.PartnerId == partnerId)
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt)
            .Select(MapToDto)
            .ToList();
    }

    public async Task<AddressDto?> GetByIdAsync(Guid id, int partnerId, CancellationToken cancellationToken = default)
    {
        var addresses = await LoadAddressesAsync(cancellationToken);
        var address = addresses.FirstOrDefault(a => a.Id == id && a.PartnerId == partnerId);
        return address != null ? MapToDto(address) : null;
    }

    public async Task<AddressDto> CreateAsync(int partnerId, CreateAddressDto dto, CancellationToken cancellationToken = default)
    {
        if (dto == null)
        {
            throw new ArgumentException("Los datos de la dirección son obligatorios.");
        }

        ValidateAddress(dto.Title, dto.Street, dto.City, dto.Phone);

        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var addresses = await LoadAddressesInternalAsync(cancellationToken);
            var partnerAddresses = addresses.Where(a => a.PartnerId == partnerId).ToList();

            bool isDefault = dto.IsDefault || partnerAddresses.Count == 0;
            if (isDefault)
            {
                foreach (var existing in partnerAddresses)
                {
                    existing.IsDefault = false;
                }
            }

            var newAddress = new ShippingAddress
            {
                Id = Guid.NewGuid(),
                PartnerId = partnerId,
                Title = dto.Title.Trim(),
                Street = dto.Street.Trim(),
                City = dto.City.Trim(),
                StateOrProvince = (dto.StateOrProvince ?? "").Trim(),
                PostalCode = string.IsNullOrWhiteSpace(dto.PostalCode) ? null : dto.PostalCode.Trim(),
                Reference = string.IsNullOrWhiteSpace(dto.Reference) ? null : dto.Reference.Trim(),
                Phone = dto.Phone.Trim(),
                IsDefault = isDefault,
                CreatedAt = DateTime.UtcNow
            };

            addresses.Add(newAddress);
            await SaveAddressesInternalAsync(addresses, cancellationToken);

            return MapToDto(newAddress);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task<AddressDto?> UpdateAsync(Guid id, int partnerId, UpdateAddressDto dto, CancellationToken cancellationToken = default)
    {
        if (dto == null)
        {
            throw new ArgumentException("Los datos de la dirección son obligatorios.");
        }

        ValidateAddress(dto.Title, dto.Street, dto.City, dto.Phone);

        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var addresses = await LoadAddressesInternalAsync(cancellationToken);
            var address = addresses.FirstOrDefault(a => a.Id == id && a.PartnerId == partnerId);
            if (address == null)
            {
                return null;
            }

            var partnerAddresses = addresses.Where(a => a.PartnerId == partnerId).ToList();

            if (dto.IsDefault)
            {
                foreach (var existing in partnerAddresses)
                {
                    existing.IsDefault = false;
                }
                address.IsDefault = true;
            }
            else if (address.IsDefault && partnerAddresses.Count > 1)
            {
                // Si desmarca la única default, mantenerla o cambiar otra si hay más
                address.IsDefault = false;
                var fallback = partnerAddresses.FirstOrDefault(a => a.Id != id);
                if (fallback != null)
                {
                    fallback.IsDefault = true;
                }
            }

            address.Title = dto.Title.Trim();
            address.Street = dto.Street.Trim();
            address.City = dto.City.Trim();
            address.StateOrProvince = (dto.StateOrProvince ?? "").Trim();
            address.PostalCode = string.IsNullOrWhiteSpace(dto.PostalCode) ? null : dto.PostalCode.Trim();
            address.Reference = string.IsNullOrWhiteSpace(dto.Reference) ? null : dto.Reference.Trim();
            address.Phone = dto.Phone.Trim();

            await SaveAddressesInternalAsync(addresses, cancellationToken);
            return MapToDto(address);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task<bool> DeleteAsync(Guid id, int partnerId, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var addresses = await LoadAddressesInternalAsync(cancellationToken);
            var address = addresses.FirstOrDefault(a => a.Id == id && a.PartnerId == partnerId);
            if (address == null)
            {
                return false;
            }

            addresses.Remove(address);

            // Si era la predeterminada, asignar la siguiente disponible del cliente
            if (address.IsDefault)
            {
                var nextDefault = addresses.FirstOrDefault(a => a.PartnerId == partnerId);
                if (nextDefault != null)
                {
                    nextDefault.IsDefault = true;
                }
            }

            await SaveAddressesInternalAsync(addresses, cancellationToken);
            return true;
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task<AddressDto?> SetDefaultAsync(Guid id, int partnerId, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var addresses = await LoadAddressesInternalAsync(cancellationToken);
            var address = addresses.FirstOrDefault(a => a.Id == id && a.PartnerId == partnerId);
            if (address == null)
            {
                return null;
            }

            foreach (var a in addresses.Where(a => a.PartnerId == partnerId))
            {
                a.IsDefault = (a.Id == id);
            }

            await SaveAddressesInternalAsync(addresses, cancellationToken);
            return MapToDto(address);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    private static void ValidateAddress(string title, string street, string city, string phone)
    {
        if (string.IsNullOrWhiteSpace(title) || title.Trim().Length < 2)
        {
            throw new ArgumentException("El título de la dirección es obligatorio (ej. Casa, Trabajo).");
        }
        if (string.IsNullOrWhiteSpace(street) || street.Trim().Length < 5)
        {
            throw new ArgumentException("La dirección de la calle y número son obligatorios (mínimo 5 caracteres).");
        }
        if (string.IsNullOrWhiteSpace(city) || city.Trim().Length < 2)
        {
            throw new ArgumentException("La ciudad es obligatoria.");
        }
        if (string.IsNullOrWhiteSpace(phone) || phone.Trim().Length < 7)
        {
            throw new ArgumentException("El teléfono de contacto para la entrega es obligatorio (mínimo 7 caracteres).");
        }
    }

    private async Task<List<ShippingAddress>> LoadAddressesAsync(CancellationToken cancellationToken)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            return await LoadAddressesInternalAsync(cancellationToken);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    private async Task<List<ShippingAddress>> LoadAddressesInternalAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_filePath))
        {
            return new List<ShippingAddress>();
        }

        try
        {
            var json = await File.ReadAllTextAsync(_filePath, cancellationToken);
            if (string.IsNullOrWhiteSpace(json))
            {
                return new List<ShippingAddress>();
            }

            return JsonSerializer.Deserialize<List<ShippingAddress>>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            }) ?? new List<ShippingAddress>();
        }
        catch
        {
            return new List<ShippingAddress>();
        }
    }

    private async Task SaveAddressesInternalAsync(List<ShippingAddress> addresses, CancellationToken cancellationToken)
    {
        var json = JsonSerializer.Serialize(addresses, new JsonSerializerOptions
        {
            WriteIndented = true
        });
        await File.WriteAllTextAsync(_filePath, json, cancellationToken);
    }

    private static AddressDto MapToDto(ShippingAddress a) => new()
    {
        Id = a.Id,
        PartnerId = a.PartnerId,
        Title = a.Title,
        Street = a.Street,
        City = a.City,
        StateOrProvince = a.StateOrProvince,
        PostalCode = a.PostalCode,
        Reference = a.Reference,
        Phone = a.Phone,
        IsDefault = a.IsDefault,
        CreatedAt = a.CreatedAt
    };
}
