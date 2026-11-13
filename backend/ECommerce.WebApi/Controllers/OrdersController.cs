namespace ECommerce.WebApi.Controllers;

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ECommerce.Application.Common.Exceptions;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.UseCases.Orders;

[Authorize]
public class OrdersController : BaseApiController
{
    private readonly CreateOrderUseCase _createOrderUseCase;
    private readonly GetOrdersUseCase _getOrdersUseCase;
    private readonly GetOrderByIdUseCase? _getOrderByIdUseCase;
    private readonly ILogger<OrdersController> _logger;

    [ActivatorUtilitiesConstructor]
    public OrdersController(
        CreateOrderUseCase createOrderUseCase,
        GetOrdersUseCase getOrdersUseCase,
        GetOrderByIdUseCase getOrderByIdUseCase,
        ILogger<OrdersController> logger)
    {
        _createOrderUseCase = createOrderUseCase;
        _getOrdersUseCase = getOrdersUseCase;
        _getOrderByIdUseCase = getOrderByIdUseCase;
        _logger = logger;
    }

    public OrdersController(
        CreateOrderUseCase createOrderUseCase,
        GetOrdersUseCase getOrdersUseCase,
        ILogger<OrdersController> logger)
        : this(createOrderUseCase, getOrdersUseCase, null!, logger)
    {
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

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status408RequestTimeout)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status502BadGateway)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Create([FromBody] CreateOrderDto? orderDto, CancellationToken cancellationToken)
    {
        if (orderDto == null)
        {
            _logger.LogWarning("Intento de creación de orden con cuerpo de solicitud vacío.");
            return BadRequest(ApiResponse<object>.Fail("El cuerpo de la solicitud no puede estar vacío."));
        }

        try
        {
            // AISLAMIENTO ESTRICTO: Se fuerza el CustomerId al del usuario autenticado en el token JWT
            var authenticatedPartnerId = GetAuthenticatedPartnerId();
            orderDto.CustomerId = authenticatedPartnerId;

            _logger.LogInformation("Iniciando creación de pedido para cliente ID {CustomerId} con {ItemCount} ítems.", authenticatedPartnerId, orderDto.Items?.Count ?? 0);

            var createdOrder = await _createOrderUseCase.ExecuteAsync(orderDto, cancellationToken);

            _logger.LogInformation("Pedido ID {OrderId} creado y confirmado exitosamente para cliente {CustomerId}.", createdOrder.Id, authenticatedPartnerId);

            return StatusCode(StatusCodes.Status201Created, ApiResponse<OrderDto>.Ok(createdOrder, "Orden creada y confirmada con éxito en Odoo."));
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Acceso no autorizado al crear pedido: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status401Unauthorized, ApiResponse<object>.Fail(ex.Message));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Solicitud inválida al crear pedido: {Message}", ex.Message);
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
        catch (NotFoundException ex)
        {
            _logger.LogWarning(ex, "Recurso no encontrado al crear pedido: {Message}", ex.Message);
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
        catch (OdooIntegrationException ex)
        {
            _logger.LogError(ex, "Error de integración con Odoo al procesar el pedido: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status502BadGateway, ApiResponse<object>.Fail($"Error en el servidor de Odoo: {ex.Message}"));
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogWarning(ex, "La solicitud de creación de pedido fue cancelada o superó el tiempo límite.");
            return StatusCode(StatusCodes.Status408RequestTimeout, ApiResponse<object>.Fail("La solicitud tardó demasiado tiempo y se canceló la conexión."));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error no controlado al crear el pedido: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status500InternalServerError, ApiResponse<object>.Fail($"Error interno al procesar el pedido: {ex.Message}"));
        }
    }

    [HttpGet]
    [HttpGet("my-orders")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<OrderDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status408RequestTimeout)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status502BadGateway)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetMyOrders([FromQuery] int? customerId, CancellationToken cancellationToken)
    {
        try
        {
            // ANTI-IDOR: El identificador se extrae exclusivamente del JWT autenticado, impidiendo fuga de pedidos
            var authenticatedPartnerId = GetAuthenticatedPartnerId();

            var orders = await _getOrdersUseCase.ExecuteAsync(authenticatedPartnerId, cancellationToken);
            return Ok(ApiResponse<IReadOnlyList<OrderDto>>.Ok(orders));
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Acceso no autorizado al consultar pedidos: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status401Unauthorized, ApiResponse<object>.Fail(ex.Message));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Solicitud inválida al consultar pedidos: {Message}", ex.Message);
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
        catch (TimeoutException ex)
        {
            _logger.LogWarning(ex, "La consulta de pedidos en Odoo excedió el tiempo límite de espera.");
            return StatusCode(StatusCodes.Status408RequestTimeout, ApiResponse<object>.Fail("La consulta de pedidos tardó demasiado tiempo y se canceló la conexión."));
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogWarning(ex, "La consulta de pedidos fue cancelada o superó el tiempo límite.");
            return StatusCode(StatusCodes.Status408RequestTimeout, ApiResponse<object>.Fail("La consulta de pedidos tardó demasiado tiempo y se canceló la conexión."));
        }
        catch (OdooIntegrationException ex)
        {
            _logger.LogError(ex, "Error de integración con Odoo al consultar pedidos: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status502BadGateway, ApiResponse<object>.Fail($"Error en el servidor de Odoo: {ex.Message}"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error no controlado al consultar pedidos: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status500InternalServerError, ApiResponse<object>.Fail($"Error interno al consultar pedidos: {ex.Message}"));
        }
    }

    [NonAction]
    public Task<IActionResult> GetByCustomer([FromQuery] int? customerId, CancellationToken cancellationToken)
        => GetMyOrders(customerId, cancellationToken);

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status408RequestTimeout)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status502BadGateway)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(ApiResponse<object>.Fail("El identificador del pedido debe ser mayor a cero."));
        }

        try
        {
            var authenticatedPartnerId = GetAuthenticatedPartnerId();

            if (_getOrderByIdUseCase == null)
            {
                throw new InvalidOperationException("El servicio de consulta de pedidos por ID no está configurado.");
            }

            var order = await _getOrderByIdUseCase.ExecuteAsync(id, cancellationToken);

            if (order == null)
            {
                return NotFound(ApiResponse<object>.Fail($"No se encontró el pedido con ID {id}."));
            }

            if (order.CustomerId > 0 && order.CustomerId != authenticatedPartnerId)
            {
                _logger.LogWarning("Intento de acceso no autorizado al pedido ID {OrderId} por el cliente ID {CustomerId}.", id, authenticatedPartnerId);
                return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<object>.Fail("No tienes permiso para consultar este pedido."));
            }

            return Ok(ApiResponse<OrderDto>.Ok(order));
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Acceso no autorizado al consultar pedido: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status401Unauthorized, ApiResponse<object>.Fail(ex.Message));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Solicitud inválida al consultar pedido: {Message}", ex.Message);
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
        catch (NotFoundException ex)
        {
            _logger.LogWarning(ex, "Pedido no encontrado: {Message}", ex.Message);
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
        catch (TimeoutException ex)
        {
            _logger.LogWarning(ex, "La consulta del pedido en Odoo excedió el tiempo límite.");
            return StatusCode(StatusCodes.Status408RequestTimeout, ApiResponse<object>.Fail("La consulta del pedido tardó demasiado tiempo y se canceló la conexión."));
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogWarning(ex, "La consulta del pedido fue cancelada o superó el tiempo límite.");
            return StatusCode(StatusCodes.Status408RequestTimeout, ApiResponse<object>.Fail("La consulta del pedido tardó demasiado tiempo y se canceló la conexión."));
        }
        catch (OdooIntegrationException ex)
        {
            _logger.LogError(ex, "Error de integración con Odoo al consultar pedido: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status502BadGateway, ApiResponse<object>.Fail($"Error en el servidor de Odoo: {ex.Message}"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error no controlado al consultar pedido: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status500InternalServerError, ApiResponse<object>.Fail($"Error interno al consultar pedido: {ex.Message}"));
        }
    }
}
