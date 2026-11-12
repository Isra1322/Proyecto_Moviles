namespace ECommerce.WebApi.Middlewares;

using System.Net;
using System.Text.Json;
using ECommerce.Application.Common.Exceptions;
using ECommerce.Application.Common.Models;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate _next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        this._next = _next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var statusCode = HttpStatusCode.InternalServerError;
        var message = "Ocurrió un error interno en el servidor.";

        switch (exception)
        {
            case NotFoundException notFoundEx:
                statusCode = HttpStatusCode.NotFound;
                message = notFoundEx.Message;
                _logger.LogWarning(notFoundEx, "Recurso no encontrado.");
                break;

            case UnauthorizedAccessException authEx:
                statusCode = HttpStatusCode.Unauthorized;
                message = authEx.Message;
                _logger.LogWarning(authEx, "Acceso no autorizado.");
                break;

            case ArgumentException argEx:
                statusCode = HttpStatusCode.BadRequest;
                message = argEx.Message;
                _logger.LogWarning(argEx, "Solicitud inválida.");
                break;

            case OperationCanceledException cancelEx:
                statusCode = HttpStatusCode.RequestTimeout;
                message = "La operación fue cancelada o superó el tiempo límite de espera.";
                _logger.LogWarning(cancelEx, "Tiempo de espera agotado.");
                break;

            case OdooIntegrationException odooEx:
                statusCode = HttpStatusCode.BadGateway;
                message = odooEx.Message;
                _logger.LogError(odooEx, "Fallo en la comunicación con Odoo Community.");
                break;

            default:
                _logger.LogError(exception, "Excepción no controlada.");
                break;
        }

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var response = ApiResponse<object>.Fail(message);
        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await context.Response.WriteAsync(json);
    }
}

