namespace ECommerce.Infrastructure.Services;

using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using ECommerce.Application.Interfaces;

public class PendingRegistrationService : IPendingRegistrationService
{
    private readonly IMemoryCache _memoryCache;
    private readonly ILogger<PendingRegistrationService> _logger;
    private readonly string _filePath;
    private readonly SemaphoreSlim _lock = new(1, 1);
    private static readonly TimeSpan ExpirationTime = TimeSpan.FromHours(24);
    private const string CacheKeyPrefix = "verify_token_";

    public PendingRegistrationService(
        IMemoryCache memoryCache,
        ILogger<PendingRegistrationService> logger)
    {
        _memoryCache = memoryCache;
        _logger = logger;
        var appData = Path.Combine(AppContext.BaseDirectory, "App_Data");
        Directory.CreateDirectory(appData);
        _filePath = Path.Combine(appData, "pending_users.json");
        LoadFromFile();
    }

    private void LoadFromFile()
    {
        try
        {
            if (File.Exists(_filePath))
            {
                var json = File.ReadAllText(_filePath);
                var dict = JsonSerializer.Deserialize<Dictionary<string, PendingUserRegistration>>(json);
                if (dict != null)
                {
                    var now = DateTime.UtcNow;
                    foreach (var kvp in dict)
                    {
                        if (now - kvp.Value.CreatedAt < ExpirationTime)
                        {
                            var remainingTime = ExpirationTime - (now - kvp.Value.CreatedAt);
                            _memoryCache.Set(CacheKeyPrefix + kvp.Key, kvp.Value, remainingTime);
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al cargar pre-registros pendientes desde {Path}", _filePath);
        }
    }

    private async Task PersistToFileAsync()
    {
        try
        {
            // Read all valid from file or write current active
            var dict = new Dictionary<string, PendingUserRegistration>();
            if (File.Exists(_filePath))
            {
                var existingJson = await File.ReadAllTextAsync(_filePath);
                var existingDict = JsonSerializer.Deserialize<Dictionary<string, PendingUserRegistration>>(existingJson);
                if (existingDict != null)
                {
                    var now = DateTime.UtcNow;
                    foreach (var kvp in existingDict)
                    {
                        if (now - kvp.Value.CreatedAt < ExpirationTime)
                        {
                            dict[kvp.Key] = kvp.Value;
                        }
                    }
                }
            }

            var json = JsonSerializer.Serialize(dict, new JsonSerializerOptions { WriteIndented = true });
            await File.WriteAllTextAsync(_filePath, json);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al persistir pre-registros pendientes en {Path}", _filePath);
        }
    }

    public async Task<string> RegisterPendingAsync(string name, string email, string password, string? phone)
    {
        await _lock.WaitAsync();
        try
        {
            var token = Guid.NewGuid().ToString("N");
            var pending = new PendingUserRegistration
            {
                Name = name.Trim(),
                Email = email.Trim().ToLowerInvariant(),
                Password = password,
                Phone = phone?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _memoryCache.Set(CacheKeyPrefix + token, pending, ExpirationTime);

            // Persist to file
            Dictionary<string, PendingUserRegistration> dict = new();
            if (File.Exists(_filePath))
            {
                try
                {
                    var existingJson = await File.ReadAllTextAsync(_filePath);
                    var parsed = JsonSerializer.Deserialize<Dictionary<string, PendingUserRegistration>>(existingJson);
                    if (parsed != null) dict = parsed;
                }
                catch { }
            }

            // Remove any older registration for same email if needed
            var keysToRemove = dict.Where(k => string.Equals(k.Value.Email, pending.Email, StringComparison.OrdinalIgnoreCase)).Select(k => k.Key).ToList();
            foreach (var k in keysToRemove)
            {
                dict.Remove(k);
                _memoryCache.Remove(CacheKeyPrefix + k);
            }

            dict[token] = pending;
            var json = JsonSerializer.Serialize(dict, new JsonSerializerOptions { WriteIndented = true });
            await File.WriteAllTextAsync(_filePath, json);

            return token;
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task<PendingUserRegistration?> GetPendingAsync(string token)
    {
        if (string.IsNullOrWhiteSpace(token)) return null;

        if (_memoryCache.TryGetValue(CacheKeyPrefix + token, out PendingUserRegistration? cached) && cached != null)
        {
            if (DateTime.UtcNow - cached.CreatedAt < ExpirationTime)
            {
                return cached;
            }
            await RemovePendingAsync(token);
            return null;
        }

        // Try load from file
        await _lock.WaitAsync();
        try
        {
            if (File.Exists(_filePath))
            {
                var json = await File.ReadAllTextAsync(_filePath);
                var dict = JsonSerializer.Deserialize<Dictionary<string, PendingUserRegistration>>(json);
                if (dict != null && dict.TryGetValue(token, out var item))
                {
                    if (DateTime.UtcNow - item.CreatedAt < ExpirationTime)
                    {
                        _memoryCache.Set(CacheKeyPrefix + token, item, ExpirationTime - (DateTime.UtcNow - item.CreatedAt));
                        return item;
                    }
                    dict.Remove(token);
                    await File.WriteAllTextAsync(_filePath, JsonSerializer.Serialize(dict, new JsonSerializerOptions { WriteIndented = true }));
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error buscando token pendiente {Token}", token);
        }
        finally
        {
            _lock.Release();
        }

        return null;
    }

    public async Task<bool> IsEmailPendingAsync(string email)
    {
        if (string.IsNullOrWhiteSpace(email)) return false;
        var cleanEmail = email.Trim().ToLowerInvariant();

        await _lock.WaitAsync();
        try
        {
            if (File.Exists(_filePath))
            {
                var json = await File.ReadAllTextAsync(_filePath);
                var dict = JsonSerializer.Deserialize<Dictionary<string, PendingUserRegistration>>(json);
                if (dict != null)
                {
                    var now = DateTime.UtcNow;
                    return dict.Values.Any(v =>
                        string.Equals(v.Email, cleanEmail, StringComparison.OrdinalIgnoreCase) &&
                        (now - v.CreatedAt < ExpirationTime));
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verificando si email está pendiente {Email}", email);
        }
        finally
        {
            _lock.Release();
        }

        return false;
    }

    public async Task RemovePendingAsync(string token)
    {
        if (string.IsNullOrWhiteSpace(token)) return;

        _memoryCache.Remove(CacheKeyPrefix + token);

        await _lock.WaitAsync();
        try
        {
            if (File.Exists(_filePath))
            {
                var json = await File.ReadAllTextAsync(_filePath);
                var dict = JsonSerializer.Deserialize<Dictionary<string, PendingUserRegistration>>(json);
                if (dict != null && dict.Remove(token))
                {
                    await File.WriteAllTextAsync(_filePath, JsonSerializer.Serialize(dict, new JsonSerializerOptions { WriteIndented = true }));
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error eliminando token pendiente {Token}", token);
        }
        finally
        {
            _lock.Release();
        }
    }
}
