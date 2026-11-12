namespace ECommerce.WebApi.Controllers;

using Microsoft.AspNetCore.Mvc;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.UseCases.Auth;

public class AuthController : BaseApiController
{
    private readonly LoginUseCase _loginUseCase;
    private readonly RegisterUseCase _registerUseCase;

    public AuthController(LoginUseCase loginUseCase, RegisterUseCase registerUseCase)
    {
        _loginUseCase = loginUseCase;
        _registerUseCase = registerUseCase;
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
    [ProducesResponseType(typeof(ApiResponse<RegisterResponseDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<RegisterResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _registerUseCase.ExecuteAsync(request, cancellationToken);

        if (!result.Success)
        {
            return BadRequest(ApiResponse<RegisterResponseDto>.Fail(result.Message ?? "Registro fallido."));
        }

        return StatusCode(StatusCodes.Status201Created, ApiResponse<RegisterResponseDto>.Ok(result, "Registro exitoso en Odoo."));
    }
}
