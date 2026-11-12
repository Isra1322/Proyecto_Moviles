namespace ECommerce.Infrastructure.Services;

using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;

public class CustomerCredentialRecord
{
    public int PartnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Salt { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public interface ICustomerCredentialStore
{
    Task SaveCredentialAsync(int partnerId, string name, string email, string password);
    Task<(bool IsValid, CustomerCredentialRecord? Record)> VerifyCredentialAsync(string emailOrUsername, string password);
    Task<bool> ExistsEmailAsync(string email);
}

public class CustomerCredentialStore : ICustomerCredentialStore
{
    private readonly string _filePath;
    private readonly ILogger<CustomerCredentialStore> _logger;
    private readonly SemaphoreSlim _lock = new(1, 1);
    private Dictionary<string, CustomerCredentialRecord> _cache = new(StringComparer.OrdinalIgnoreCase);

    public CustomerCredentialStore(ILogger<CustomerCredentialStore> logger)
    {
        _logger = logger;
        var appData = Path.Combine(AppContext.BaseDirectory, "App_Data");
        Directory.CreateDirectory(appData);
        _filePath = Path.Combine(appData, "customer_credentials.json");
        LoadFromFile();
    }

    private void LoadFromFile()
    {
        try
        {
            if (File.Exists(_filePath))
            {
                var json = File.ReadAllText(_filePath);
                var list = JsonSerializer.Deserialize<List<CustomerCredentialRecord>>(json);
                if (list != null)
                {
                    _cache = list.ToDictionary(x => x.Email, x => x, StringComparer.OrdinalIgnoreCase);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al cargar credenciales de clientes desde {Path}", _filePath);
        }
    }

    private async Task PersistToFileAsync()
    {
        try
        {
            var list = _cache.Values.ToList();
            var json = JsonSerializer.Serialize(list, new JsonSerializerOptions { WriteIndented = true });
            await File.WriteAllTextAsync(_filePath, json);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al guardar credenciales de clientes en {Path}", _filePath);
        }
    }

    public async Task SaveCredentialAsync(int partnerId, string name, string email, string password)
    {
        await _lock.WaitAsync();
        try
        {
            var saltBytes = RandomNumberGenerator.GetBytes(16);
            var salt = Convert.ToBase64String(saltBytes);
            var hash = HashPassword(password, salt);

            var record = new CustomerCredentialRecord
            {
                PartnerId = partnerId,
                Name = name,
                Email = email.Trim().ToLowerInvariant(),
                PasswordHash = hash,
                Salt = salt,
                CreatedAt = DateTime.UtcNow
            };

            _cache[record.Email] = record;
            await PersistToFileAsync();
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task<(bool IsValid, CustomerCredentialRecord? Record)> VerifyCredentialAsync(string emailOrUsername, string password)
    {
        await _lock.WaitAsync();
        try
        {
            var key = emailOrUsername.Trim().ToLowerInvariant();
            if (_cache.TryGetValue(key, out var record))
            {
                var hash = HashPassword(password, record.Salt);
                if (CryptographicOperations.FixedTimeEquals(
                    Encoding.UTF8.GetBytes(hash),
                    Encoding.UTF8.GetBytes(record.PasswordHash)))
                {
                    return (true, record);
                }
            }
            return (false, null);
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task<bool> ExistsEmailAsync(string email)
    {
        await _lock.WaitAsync();
        try
        {
            return _cache.ContainsKey(email.Trim().ToLowerInvariant());
        }
        finally
        {
            _lock.Release();
        }
    }

    private static string HashPassword(string password, string salt)
    {
        using var sha256 = SHA256.Create();
        var saltedPassword = $"{salt}:{password}";
        var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(saltedPassword));
        return Convert.ToBase64String(hashBytes);
    }
}
