namespace ECommerce.Application.Interfaces;

public interface IJwtTokenService
{
    string GenerateToken(int partnerId, string email, string name);
}
