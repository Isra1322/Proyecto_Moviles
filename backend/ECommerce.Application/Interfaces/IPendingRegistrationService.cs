namespace ECommerce.Application.Interfaces;

public class PendingUserRegistration
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public interface IPendingRegistrationService
{
    Task<string> RegisterPendingAsync(string name, string email, string password, string? phone);
    Task<PendingUserRegistration?> GetPendingAsync(string token);
    Task<bool> IsEmailPendingAsync(string email);
    Task RemovePendingAsync(string token);
}
