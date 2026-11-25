namespace ECommerce.Application.UseCases.Auth;

using System.Text.RegularExpressions;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;

public class RegisterUseCase
{
    private readonly IOdooService _odooService;
    private readonly IPendingRegistrationService _pendingRegistrationService;
    private readonly IEmailService _emailService;

    public RegisterUseCase(
        IOdooService odooService,
        IPendingRegistrationService pendingRegistrationService,
        IEmailService emailService)
    {
        _odooService = odooService;
        _pendingRegistrationService = pendingRegistrationService;
        _emailService = emailService;
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

        // Valida si el correo ya existe en Odoo (res.partner) o credenciales
        var exists = await _odooService.CheckEmailExistsAsync(request.Email, cancellationToken);
        if (exists)
        {
            return new RegisterResponseDto
            {
                Success = false,
                Message = "El correo ya se encuentra registrado."
            };
        }

        // REGLA DE NEGOCIO OBLIGATORIA: NO crees el usuario ni el res.partner en Odoo en este momento.
        // Genera el token de verificación y guarda los datos en el almacén temporal.
        var token = await _pendingRegistrationService.RegisterPendingAsync(
            request.Name,
            request.Email,
            request.Password,
            request.Phone
        );

        // Llama a IEmailService (SmtpEmailService con Brevo) para disparar el correo de confirmación
        try
        {
            await _emailService.SendVerificationEmailAsync(
                request.Email,
                request.Name,
                token,
                cancellationToken
            );
        }
        catch
        {
            await _pendingRegistrationService.RemovePendingAsync(token);
            throw;
        }

        return new RegisterResponseDto
        {
            Success = true,
            Email = request.Email.Trim().ToLowerInvariant(),
            Name = request.Name.Trim(),
            RequiresVerification = true,
            Message = "Te hemos enviado un correo de confirmación. Por favor, revisa tu bandeja de entrada o carpeta de spam para activar tu cuenta."
        };
    }
}
