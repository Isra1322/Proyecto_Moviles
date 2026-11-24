namespace ECommerce.Infrastructure.Services;

using System.Text.Json;
using System.Text.RegularExpressions;
using ECommerce.Application.DTOs.PaymentMethods;
using ECommerce.Application.Interfaces;
using ECommerce.Domain.Entities;

public class PaymentMethodService : IPaymentMethodService
{
    private readonly string _filePath;
    private static readonly SemaphoreSlim _semaphore = new(1, 1);

    public PaymentMethodService()
    {
        var baseDir = AppDomain.CurrentDomain.BaseDirectory;
        var dataDir = Path.Combine(baseDir, "App_Data");
        if (!Directory.Exists(dataDir))
        {
            Directory.CreateDirectory(dataDir);
        }
        _filePath = Path.Combine(dataDir, "payment_methods.json");
    }

    public async Task<List<PaymentMethodDto>> GetByPartnerIdAsync(int partnerId, CancellationToken cancellationToken = default)
    {
        var cards = await LoadCardsAsync(cancellationToken);
        return cards
            .Where(c => c.PartnerId == partnerId)
            .OrderByDescending(c => c.IsDefault)
            .ThenByDescending(c => c.CreatedAt)
            .Select(MapToDto)
            .ToList();
    }

    public async Task<PaymentMethodDto?> GetByIdAsync(Guid id, int partnerId, CancellationToken cancellationToken = default)
    {
        var cards = await LoadCardsAsync(cancellationToken);
        var card = cards.FirstOrDefault(c => c.Id == id && c.PartnerId == partnerId);
        return card != null ? MapToDto(card) : null;
    }

