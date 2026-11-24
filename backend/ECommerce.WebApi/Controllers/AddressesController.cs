namespace ECommerce.WebApi.Controllers;

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Addresses;
using ECommerce.Application.Interfaces;

[Authorize]
public class AddressesController : BaseApiController
{
    private readonly IAddressService _addressService;
    private readonly ILogger<AddressesController> _logger;

    public AddressesController(
        IAddressService addressService,
        ILogger<AddressesController> logger)
    {
        _addressService = addressService;
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
    [ProducesResponseType(typeof(ApiResponse<List<AddressDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var partnerId = GetAuthenticatedPartnerId();
        var addresses = await _addressService.GetByPartnerIdAsync(partnerId, cancellationToken);
        return Ok(ApiResponse<List<AddressDto>>.Ok(addresses, "Direcciones de entrega obtenidas con éxito."));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AddressDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var partnerId = GetAuthenticatedPartnerId();
        var address = await _addressService.GetByIdAsync(id, partnerId, cancellationToken);
        if (address == null)
        {
            return NotFound(ApiResponse<object>.Fail("La dirección de entrega no existe o no pertenece a este usuario."));
        }

        return Ok(ApiResponse<AddressDto>.Ok(address));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<AddressDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Create([FromBody] CreateAddressDto? dto, CancellationToken cancellationToken)
    {
        if (dto == null)
        {
            return BadRequest(ApiResponse<object>.Fail("Los datos de la dirección son obligatorios."));
        }

        if (!ModelState.IsValid)
        {
            var errors = string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return BadRequest(ApiResponse<object>.Fail(errors));
        }

        try
        {
            var partnerId = GetAuthenticatedPartnerId();
            var created = await _addressService.CreateAsync(partnerId, dto, cancellationToken);
            _logger.LogInformation("Dirección {AddressId} registrada exitosamente para cliente {PartnerId}", created.Id, partnerId);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<AddressDto>.Ok(created, "Dirección de entrega registrada exitosamente."));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Validación fallida al registrar dirección: {Message}", ex.Message);
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<AddressDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateAddressDto? dto, CancellationToken cancellationToken)
    {
        if (dto == null)
        {
            return BadRequest(ApiResponse<object>.Fail("Los datos de la dirección son obligatorios."));
        }

        if (!ModelState.IsValid)
        {
            var errors = string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
            return BadRequest(ApiResponse<object>.Fail(errors));
        }

        try
        {
            var partnerId = GetAuthenticatedPartnerId();
            var updated = await _addressService.UpdateAsync(id, partnerId, dto, cancellationToken);
            if (updated == null)
            {
                return NotFound(ApiResponse<object>.Fail("La dirección no fue encontrada o no pertenece a este usuario."));
            }

            _logger.LogInformation("Dirección {AddressId} actualizada para cliente {PartnerId}", id, partnerId);
            return Ok(ApiResponse<AddressDto>.Ok(updated, "Dirección de entrega actualizada exitosamente."));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Validación fallida al actualizar dirección: {Message}", ex.Message);
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
        var deleted = await _addressService.DeleteAsync(id, partnerId, cancellationToken);
        if (!deleted)
        {
            return NotFound(ApiResponse<object>.Fail("La dirección no fue encontrada o no pertenece a este usuario."));
        }

        _logger.LogInformation("Dirección {AddressId} eliminada para cliente {PartnerId}", id, partnerId);
        return Ok(ApiResponse<bool>.Ok(true, "Dirección de entrega eliminada exitosamente."));
    }

    [HttpPut("{id:guid}/set-default")]
    [ProducesResponseType(typeof(ApiResponse<AddressDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SetDefault(Guid id, CancellationToken cancellationToken)
    {
        var partnerId = GetAuthenticatedPartnerId();
        var updated = await _addressService.SetDefaultAsync(id, partnerId, cancellationToken);
        if (updated == null)
        {
            return NotFound(ApiResponse<object>.Fail("La dirección no fue encontrada o no pertenece a este usuario."));
        }

        _logger.LogInformation("Dirección {AddressId} establecida como predeterminada para cliente {PartnerId}", id, partnerId);
        return Ok(ApiResponse<AddressDto>.Ok(updated, "Dirección establecida como predeterminada."));
    }
}
