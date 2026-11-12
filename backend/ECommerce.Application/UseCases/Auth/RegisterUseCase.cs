namespace ECommerce.Application.UseCases.Auth;

using System.Text.RegularExpressions;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;

public class RegisterUseCase
{
    private readonly IOdooService _odooService;

    public RegisterUseCase(IOdooService odooService)
    {
        _odooService = odooService;
    }

    public async Task<RegisterResponseDto> ExecuteAsync(RegisterRequestDto request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return new RegisterResponseDto
            {
                Success = false,
                Message = "El nombre completo es obligatorio."
            };
        }

        if (string.IsNullOrWhiteSpace(request.Email) || !Regex.IsMatch(request.Email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
        {
            return new RegisterResponseDto
            {
                Success = false,
                Message = "El formato del correo electrónico es inválido."
            };
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
        {
            return new RegisterResponseDto
            {
                Success = false,
                Message = "La contraseña debe tener al menos 6 caracteres."
            };
        }

        return await _odooService.RegisterCustomerAsync(request, cancellationToken);
    }
}
