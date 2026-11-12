namespace ECommerce.Infrastructure.Services;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using ECommerce.Application.Interfaces;

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateToken(int partnerId, string email, string name)
    {
        var secretKey = _configuration["Jwt:Key"] ?? "ClaveSecretaSuperSeguraParaECommerceProyectoFinal2026_Minimo32Caracteres!";
        var issuer = _configuration["Jwt:Issuer"] ?? "ECommerce.WebApi";
        var audience = _configuration["Jwt:Audience"] ?? "ECommerce.MobileApp";
        var expireDays = int.TryParse(_configuration["Jwt:ExpireDays"], out var days) ? days : 7;

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, partnerId.ToString()),
            new(ClaimTypes.Email, email),
            new(ClaimTypes.Name, name),
            new("partner_id", partnerId.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddDays(expireDays),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = credentials
        };

        var handler = new JwtSecurityTokenHandler();
        var token = handler.CreateToken(tokenDescriptor);
        return handler.WriteToken(token);
    }
}
