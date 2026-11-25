namespace ECommerce.WebApi.Controllers;

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Payments;

[Authorize]
public class PaymentsController : BaseApiController
{
    private readonly IConfiguration _config;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(
        IConfiguration config,
        ILogger<PaymentsController> logger)
    {
        _config = config;
        _logger = logger;
        StripeConfiguration.ApiKey = _config["StripeSettings:SecretKey"];
    }

    [HttpPost("create-payment-intent")]
    [ProducesResponseType(typeof(ApiResponse<PaymentIntentResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> CreatePaymentIntent([FromBody] CreatePaymentIntentDto dto, CancellationToken cancellationToken)
    {
        if (dto == null || dto.Amount <= 0)
        {
            _logger.LogWarning("Intento de creación de PaymentIntent con monto inválido o cuerpo nulo.");
            return BadRequest(ApiResponse<object>.Fail("El monto a pagar debe ser mayor a cero."));
        }

        try
        {
            // 1. Obtener datos del cliente del DTO o del token JWT
            var email = !string.IsNullOrWhiteSpace(dto.CustomerEmail)
                ? dto.CustomerEmail.Trim()
                : User.FindFirst(ClaimTypes.Email)?.Value
                  ?? User.FindFirst("email")?.Value;

            var name = !string.IsNullOrWhiteSpace(dto.CustomerName)
                ? dto.CustomerName.Trim()
                : User.FindFirst(ClaimTypes.Name)?.Value
                  ?? User.FindFirst("name")?.Value
                  ?? email;

            // 2. Asociar o crear cliente en Stripe
            Customer? stripeCustomer = null;
            if (!string.IsNullOrWhiteSpace(email))
            {
                var customerService = new CustomerService();
                var existingCustomers = await customerService.ListAsync(new CustomerListOptions
                {
                    Email = email,
                    Limit = 1
                }, cancellationToken: cancellationToken);

                if (existingCustomers.Data.Count > 0)
                {
                    stripeCustomer = existingCustomers.Data[0];
                    _logger.LogInformation("Cliente de Stripe existente encontrado: {CustomerId} ({Email})", stripeCustomer.Id, email);
                }
                else
                {
                    stripeCustomer = await customerService.CreateAsync(new CustomerCreateOptions
                    {
                        Email = email,
                        Name = name
                    }, cancellationToken: cancellationToken);
                    _logger.LogInformation("Nuevo cliente de Stripe creado: {CustomerId} ({Email})", stripeCustomer.Id, email);
                }
            }

            // 3. Generar Ephemeral Key para el cliente
            string? ephemeralKeySecret = null;
            if (stripeCustomer != null)
            {
                var keyOptions = new EphemeralKeyCreateOptions
                {
                    Customer = stripeCustomer.Id,
                    StripeVersion = "2024-06-20"
                };
                var keyService = new EphemeralKeyService();
                var ephemeralKey = await keyService.CreateAsync(keyOptions, cancellationToken: cancellationToken);
                ephemeralKeySecret = ephemeralKey.Secret;
            }

            // 4. Configurar PaymentIntent con soporte para reutilización de tarjetas
            long amountInCents = (long)Math.Round(dto.Amount * 100, MidpointRounding.AwayFromZero);

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = string.IsNullOrWhiteSpace(dto.Currency) ? "usd" : dto.Currency.ToLowerInvariant(),
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions { Enabled = true },
                Customer = stripeCustomer?.Id,
                SetupFutureUsage = "off_session"
            };

            var service = new PaymentIntentService();
            PaymentIntent paymentIntent = await service.CreateAsync(options, cancellationToken: cancellationToken);

            var publishableKey = _config["StripeSettings:PublishableKey"]
                ?? "pk_test_51UfXT3RuFqpQHde6MCO1ajpTWvNHdtRTRMLNUPtk70AGJfX4EzuG154GVociMsBAIJpKNP7icDvqgekKmGUi6vSh00j4P3bSkC";

            var result = new PaymentIntentResultDto
            {
                ClientSecret = paymentIntent.ClientSecret,
                PaymentIntentId = paymentIntent.Id,
                CustomerId = stripeCustomer?.Id,
                EphemeralKeySecret = ephemeralKeySecret,
                PublishableKey = publishableKey
            };

            _logger.LogInformation(
                "PaymentIntent creado exitosamente: ID {PaymentIntentId}, Cliente {CustomerId}, Monto {Amount} centavos.",
                paymentIntent.Id,
                stripeCustomer?.Id ?? "N/A",
                amountInCents);

            return Ok(ApiResponse<PaymentIntentResultDto>.Ok(result, "PaymentIntent creado con éxito"));
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Error de Stripe al crear PaymentIntent: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status500InternalServerError, ApiResponse<object>.Fail($"Error de Stripe: {ex.Message}"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error inesperado al crear PaymentIntent: {Message}", ex.Message);
            return StatusCode(StatusCodes.Status500InternalServerError, ApiResponse<object>.Fail($"Error interno al procesar el pago: {ex.Message}"));
        }
    }
}
