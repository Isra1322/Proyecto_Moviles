namespace ECommerce.Application.UseCases.Auth;

using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;

public class LoginUseCase
{
    private readonly IOdooService _odooService;
    private readonly IPendingRegistrationService _pendingRegistrationService;

    public LoginUseCase(IOdooService odooService, IPendingRegistrationService pendingRegistrationService)
    {
        _odooService = odooService;
        _pendingRegistrationService = pendingRegistrationService;
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

        // Si un usuario registrado pendiente o con correo no confirmado intenta hacer login:
        if (await _pendingRegistrationService.IsEmailPendingAsync(request.Username))
        {
            return new LoginResponseDto
            {
                IsAuthenticated = false,
                Message = "Debes verificar tu correo antes de iniciar sesión"
            };
        }

        return await _odooService.AuthenticateAsync(request.Username, request.Password, cancellationToken);
    }
}
