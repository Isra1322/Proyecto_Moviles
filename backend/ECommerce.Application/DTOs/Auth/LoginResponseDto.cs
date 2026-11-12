namespace ECommerce.Application.DTOs.Auth;

public class LoginResponseDto
{
    //Token de sesion
    //Esto no va en Domain por que es un dto del application 
    //y el domain solo debe tener las entidades y las reglas de negocio
    public string? SessionId { get; set; }
    public string? AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public bool IsAuthenticated { get; set; }
    public int Uid { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public int? PartnerId { get; set; }
    public string? Message { get; set; }
}

