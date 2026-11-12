namespace ECommerce.Application.UseCases.Auth;

using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;

public class LoginUseCase
{
    private readonly IOdooService _odooService;

    public LoginUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<LoginResponseDto> ExecuteAsync(LoginRequestDto request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Username))
        {
            return new LoginResponseDto
            {
                IsAuthenticated = false,
                Message = "El nombre de usuario o correo es obligatorio."
            };
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return new LoginResponseDto
            {
                IsAuthenticated = false,
                Message = "La contraseña es obligatoria."
            };
        }

        return await _odooService.AuthenticateAsync(request.Username, request.Password, cancellationToken);
    }
}

