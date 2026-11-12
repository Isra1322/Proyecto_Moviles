namespace ECommerce.Application.DTOs.Auth;

public class RegisterResponseDto
{
    public bool Success { get; set; }
    public int PartnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AccessToken { get; set; }
    public string? Message { get; set; }
}
