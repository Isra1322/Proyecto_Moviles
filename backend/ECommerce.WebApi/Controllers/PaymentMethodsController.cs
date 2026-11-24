namespace ECommerce.WebApi.Controllers;

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.PaymentMethods;
using ECommerce.Application.Interfaces;

[Authorize]
public class PaymentMethodsController : BaseApiController
{
    private readonly IPaymentMethodService _paymentMethodService;
    private readonly ILogger<PaymentMethodsController> _logger;

    public PaymentMethodsController(
        IPaymentMethodService paymentMethodService,
        ILogger<PaymentMethodsController> logger)
    {
        _paymentMethodService = paymentMethodService;
        _logger = logger;
    }

    private int GetAuthenticatedPartnerId()
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("partner_id")?.Value;

        if (int.TryParse(claimValue, out var partnerId) && partnerId > 0)
        {
            return partnerId;
        }

        throw new UnauthorizedAccessException("El token no contiene un identificador de cliente válido.");
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<PaymentMethodDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var partnerId = GetAuthenticatedPartnerId();
        var cards = await _paymentMethodService.GetByPartnerIdAsync(partnerId, cancellationToken);
        return Ok(ApiResponse<List<PaymentMethodDto>>.Ok(cards, "Métodos de pago obtenidos con éxito."));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<PaymentMethodDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Create([FromBody] CreatePaymentMethodDto? dto, CancellationToken cancellationToken)
    {
        if (dto == null)
        {
            return BadRequest(ApiResponse<object>.Fail("Los datos de la tarjeta son obligatorios."));
        }

        try
        {
            var partnerId = GetAuthenticatedPartnerId();
            var created = await _paymentMethodService.CreateAsync(partnerId, dto, cancellationToken);
            _logger.LogInformation("Método de pago {CardId} registrado para cliente {PartnerId}", created.Id, partnerId);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<PaymentMethodDto>.Ok(created, "Método de pago registrado exitosamente."));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Validación fallida al registrar método de pago: {Message}", ex.Message);
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var partnerId = GetAuthenticatedPartnerId();
        var deleted = await _paymentMethodService.DeleteAsync(id, partnerId, cancellationToken);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.Fail("El método de pago no fue encontrado o no pertenece a este usuario."));
        }

        _logger.LogInformation("Método de pago {CardId} eliminado para cliente {PartnerId}", id, partnerId);
        return Ok(ApiResponse<bool>.Ok(true, "Método de pago eliminado exitosamente."));
    }
}
