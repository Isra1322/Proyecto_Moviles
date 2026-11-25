namespace ECommerce.WebApi.Controllers;

using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Application.UseCases.Auth;

public class AuthController : BaseApiController
{
    private readonly LoginUseCase _loginUseCase;
    private readonly RegisterUseCase _registerUseCase;
    private readonly IOdooService _odooService;
    private readonly IPendingRegistrationService _pendingRegistrationService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        LoginUseCase loginUseCase,
        RegisterUseCase registerUseCase,
        IOdooService odooService,
        IPendingRegistrationService pendingRegistrationService,
        ILogger<AuthController> logger)
    {
        _loginUseCase = loginUseCase;
        _registerUseCase = registerUseCase;
        _odooService = odooService;
        _pendingRegistrationService = pendingRegistrationService;
        _logger = logger;
    }

    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _loginUseCase.ExecuteAsync(request, cancellationToken);

        if (!result.IsAuthenticated)
        {
            return Unauthorized(ApiResponse<LoginResponseDto>.Fail(result.Message ?? "Autenticación fallida."));
        }

        return Ok(ApiResponse<LoginResponseDto>.Ok(result, "Inicio de sesión exitoso."));
    }

    [HttpPost("register")]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _registerUseCase.ExecuteAsync(request, cancellationToken);

        if (!result.Success)
        {
            return BadRequest(ApiResponse<RegisterResponseDto>.Fail(result.Message ?? "Registro fallido."));
        }

        return Ok(ApiResponse<RegisterResponseDto>.Ok(result, result.Message));
    }

    [HttpGet("verify-email")]
    [AllowAnonymous]
    [Produces("text/html")]
    public async Task<IActionResult> VerifyEmail([FromQuery] string? token, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return Content(GetErrorHtml("El enlace de confirmación es inválido o ha expirado. Por favor, regístrate nuevamente desde la app."), "text/html", Encoding.UTF8);
        }

        var pending = await _pendingRegistrationService.GetPendingAsync(token);
        if (pending == null)
        {
            return Content(GetErrorHtml("El enlace de confirmación es inválido o ha expirado. Por favor, regístrate nuevamente desde la app."), "text/html", Encoding.UTF8);
        }

        try
        {
            var registerRequest = new RegisterRequestDto
            {
                Name = pending.Name,
                Email = pending.Email,
                Password = pending.Password,
                Phone = pending.Phone
            };

            var result = await _odooService.RegisterCustomerAsync(registerRequest, cancellationToken);
            if (!result.Success)
            {
                await _pendingRegistrationService.RemovePendingAsync(token);

                if (result.Message?.Contains("ya se encuentra registrado", StringComparison.OrdinalIgnoreCase) == true ||
                    result.Message?.Contains("Contacto existente", StringComparison.OrdinalIgnoreCase) == true)
                {
                    return Content(GetSuccessHtml(), "text/html", Encoding.UTF8);
                }

                return Content(GetErrorHtml(result.Message ?? "Error al activar la cuenta en Odoo."), "text/html", Encoding.UTF8);
            }

            await _pendingRegistrationService.RemovePendingAsync(token);
            return Content(GetSuccessHtml(), "text/html", Encoding.UTF8);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al procesar activación de correo para token {Token}", token);
            return Content(GetErrorHtml("Ocurrió un error al activar tu cuenta. Por favor, intenta nuevamente más tarde."), "text/html", Encoding.UTF8);
        }
    }

    private static string GetSuccessHtml()
    {
        return @"<!DOCTYPE html>
<html lang=""es"">
<head>
  <meta charset=""utf-8"">
  <meta name=""viewport"" content=""width=device-width, initial-scale=1"">
  <title>Cuenta Activada - E-Commerce Móvil</title>
  <style>
    :root {
      --bg: #121212;
      --card-bg: #1e1e1e;
      --text: #ffffff;
      --subtext: #a0a0a0;
      --accent: #2196f3;
      --success: #4caf50;
      --border: #2c2c2c;
    }
    @media (prefers-color-scheme: light) {
      :root {
        --bg: #f4f6f8;
        --card-bg: #ffffff;
        --text: #1a1a1a;
        --subtext: #666666;
        --border: #e0e0e0;
      }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, Helvetica, Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 20px;
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 40px 30px;
      text-align: center;
      max-width: 420px;
      width: 100%;
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    }
    .icon-container {
      width: 80px;
      height: 80px;
      background-color: rgba(76, 175, 80, 0.15);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px auto;
    }
    .icon {
      font-size: 40px;
      color: var(--success);
      line-height: 1;
    }
    h2 {
      font-size: 24px;
      font-weight: 700;
      margin-bottom: 12px;
      color: var(--text);
    }
    p {
      color: var(--subtext);
      font-size: 15px;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-block;
      background-color: rgba(33, 150, 243, 0.15);
      color: var(--accent);
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }
  </style>
</head>
<body>
  <div class=""card"">
    <div class=""icon-container"">
      <div class=""icon"">✓</div>
    </div>
    <span class=""badge"">E-Commerce Móvil</span>
    <h2>¡Cuenta Activada!</h2>
    <p>Tu correo ha sido verificado con éxito y tu cuenta fue creada en el sistema. Ya puedes volver a la aplicación móvil e iniciar sesión.</p>
  </div>
</body>
</html>";
    }

    private static string GetErrorHtml(string message)
    {
        var template = @"<!DOCTYPE html>
<html lang=""es"">
<head>
  <meta charset=""utf-8"">
  <meta name=""viewport"" content=""width=device-width, initial-scale=1"">
  <title>Error de Activación - E-Commerce Móvil</title>
  <style>
    :root {
      --bg: #121212;
      --card-bg: #1e1e1e;
      --text: #ffffff;
      --subtext: #a0a0a0;
      --accent: #2196f3;
      --error: #f44336;
      --border: #2c2c2c;
    }
    @media (prefers-color-scheme: light) {
      :root {
        --bg: #f4f6f8;
        --card-bg: #ffffff;
        --text: #1a1a1a;
        --subtext: #666666;
        --border: #e0e0e0;
      }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, Helvetica, Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 20px;
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 40px 30px;
      text-align: center;
      max-width: 420px;
      width: 100%;
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    }
    .icon-container {
      width: 80px;
      height: 80px;
      background-color: rgba(244, 67, 54, 0.15);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px auto;
    }
    .icon {
      font-size: 40px;
      color: var(--error);
      line-height: 1;
    }
    h2 {
      font-size: 24px;
      font-weight: 700;
      margin-bottom: 12px;
      color: var(--text);
    }
    p {
      color: var(--subtext);
      font-size: 15px;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-block;
      background-color: rgba(244, 67, 54, 0.15);
      color: var(--error);
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }
  </style>
</head>
<body>
  <div class=""card"">
    <div class=""icon-container"">
      <div class=""icon"">✕</div>
    </div>
    <span class=""badge"">E-Commerce Móvil</span>
    <h2>Enlace Inválido</h2>
    <p>{{MESSAGE}}</p>
  </div>
</body>
</html>";
        var safeMessage = message.Replace("<", "&lt;").Replace(">", "&gt;");
        return template.Replace("{{MESSAGE}}", safeMessage);
    }
}