    public async Task<PaymentMethodDto> CreateAsync(int partnerId, CreatePaymentMethodDto dto, CancellationToken cancellationToken = default)
    {
        if (dto == null)
        {
            throw new ArgumentException("Los datos del método de pago son obligatorios.");
        }

        // 1. Validar nombre del titular
        if (string.IsNullOrWhiteSpace(dto.CardHolderName) || dto.CardHolderName.Trim().Length < 3)
        {
            throw new ArgumentException("El nombre del titular de la tarjeta es obligatorio y debe tener al menos 3 caracteres.");
        }

        // 2. Limpiar y validar número de tarjeta
        var cleanNumber = Regex.Replace(dto.CardNumber ?? "", @"[\s-]", "");
        if (!Regex.IsMatch(cleanNumber, @"^\d{13,19}$"))
        {
            throw new ArgumentException("El número de tarjeta debe contener entre 13 y 19 dígitos numéricos.");
        }

        if (!IsValidLuhn(cleanNumber))
        {
            throw new ArgumentException("El número de tarjeta no es válido según la verificación estándar de tarjetas.");
        }

        // 3. Validar expiración (MM/AA o MM/AAAA)
        var expiry = (dto.ExpiryDate ?? "").Trim();
        var expiryParts = expiry.Split('/');
        if (expiryParts.Length != 2 ||
            !int.TryParse(expiryParts[0], out var month) ||
            !int.TryParse(expiryParts[1], out var year) ||
            month < 1 || month > 12)
        {
            throw new ArgumentException("El formato de expiración debe ser MM/AA.");
        }

        var fullYear = year < 100 ? 2000 + year : year;
        var now = DateTime.UtcNow;
        var endOfMonth = new DateTime(fullYear, month, DateTime.DaysInMonth(fullYear, month), 23, 59, 59, DateTimeKind.Utc);
        if (endOfMonth < now)
        {
            throw new ArgumentException("La tarjeta de crédito/débito ingresada se encuentra expirada.");
        }

        // 4. Validar CVV (3 o 4 dígitos)
        var cleanCvv = (dto.Cvv ?? "").Trim();
        if (!Regex.IsMatch(cleanCvv, @"^\d{3,4}$"))
        {
            throw new ArgumentException("El código de seguridad (CVV) debe contener 3 o 4 dígitos numéricos.");
        }

        // 5. Detectar tipo y enmascarar
        var cardType = DetectCardType(cleanNumber);
        var last4 = cleanNumber[^4..];
        var maskedNumber = $"**** **** **** {last4}";

        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var cards = await LoadCardsInternalAsync(cancellationToken);
            var partnerCards = cards.Where(c => c.PartnerId == partnerId).ToList();

            bool isDefault = dto.IsDefault || partnerCards.Count == 0;
            if (isDefault)
            {
                foreach (var existing in partnerCards)
                {
                    existing.IsDefault = false;
                }
            }

            var newCard = new PaymentMethod
            {
                Id = Guid.NewGuid(),
                PartnerId = partnerId,
                CardHolderName = dto.CardHolderName.Trim().ToUpperInvariant(),
                MaskedCardNumber = maskedNumber,
                CardType = cardType,
                ExpiryDate = $"{month:D2}/{(fullYear % 100):D2}",
                IsDefault = isDefault,
                CreatedAt = DateTime.UtcNow
            };

            cards.Add(newCard);
            await SaveCardsInternalAsync(cards, cancellationToken);

            return MapToDto(newCard);
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
            var cards = await LoadCardsInternalAsync(cancellationToken);
            var card = cards.FirstOrDefault(c => c.Id == id && c.PartnerId == partnerId);
            if (card == null)
            {
                return false;
            }

            cards.Remove(card);

            // Si era la tarjeta por defecto, asignar otra si existe
            if (card.IsDefault)
            {
                var nextDefault = cards.FirstOrDefault(c => c.PartnerId == partnerId);
                if (nextDefault != null)
                {
                    nextDefault.IsDefault = true;
                }
            }

            await SaveCardsInternalAsync(cards, cancellationToken);
            return true;
        }
        finally
        {
            _semaphore.Release();
        }
    }

    private static bool IsValidLuhn(string number)
    {
        int sum = 0;
        bool alternate = false;
        for (int i = number.Length - 1; i >= 0; i--)
        {
            int n = number[i] - '0';
            if (alternate)
            {
                n *= 2;
                if (n > 9) n = (n % 10) + 1;
            }
            sum += n;
            alternate = !alternate;
        }
        return sum % 10 == 0;
    }

    private static string DetectCardType(string digits)
    {
        if (digits.StartsWith("4")) return "Visa";
        if (digits.StartsWith("34") || digits.StartsWith("37")) return "American Express";
        if (digits.StartsWith("6011") || digits.StartsWith("65") ||
            (digits.Length >= 3 && int.TryParse(digits[..3], out var d3) && d3 >= 644 && d3 <= 649))
        {
            return "Discover";
        }
        if (digits.Length >= 2 && int.TryParse(digits[..2], out var d2) && d2 >= 51 && d2 <= 55)
        {
            return "MasterCard";
        }
        if (digits.Length >= 4 && int.TryParse(digits[..4], out var d4) && d4 >= 2221 && d4 <= 2720)
        {
            return "MasterCard";
        }
        return "Tarjeta";
    }

    private async Task<List<PaymentMethod>> LoadCardsAsync(CancellationToken cancellationToken)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            return await LoadCardsInternalAsync(cancellationToken);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    private async Task<List<PaymentMethod>> LoadCardsInternalAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_filePath))
        {
            return new List<PaymentMethod>();
        }

        try
        {
            var json = await File.ReadAllTextAsync(_filePath, cancellationToken);
            if (string.IsNullOrWhiteSpace(json))
            {
                return new List<PaymentMethod>();
            }

            return JsonSerializer.Deserialize<List<PaymentMethod>>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            }) ?? new List<PaymentMethod>();
        }
        catch
        {
            return new List<PaymentMethod>();
        }
    }

    private async Task SaveCardsInternalAsync(List<PaymentMethod> cards, CancellationToken cancellationToken)
    {
        var json = JsonSerializer.Serialize(cards, new JsonSerializerOptions
        {
            WriteIndented = true
        });
        await File.WriteAllTextAsync(_filePath, json, cancellationToken);
    }

    private static PaymentMethodDto MapToDto(PaymentMethod c) => new()
    {
        Id = c.Id,
        PartnerId = c.PartnerId,
        CardHolderName = c.CardHolderName,
        MaskedCardNumber = c.MaskedCardNumber,
        CardType = c.CardType,
        ExpiryDate = c.ExpiryDate,
        IsDefault = c.IsDefault,
        CreatedAt = c.CreatedAt
    };
}
