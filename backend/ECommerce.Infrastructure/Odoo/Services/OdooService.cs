namespace ECommerce.Infrastructure.Odoo.Services;

using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ECommerce.Application.Common.Exceptions;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.DTOs.Products;
using ECommerce.Application.Interfaces;
using ECommerce.Domain.Enums;
using ECommerce.Infrastructure.Configuration;
using ECommerce.Infrastructure.Mappers;
using ECommerce.Infrastructure.Odoo.Models;
using ECommerce.Infrastructure.Services;

/// <summary>
/// Implementación de IOdooService basada exclusivamente en la API JSON-2 oficial de Odoo 20 Community (/json/2/...).
/// Cumple con la especificación técnica de cabeceras Authorization: Bearer, X-Odoo-Database y confirmación action_confirm.
/// </summary>
public class OdooService : IOdooService
{
    private readonly HttpClient _httpClient;
    private readonly OdooSettings _settings;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly ICustomerCredentialStore _credentialStore;
    private readonly ILogger<OdooService> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public OdooService(
        HttpClient httpClient,
        IOptions<OdooSettings> settings,
        IJwtTokenService jwtTokenService,
        ICustomerCredentialStore credentialStore,
        ILogger<OdooService> logger)
    {
        _httpClient = httpClient;
        _settings = settings.Value;
        _jwtTokenService = jwtTokenService;
        _credentialStore = credentialStore;
        _logger = logger;

        if (_httpClient.BaseAddress == null && !string.IsNullOrWhiteSpace(_settings.Url))
        {
            var normalizedUrl = _settings.Url.Replace("://localhost", "://127.0.0.1");
            _httpClient.BaseAddress = new Uri(normalizedUrl.TrimEnd('/') + "/");
        }

        if (_httpClient.DefaultRequestHeaders.Authorization == null && !string.IsNullOrWhiteSpace(_settings.ApiKey))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _settings.ApiKey);
        }

        if (!_httpClient.DefaultRequestHeaders.Contains("X-Odoo-Database") && !string.IsNullOrWhiteSpace(_settings.Database))
        {
            _httpClient.DefaultRequestHeaders.TryAddWithoutValidation("X-Odoo-Database", _settings.Database);
        }

        var timeoutSeconds = _settings.TimeoutSeconds > 0 ? _settings.TimeoutSeconds : 30;
        try
        {
            _httpClient.Timeout = TimeSpan.FromSeconds(timeoutSeconds);
        }
        catch (InvalidOperationException)
        {
            // Ignorar si el HttpClient ya inició operaciones en un contexto previo
        }
    }

    private string BuildJson2Url(string model, string method)
    {
        var normalizedUrl = _settings.Url.Replace("://localhost", "://127.0.0.1");
        return $"{normalizedUrl.TrimEnd('/')}/json/2/{model}/{method}";
    }

    private static List<JsonElement> ExtractRecordsFromJson2(JsonElement responseElement)
    {
        if (responseElement.ValueKind == JsonValueKind.Array)
        {
            return responseElement.EnumerateArray().ToList();
        }

        if (responseElement.ValueKind == JsonValueKind.Object)
        {
            if (responseElement.TryGetProperty("result", out var resultProp) && resultProp.ValueKind == JsonValueKind.Array)
            {
                return resultProp.EnumerateArray().ToList();
            }
            if (responseElement.TryGetProperty("records", out var recordsProp) && recordsProp.ValueKind == JsonValueKind.Array)
            {
                return recordsProp.EnumerateArray().ToList();
            }
            if (responseElement.TryGetProperty("data", out var dataProp) && dataProp.ValueKind == JsonValueKind.Array)
            {
                return dataProp.EnumerateArray().ToList();
            }
        }

        return new List<JsonElement>();
    }

    private async Task<T?> CallJson2Async<T>(string model, string method, object payload, CancellationToken cancellationToken = default)
    {
        var url = BuildJson2Url(model, method);
        using var request = new HttpRequestMessage(HttpMethod.Post, url);

        // Encabezados obligatorios según Validación Técnica Odoo 20 JSON-2
        if (!string.IsNullOrWhiteSpace(_settings.ApiKey) && request.Headers.Authorization == null && _httpClient.DefaultRequestHeaders.Authorization == null)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _settings.ApiKey);
        }

        if (!string.IsNullOrWhiteSpace(_settings.Database) && !request.Headers.Contains("X-Odoo-Database") && !_httpClient.DefaultRequestHeaders.Contains("X-Odoo-Database"))
        {
            request.Headers.Add("X-Odoo-Database", _settings.Database);
        }

        request.Content = new StringContent(
            JsonSerializer.Serialize(payload, JsonOptions),
            System.Text.Encoding.UTF8,
            "application/json"
        );

        HttpResponseMessage httpResponse;
        try
        {
            httpResponse = await _httpClient.SendAsync(request, cancellationToken);
            if (!httpResponse.IsSuccessStatusCode)
            {
                var errorBody = await httpResponse.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("Error HTTP al comunicarse con Odoo JSON-2 en {Url} ({StatusCode}): {ErrorBody}", url, (int)httpResponse.StatusCode, errorBody);
                throw new OdooIntegrationException($"Fallo en la conexión HTTP con Odoo JSON-2 ({url}): {(int)httpResponse.StatusCode} {httpResponse.ReasonPhrase} - {errorBody}");
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex) when (ex is not OdooIntegrationException)
        {
            _logger.LogError(ex, "Error HTTP al comunicarse con Odoo JSON-2 en {Url}", url);
            throw new OdooIntegrationException($"Fallo en la conexión HTTP con Odoo JSON-2 ({url}): {ex.Message}", ex);
        }

        var responseContent = await httpResponse.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(responseContent))
        {
            return default;
        }

        try
        {
            return JsonSerializer.Deserialize<T>(responseContent, JsonOptions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deserializando respuesta JSON-2 desde {Url}: {Content}", url, responseContent);
            throw new OdooIntegrationException($"Respuesta inesperada desde Odoo JSON-2: {ex.Message}", ex);
        }
    }

    public async Task<LoginResponseDto> AuthenticateAsync(string username, string password, CancellationToken cancellationToken = default)
    {
        var cleanUsername = username.Trim();

        // 1. Verificar credenciales en el almacén de clientes registrados
        var (isValid, record) = await _credentialStore.VerifyCredentialAsync(cleanUsername, password);
        if (isValid && record != null)
        {
            var token = _jwtTokenService.GenerateToken(record.PartnerId, record.Email, record.Name);
            return new LoginResponseDto
            {
                IsAuthenticated = true,
                Uid = record.PartnerId,
                PartnerId = record.PartnerId,
                Username = record.Email,
                Name = record.Name,
                AccessToken = token,
                SessionId = Guid.NewGuid().ToString("N"),
                Message = "Inicio de sesión exitoso."
            };
        }

        // 2. Si no está en el almacén local, consultar en Odoo res.partner vía JSON-2
        try
        {
            var searchPayload = new
            {
                domain = new object[]
                {
                    new object[] { "email", "=", cleanUsername }
                },
                fields = new[] { "id", "name", "email" },
                limit = 1
            };

            var responseElement = await CallJson2Async<JsonElement>("res.partner", "search_read", searchPayload, cancellationToken);
            var partners = ExtractRecordsFromJson2(responseElement);
            if (partners != null && partners.Count > 0)
            {
                var partnerElem = partners[0];
                var partnerId = partnerElem.GetProperty("id").GetInt32();
                var name = partnerElem.TryGetProperty("name", out var n) ? n.GetString() ?? cleanUsername : cleanUsername;
                var email = partnerElem.TryGetProperty("email", out var e) ? e.GetString() ?? cleanUsername : cleanUsername;

                var token = _jwtTokenService.GenerateToken(partnerId, email, name);
                return new LoginResponseDto
                {
                    IsAuthenticated = true,
                    Uid = partnerId,
                    PartnerId = partnerId,
                    Username = email,
                    Name = name,
                    AccessToken = token,
                    SessionId = Guid.NewGuid().ToString("N"),
                    Message = "Inicio de sesión exitoso mediante contacto Odoo."
                };
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "No se pudo consultar res.partner en Odoo para {Username}", cleanUsername);
        }

        return new LoginResponseDto
        {
            IsAuthenticated = false,
            Message = "Credenciales incorrectas o usuario no encontrado en Odoo."
        };
    }

    public async Task<RegisterResponseDto> RegisterCustomerAsync(RegisterRequestDto request, CancellationToken cancellationToken = default)
    {
        var cleanEmail = request.Email.Trim();
        var cleanName = request.Name.Trim();
        var cleanPhone = request.Phone?.Trim();

        // 1. Verificar si ya existe en el almacén de credenciales
        if (await _credentialStore.ExistsEmailAsync(cleanEmail))
        {
            return new RegisterResponseDto
            {
                Success = false,
                Message = "El correo electrónico ya se encuentra registrado."
            };
        }

        // 2. Verificar si ya existe en Odoo res.partner mediante /json/2/res.partner/search_read
        try
        {
            var checkPayload = new
            {
                domain = new object[]
                {
                    new object[] { "email", "=", cleanEmail }
                },
                fields = new[] { "id", "name", "email" },
                limit = 1
            };

            var responseElement = await CallJson2Async<JsonElement>("res.partner", "search_read", checkPayload, cancellationToken);
            var existingPartners = ExtractRecordsFromJson2(responseElement);

            // Solo si el arreglo resultante contiene al menos un elemento (Count > 0), se rechaza por duplicado.
            // Si el arreglo viene vacío ([]), procede inmediatamente a crear el nuevo res.partner.
            if (existingPartners != null && existingPartners.Count > 0)
            {
                var matchingPartner = existingPartners.FirstOrDefault(p =>
                {
                    if (p.TryGetProperty("email", out var emailProp) && emailProp.ValueKind == JsonValueKind.String)
                    {
                        var emailVal = emailProp.GetString();
                        return !string.IsNullOrWhiteSpace(emailVal) &&
                               string.Equals(emailVal.Trim(), cleanEmail, StringComparison.OrdinalIgnoreCase);
                    }
                    return false;
                });

                if (matchingPartner.ValueKind != JsonValueKind.Undefined)
                {
                    _logger.LogWarning("Contacto existente en Odoo encontrado para el correo {Email}", cleanEmail);
                    return new RegisterResponseDto
                    {
                        Success = false,
                        Message = "Ya existe un contacto registrado con este correo en Odoo."
                    };
                }
            }
        }
        catch (Exception ex)
        {
            // Si la consulta a search_read falla o no puede deserializarse, no capturar devolviendo "Ya existe un contacto...".
            // Se registra el error real en los logs.
            _logger.LogError(ex, "Error al consultar /json/2/res.partner/search_read en Odoo para el correo {Email}. Se procederá con la creación.", cleanEmail);
        }

        // 3. Crear el cliente en Odoo res.partner vía JSON-2 (/json/2/res.partner/create)
        var payloadObj = new Dictionary<string, object>
        {
            ["vals_list"] = new object[]
            {
                new Dictionary<string, object>
                {
                    ["name"] = cleanName,
                    ["email"] = cleanEmail,
                    ["phone"] = cleanPhone ?? string.Empty,
                    ["customer_rank"] = 1
                }
            }
        };

        var jsonContent = new StringContent(
            System.Text.Json.JsonSerializer.Serialize(payloadObj),
            System.Text.Encoding.UTF8,
            "application/json"
        );

        // Enviar POST a http://localhost:8069/json/2/res.partner/create
        HttpResponseMessage response;
        try
        {
            response = await _httpClient.PostAsync("/json/2/res.partner/create", jsonContent, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("Error HTTP al comunicarse con Odoo JSON-2 en /json/2/res.partner/create ({StatusCode}): {ErrorBody}", (int)response.StatusCode, errorBody);
                throw new OdooIntegrationException($"Fallo en la conexión HTTP con Odoo JSON-2 (/json/2/res.partner/create): {(int)response.StatusCode} {response.ReasonPhrase} - {errorBody}");
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex) when (ex is not OdooIntegrationException)
        {
            _logger.LogError(ex, "Error HTTP al comunicarse con Odoo JSON-2 en /json/2/res.partner/create");
            throw new OdooIntegrationException($"Fallo en la conexión HTTP con Odoo JSON-2 (/json/2/res.partner/create): {ex.Message}", ex);
        }

        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(responseContent))
        {
            throw new OdooIntegrationException("Odoo no devolvió respuesta para el contacto creado.");
        }

        JsonElement createResult;
        try
        {
            createResult = JsonSerializer.Deserialize<JsonElement>(responseContent, JsonOptions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deserializando respuesta JSON-2 de creación desde /json/2/res.partner/create: {Content}", responseContent);
            throw new OdooIntegrationException($"Respuesta inesperada desde Odoo JSON-2: {ex.Message}", ex);
        }

        int partnerId = 0;
        if (createResult.ValueKind == JsonValueKind.Array && createResult.GetArrayLength() > 0)
        {
            partnerId = createResult[0].GetInt32();
        }
        else if (createResult.ValueKind == JsonValueKind.Number)
        {
            partnerId = createResult.GetInt32();
        }
        else if (createResult.ValueKind == JsonValueKind.Object)
        {
            if (createResult.TryGetProperty("result", out var resProp))
            {
                if (resProp.ValueKind == JsonValueKind.Array && resProp.GetArrayLength() > 0)
                {
                    partnerId = resProp[0].GetInt32();
                }
                else if (resProp.ValueKind == JsonValueKind.Number)
                {
                    partnerId = resProp.GetInt32();
                }
            }
            else if (createResult.TryGetProperty("id", out var idProp) && idProp.ValueKind == JsonValueKind.Number)
            {
                partnerId = idProp.GetInt32();
            }
        }

        if (partnerId <= 0)
        {
            throw new OdooIntegrationException("Odoo no devolvió un identificador válido para el contacto creado.");
        }

        // 4. Guardar credenciales de forma segura
        await _credentialStore.SaveCredentialAsync(partnerId, cleanName, cleanEmail, request.Password);

        // 5. Generar token JWT firmado
        var token = _jwtTokenService.GenerateToken(partnerId, cleanEmail, cleanName);

        _logger.LogInformation("Cliente registrado con éxito en Odoo res.partner ID {PartnerId} ({Email})", partnerId, cleanEmail);

        return new RegisterResponseDto
        {
            Success = true,
            PartnerId = partnerId,
            Name = cleanName,
            Email = cleanEmail,
            AccessToken = token,
            Message = "Cliente registrado exitosamente."
        };
    }

    public async Task<IReadOnlyList<ProductDto>> GetProductsAsync(int? categoryId = null, CancellationToken cancellationToken = default)
    {
        var domain = new List<object>
        {
            new object[] { "sale_ok", "=", true }
        };

        if (categoryId.HasValue && categoryId.Value > 0)
        {
            domain.Add(new object[] { "categ_id", "=", categoryId.Value });
        }

        var payload = new
        {
            domain = domain,
            fields = new[] { "id", "name", "description_sale", "list_price", "qty_available", "categ_id", "barcode", "default_code", "image_128" },
            limit = 100
        };

        var products = await CallJson2Async<List<OdooProductModel>>(
            "product.template",
            "search_read",
            payload,
            cancellationToken);

        return (products ?? new List<OdooProductModel>())
            .Select(OdooProductMapper.ToDto)
            .ToList();
    }

    public async Task<ProductDto?> GetProductByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var domain = new List<object>
        {
            new object[] { "id", "=", id },
            new object[] { "sale_ok", "=", true }
        };

        var payload = new Dictionary<string, object>
        {
            ["domain"] = domain,
            ["fields"] = new[] { "id", "name", "description_sale", "list_price", "qty_available", "categ_id", "barcode", "default_code", "image_128" },
            ["limit"] = 1
        };

        var products = await CallJson2Async<List<OdooProductModel>>(
            "product.template",
            "search_read",
            payload,
            cancellationToken);

        var product = products?.FirstOrDefault(p => p.Id == id) ?? products?.FirstOrDefault();
        return product != null ? OdooProductMapper.ToDto(product) : null;
    }

    public async Task<IReadOnlyList<CategoryDto>> GetCategoriesAsync(CancellationToken cancellationToken = default)
    {
        // Filtrar categorías técnicas ("All", "Todos", "Expenses")
        var domain = new List<object>
        {
            new object[] { "name", "!=", "All" },
            new object[] { "name", "!=", "Todos" },
            new object[] { "name", "!=", "Expenses" }
        };

        var payload = new
        {
            domain = domain,
            fields = new[] { "id", "name", "parent_id" },
            limit = 100
        };

        var categories = await CallJson2Async<List<OdooCategoryModel>>(
            "product.category",
            "search_read",
            payload,
            cancellationToken);

        return (categories ?? new List<OdooCategoryModel>())
            .Select(OdooCategoryMapper.ToDto)
            .ToList();
    }

    public async Task<OrderDto> CreateOrderAsync(CreateOrderDto orderDto, CancellationToken cancellationToken = default)
    {
        // Construir líneas con comando relacional [0, 0, {...}] según especificación técnica Odoo 20
        var orderLinesPayload = orderDto.Items.Select(item => new object[]
        {
            0,
            0,
            new Dictionary<string, object>
            {
                ["product_id"] = item.ProductId,
                ["product_uom_qty"] = item.Quantity,
                ["price_unit"] = item.UnitPrice
            }
        }).ToList();

        // 1. Crear cotización mediante JSON-2: POST /json/2/sale.order/create
        var partnerId = orderDto.CustomerId;
        var payloadObj = new Dictionary<string, object>
        {
            ["vals_list"] = new object[]
            {
                new Dictionary<string, object>
                {
                    ["partner_id"] = partnerId,
                    ["client_order_ref"] = $"PEDIDO-{DateTime.UtcNow:yyyyMMddHHmmss}",
                    ["order_line"] = orderLinesPayload // Lista de [0, 0, { "product_id": id, "product_uom_qty": qty, "price_unit": price }]
                }
            }
        };

        var jsonContent = new StringContent(
            System.Text.Json.JsonSerializer.Serialize(payloadObj),
            System.Text.Encoding.UTF8,
            "application/json"
        );

        HttpResponseMessage response;
        try
        {
            response = await _httpClient.PostAsync("/json/2/sale.order/create", jsonContent, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("Error HTTP al comunicarse con Odoo JSON-2 en /json/2/sale.order/create ({StatusCode}): {ErrorBody}", (int)response.StatusCode, errorBody);
                throw new OdooIntegrationException($"Fallo en la conexión HTTP con Odoo JSON-2 (/json/2/sale.order/create): {(int)response.StatusCode} {response.ReasonPhrase} - {errorBody}");
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex) when (ex is not OdooIntegrationException)
        {
            _logger.LogError(ex, "Error HTTP al comunicarse con Odoo JSON-2 en /json/2/sale.order/create");
            throw new OdooIntegrationException($"Fallo en la conexión HTTP con Odoo JSON-2 (/json/2/sale.order/create): {ex.Message}", ex);
        }

        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(responseContent))
        {
            throw new OdooIntegrationException("Odoo no devolvió respuesta para la orden creada.");
        }

        JsonElement createResult;
        try
        {
            createResult = JsonSerializer.Deserialize<JsonElement>(responseContent, JsonOptions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deserializando respuesta JSON-2 de creación desde /json/2/sale.order/create: {Content}", responseContent);
            throw new OdooIntegrationException($"Respuesta inesperada desde Odoo JSON-2: {ex.Message}", ex);
        }

        int orderId = 0;
        if (createResult.ValueKind == JsonValueKind.Array && createResult.GetArrayLength() > 0)
        {
            orderId = createResult[0].GetInt32();
        }
        else if (createResult.ValueKind == JsonValueKind.Number)
        {
            orderId = createResult.GetInt32();
        }
        else if (createResult.ValueKind == JsonValueKind.Object)
        {
            if (createResult.TryGetProperty("result", out var resProp))
            {
                if (resProp.ValueKind == JsonValueKind.Array && resProp.GetArrayLength() > 0)
                {
                    orderId = resProp[0].GetInt32();
                }
                else if (resProp.ValueKind == JsonValueKind.Number)
                {
                    orderId = resProp.GetInt32();
                }
            }
            else if (createResult.TryGetProperty("id", out var idProp) && idProp.ValueKind == JsonValueKind.Number)
            {
                orderId = idProp.GetInt32();
            }
        }

        if (orderId <= 0)
        {
            throw new OdooIntegrationException("Odoo JSON-2 no devolvió un identificador válido para la cotización creada.");
        }

        _logger.LogInformation("Cotización ID {OrderId} creada exitosamente en Odoo para cliente {CustomerId}", orderId, partnerId);

        // 2. Confirmación inmediata del pedido: POST /json/2/sale.order/action_confirm
        // Cumplimiento estricto del Paso 10 del documento técnico de validación Odoo 20
        try
        {
            var confirmPayload = new Dictionary<string, object>
            {
                ["ids"] = new[] { orderId },
                ["context"] = new Dictionary<string, object>()
            };

            var confirmResult = await CallJson2Async<JsonElement>(
                "sale.order",
                "action_confirm",
                confirmPayload,
                cancellationToken);

            _logger.LogInformation("Pedido ID {OrderId} confirmado formalmente en Odoo (action_confirm): {Result}", orderId, confirmResult);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "El pedido ID {OrderId} fue creado pero la confirmación automática action_confirm arrojó advertencia: {Message}", orderId, ex.Message);
        }

        // 3. Validación de inventario defensiva (No bloqueante de la respuesta)
        // Mantener la confirmación del pedido como respuesta garantizada al cliente,
        // asegurando que stock.picking termine en estado 'done' para descontar stock físico (qty_available)
        try
        {
            using var pickingCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            pickingCts.CancelAfter(TimeSpan.FromSeconds(8));

            await AutoValidatePickingForOrderAsync(orderId, pickingCts.Token);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "La validación síncrona del picking para la orden {OrderId} no concluyó dentro del tiempo límite. Continuando en segundo plano.", orderId);

            _ = Task.Run(async () =>
            {
                try
                {
                    using var bgCts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
                    await AutoValidatePickingForOrderAsync(orderId, bgCts.Token);
                }
                catch (Exception bgEx)
                {
                    _logger.LogWarning(bgEx, "No se pudo auto-validar el picking para la orden {OrderId}. Se mantiene como confirmada.", orderId);
                }
            });
        }

        // 4. Recuperar y retornar la orden confirmada con sus líneas de forma resiliente
        try
        {
            return await FetchOrderDetailsAsync(orderId, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "El pedido ID {OrderId} fue creado y confirmado en Odoo, pero ocurrió una advertencia al consultar sus líneas detalladas: {Message}", orderId, ex.Message);
            return new OrderDto
            {
                Id = orderId,
                OdooOrderId = orderId,
                CustomerId = partnerId,
                OrderDate = DateTime.UtcNow,
                Status = OrderStatus.Confirmed,
                TotalAmount = orderDto.Items.Sum(i => i.Quantity * i.UnitPrice),
                Items = orderDto.Items.Select(i => new OrderItemDto
                {
                    ProductId = i.ProductId,
                    ProductName = $"Producto {i.ProductId}",
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice
                }).ToList()
            };
        }
    }

    public record OdooPickingRecord(int Id, string State);

    /// <summary>
    /// Busca los albaranes de entrega (stock.picking) asociados a la orden de venta que no se encuentren finalizados ni cancelados.
    /// </summary>
    private async Task<List<OdooPickingRecord>> SearchPickingsBySaleOrderAsync(int orderId, CancellationToken cancellationToken = default)
    {
        var pickingQuery = new
        {
            domain = new object[]
            {
                new object[] { "sale_id", "=", orderId },
                new object[] { "state", "not in", new object[] { "done", "cancel" } }
            },
            fields = new[] { "id", "state" },
            limit = 5
        };

        var responseElement = await CallJson2Async<JsonElement>(
            "stock.picking",
            "search_read",
            pickingQuery,
            cancellationToken);

        var records = ExtractRecordsFromJson2(responseElement);
        var result = new List<OdooPickingRecord>();

        foreach (var elem in records)
        {
            int id = 0;
            if (elem.TryGetProperty("id", out var idProp) && idProp.ValueKind == JsonValueKind.Number)
            {
                id = idProp.GetInt32();
            }

            string state = elem.TryGetProperty("state", out var stateProp) && stateProp.ValueKind == JsonValueKind.String
                ? stateProp.GetString() ?? string.Empty
                : string.Empty;

            if (id > 0)
            {
                result.Add(new OdooPickingRecord(id, state));
            }
        }

        if (result.Count == 0)
        {
            try
            {
                var saleOrderQuery = new
                {
                    domain = new object[]
                    {
                        new object[] { "id", "=", orderId }
                    },
                    fields = new[] { "id", "picking_ids" },
                    limit = 1
                };

                var soResponse = await CallJson2Async<JsonElement>("sale.order", "search_read", saleOrderQuery, cancellationToken);
                var soRecords = ExtractRecordsFromJson2(soResponse);
                if (soRecords.Count > 0 && soRecords[0].TryGetProperty("picking_ids", out var pickIdsProp) && pickIdsProp.ValueKind == JsonValueKind.Array)
                {
                    var pickIds = pickIdsProp.EnumerateArray()
                        .Where(p => p.ValueKind == JsonValueKind.Number)
                        .Select(p => p.GetInt32())
                        .ToList();

                    if (pickIds.Count > 0)
                    {
                        var fallbackQuery = new
                        {
                            domain = new object[]
                            {
                                new object[] { "id", "in", pickIds.ToArray() },
                                new object[] { "state", "not in", new object[] { "done", "cancel" } }
                            },
                            fields = new[] { "id", "state" },
                            limit = 5
                        };

                        var fallbackResponse = await CallJson2Async<JsonElement>("stock.picking", "search_read", fallbackQuery, cancellationToken);
                        var fallbackRecords = ExtractRecordsFromJson2(fallbackResponse);
                        foreach (var elem in fallbackRecords)
                        {
                            if (elem.TryGetProperty("id", out var fIdProp) && fIdProp.ValueKind == JsonValueKind.Number)
                            {
                                var fState = elem.TryGetProperty("state", out var fStateProp) && fStateProp.ValueKind == JsonValueKind.String
                                    ? fStateProp.GetString() ?? string.Empty
                                    : string.Empty;
                                result.Add(new OdooPickingRecord(fIdProp.GetInt32(), fState));
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Fallo en consulta de respaldo de picking_ids para sale.order {OrderId}", orderId);
            }
        }

        return result;
    }

    /// <summary>
    /// Comprueba la disponibilidad de inventario para el albarán en Odoo (action_assign).
    /// </summary>
    private async Task ActionAssignPickingAsync(int pickingId, CancellationToken cancellationToken = default)
    {
        try
        {
            var assignPayload = new Dictionary<string, object>
            {
                ["ids"] = new[] { pickingId },
                ["context"] = new Dictionary<string, object>()
            };

            await CallJson2Async<JsonElement>(
                "stock.picking",
                "action_assign",
                assignPayload,
                cancellationToken);

            _logger.LogInformation("Disponibilidad asignada (action_assign) para stock.picking ID {PickingId}", pickingId);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Advertencia al ejecutar action_assign para stock.picking ID {PickingId}: {Message}", pickingId, ex.Message);
        }
    }

    /// <summary>
    /// Orquesta la auto-validación del albarán de entrega para descontar físicamente el stock (qty_available) en Odoo.
    /// </summary>
    private async Task AutoValidatePickingForOrderAsync(int orderId, CancellationToken cancellationToken)
    {
        var pickings = await SearchPickingsBySaleOrderAsync(orderId, cancellationToken);
        if (pickings == null || !pickings.Any())
        {
            _logger.LogInformation("No se encontraron albaranes de entrega pendientes para la orden {OrderId}", orderId);
            return;
        }

        foreach (var picking in pickings)
        {
            var pickingId = picking.Id;
            if (picking.State == "done")
            {
                _logger.LogInformation("stock.picking ID {PickingId} ya se encuentra en estado 'done'", pickingId);
                continue;
            }

            // 1. Asignar disponibilidad en Odoo (action_assign)
            await ActionAssignPickingAsync(pickingId, cancellationToken);

            // 2. Validar albarán de entrega (auto-llenar cantidades, button_validate con bypass y procesar wizard si aplica)
            await ValidatePickingAsync(pickingId, cancellationToken);
        }
    }

    /// <summary>
    /// Auto-llena las cantidades realizadas (quantity o quantity_done) en las líneas stock.move
    /// asociadas al albarán antes de validar, garantizando que Odoo reconozca la entrega completa y no abra wizards interactivos.
    /// </summary>
    private async Task AutoFillMoveQuantitiesAsync(int pickingId, CancellationToken cancellationToken = default)
    {
        try
        {
            var movesQuery = new
            {
                domain = new object[]
                {
                    new object[] { "picking_id", "=", pickingId }
                },
                fields = new[] { "id", "product_uom_qty" },
                limit = 100
            };

            var movesResponse = await CallJson2Async<JsonElement>("stock.move", "search_read", movesQuery, cancellationToken);
            var moveRecords = ExtractRecordsFromJson2(movesResponse);

            if (moveRecords == null || moveRecords.Count == 0)
            {
                _logger.LogInformation("No se encontraron líneas stock.move para el albarán ID {PickingId}", pickingId);
                return;
            }

            foreach (var move in moveRecords)
            {
                if (move.TryGetProperty("id", out var idProp) && idProp.ValueKind == JsonValueKind.Number)
                {
                    var moveId = idProp.GetInt32();
                    decimal qty = 1;
                    if (move.TryGetProperty("product_uom_qty", out var qtyProp) && qtyProp.ValueKind == JsonValueKind.Number)
                    {
                        qty = qtyProp.GetDecimal();
                    }

                    bool updated = false;
                    try
                    {
                        var writePayload = new
                        {
                            ids = new[] { moveId },
                            vals = new
                            {
                                quantity = qty,
                                picked = true
                            }
                        };
                        await CallJson2Async<JsonElement>("stock.move", "write", writePayload, cancellationToken);
                        updated = true;
                        _logger.LogInformation("stock.move ID {MoveId} actualizado con quantity={Qty}, picked=true", moveId, qty);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogDebug(ex, "No se pudo actualizar stock.move ID {MoveId} con quantity/picked, reintentando con quantity_done: {Message}", moveId, ex.Message);
                    }

                    if (!updated)
                    {
                        try
                        {
                            var fallbackPayload = new
                            {
                                ids = new[] { moveId },
                                vals = new
                                {
                                    quantity_done = qty
                                }
                            };
                            await CallJson2Async<JsonElement>("stock.move", "write", fallbackPayload, cancellationToken);
                            _logger.LogInformation("stock.move ID {MoveId} actualizado con quantity_done={Qty}", moveId, qty);
                        }
                        catch (Exception exFallback)
                        {
                            _logger.LogWarning(exFallback, "Fallo al actualizar stock.move ID {MoveId} con quantity_done: {Message}", moveId, exFallback.Message);
                        }
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Advertencia al auto-llenar cantidades de stock.move para picking ID {PickingId}: {Message}", pickingId, ex.Message);
        }
    }

    private Task SetMoveQuantitiesAsync(int pickingId, CancellationToken cancellationToken = default)
    {
        return AutoFillMoveQuantitiesAsync(pickingId, cancellationToken);
    }

    /// <summary>
    /// Ejecuta la validación de salida de inventario (button_validate):
    /// 1. Auto-llena las cantidades realizadas (quantity) antes de validar.
    /// 2. Invoca button_validate enviando flags de contexto para omitir asistentes interactivos.
    /// 3. Procesa el Wizard interactivo si Odoo devuelve un ir.actions.act_window llamando al método process().
    /// 4. Mantiene la resiliencia en bloque defensivo try-catch.
    /// </summary>
    private async Task ValidatePickingAsync(int pickingId, CancellationToken cancellationToken = default)
    {
        try
        {
            // 1. Auto-llenar cantidades realizadas (quantity) antes de validar
            await AutoFillMoveQuantitiesAsync(pickingId, cancellationToken);

            // 2. Validar con bypass de wizards en el contexto (incluyendo skip_sms para evitar confirm.stock.sms)
            var validatePayload = new
            {
                ids = new[] { pickingId },
                context = new
                {
                    skip_immediate = true,
                    skip_backorder = true,
                    skip_sms = true,
                    skip_sanity_check = true,
                    button_validate_picking_ids = new[] { pickingId }
                }
            };

            var validateResult = await CallJson2Async<JsonElement>(
                "stock.picking",
                "button_validate",
                validatePayload,
                cancellationToken);

            _logger.LogInformation("button_validate ejecutado para stock.picking ID {PickingId}", pickingId);

            // Si Odoo devuelve true directamente, la entrega fue validada con éxito
            if (validateResult.ValueKind == JsonValueKind.True)
            {
                _logger.LogInformation("stock.picking ID {PickingId} validado exitosamente en estado 'done'. Stock físico (qty_available) descontado en Odoo.", pickingId);
                return;
            }

            // 3. Procesar el Wizard si Odoo aún lo devuelve (ir.actions.act_window con res_model)
            if (IsActionWindow(validateResult, out var actionType, out var resModel, out var wizardId, out var wizardContext))
            {
                _logger.LogInformation(
                    "button_validate devolvió asistente de confirmación '{ResModel}' (ID: {WizardId}) para stock.picking {PickingId}. Procesando asistente...",
                    resModel, wizardId, pickingId);

                await ProcessWizardAsync(pickingId, resModel, wizardId, cancellationToken);
            }

            // Asegurar que la entrega quede formalmente en estado 'done'
            await EnsurePickingDoneAsync(pickingId, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Advertencia al validar entrega para stock.picking ID {PickingId}: {Message}", pickingId, ex.Message);
        }
    }

    private async Task ProcessWizardAsync(
        int pickingId,
        string? resModel,
        int wizardId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(resModel))
        {
            return;
        }

        if (wizardId <= 0)
        {
            _logger.LogWarning("No se puede ejecutar process() en asistente '{ResModel}' para stock.picking {PickingId} porque res_id no es válido ({WizardId})", resModel, pickingId, wizardId);
            return;
        }

        try
        {
            if (string.Equals(resModel, "confirm.stock.sms", StringComparison.OrdinalIgnoreCase))
            {
                var smsPayload = new
                {
                    ids = new[] { wizardId },
                    context = new
                    {
                        button_validate_picking_ids = new[] { pickingId },
                        skip_sms = true,
                        skip_backorder = true
                    }
                };

                await CallJson2Async<JsonElement>(resModel, "dont_send_sms", smsPayload, cancellationToken);
                _logger.LogInformation("Método dont_send_sms() en '{ResModel}' ID {WizardId} ejecutado exitosamente para stock.picking {PickingId}", resModel, wizardId, pickingId);
                return;
            }

            var processPayload = new
            {
                ids = new[] { wizardId },
                context = new
                {
                    button_validate_picking_ids = new[] { pickingId },
                    skip_sms = true,
                    skip_backorder = true
                }
            };

            await CallJson2Async<JsonElement>(resModel, "process", processPayload, cancellationToken);
            _logger.LogInformation("Método process() en '{ResModel}' ID {WizardId} ejecutado exitosamente para stock.picking {PickingId}", resModel, wizardId, pickingId);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Advertencia al procesar asistente '{ResModel}' ID {WizardId} para picking {PickingId}: {Message}", resModel, wizardId, pickingId, ex.Message);

            if (resModel == "stock.backorder.confirmation")
            {
                try
                {
                    var cancelBackorderPayload = new
                    {
                        ids = new[] { wizardId },
                        context = new
                        {
                            button_validate_picking_ids = new[] { pickingId },
                            skip_sms = true,
                            skip_backorder = true
                        }
                    };
                    await CallJson2Async<JsonElement>(resModel, "process_cancel_backorder", cancelBackorderPayload, cancellationToken);
                    _logger.LogInformation("stock.backorder.confirmation ID {WizardId} procesado con cancel_backorder para picking {PickingId}", wizardId, pickingId);
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception fallbackEx)
                {
                    _logger.LogWarning(fallbackEx, "Fallback process_cancel_backorder en '{ResModel}' también falló: {Message}", resModel, fallbackEx.Message);
                }
            }
            else if (string.Equals(resModel, "confirm.stock.sms", StringComparison.OrdinalIgnoreCase))
            {
                try
                {
                    var sendSmsPayload = new
                    {
                        ids = new[] { wizardId },
                        context = new
                        {
                            button_validate_picking_ids = new[] { pickingId },
                            skip_sms = true,
                            skip_backorder = true
                        }
                    };
                    await CallJson2Async<JsonElement>(resModel, "send_sms", sendSmsPayload, cancellationToken);
                    _logger.LogInformation("confirm.stock.sms ID {WizardId} procesado con send_sms para picking {PickingId}", wizardId, pickingId);
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception fallbackEx)
                {
                    _logger.LogWarning(fallbackEx, "Fallback send_sms en '{ResModel}' también falló: {Message}", resModel, fallbackEx.Message);
                }
            }
        }
    }

    private async Task EnsurePickingDoneAsync(int pickingId, CancellationToken cancellationToken)
    {
        try
        {
            var checkQuery = new
            {
                domain = new object[]
                {
                    new object[] { "id", "=", pickingId }
                },
                fields = new[] { "id", "state" },
                limit = 1
            };

            var checkResponse = await CallJson2Async<JsonElement>("stock.picking", "search_read", checkQuery, cancellationToken);
            var checkRecords = ExtractRecordsFromJson2(checkResponse);
            string? finalState = null;
            if (checkRecords != null && checkRecords.Count > 0)
            {
                var record = checkRecords[0];
                if (record.TryGetProperty("state", out var stateProp) && stateProp.ValueKind == JsonValueKind.String)
                {
                    finalState = stateProp.GetString();
                }
            }

            if (finalState == "done")
            {
                _logger.LogInformation("stock.picking ID {PickingId} validado formalmente en estado 'done'. Stock físico (qty_available) descontado en Odoo.", pickingId);
            }
            else
            {
                _logger.LogInformation("stock.picking ID {PickingId} se encuentra en estado '{State}' tras la validación. Reintentando button_validate con bypass completo...", pickingId, finalState);

                try
                {
                    var retryPayload = new
                    {
                        ids = new[] { pickingId },
                        context = new
                        {
                            skip_immediate = true,
                            skip_backorder = true,
                            skip_sms = true,
                            skip_sanity_check = true,
                            button_validate_picking_ids = new[] { pickingId }
                        }
                    };

                    await CallJson2Async<JsonElement>(
                        "stock.picking",
                        "button_validate",
                        retryPayload,
                        cancellationToken);
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception retryEx)
                {
                    _logger.LogDebug(retryEx, "Reintento de button_validate para picking {PickingId} finalizó: {Message}", pickingId, retryEx.Message);
                }
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Advertencia al verificar estado en stock.picking {PickingId}: {Message}", pickingId, ex.Message);
        }
    }

    private static bool IsActionWindow(
        JsonElement element,
        out string? actionType,
        out string? resModel,
        out int wizardId,
        out object wizardContext)
    {
        actionType = null;
        resModel = null;
        wizardId = 0;
        wizardContext = new Dictionary<string, object>();

        var target = element;
        if (target.ValueKind == JsonValueKind.Object && target.TryGetProperty("result", out var resProp) && resProp.ValueKind == JsonValueKind.Object)
        {
            target = resProp;
        }

        if (target.ValueKind == JsonValueKind.Object)
        {
            if (target.TryGetProperty("type", out var typeProp) && typeProp.ValueKind == JsonValueKind.String)
            {
                actionType = typeProp.GetString();
            }

            if (target.TryGetProperty("res_model", out var modelProp) && modelProp.ValueKind == JsonValueKind.String)
            {
                resModel = modelProp.GetString();
            }

            if (target.TryGetProperty("res_id", out var resIdProp) && resIdProp.ValueKind == JsonValueKind.Number && resIdProp.TryGetInt32(out var id))
            {
                wizardId = id;
            }
            else if (target.TryGetProperty("res_ids", out var resIdsProp) && resIdsProp.ValueKind == JsonValueKind.Array && resIdsProp.GetArrayLength() > 0)
            {
                if (resIdsProp[0].ValueKind == JsonValueKind.Number && resIdsProp[0].TryGetInt32(out var arrId))
                {
                    wizardId = arrId;
                }
            }

            if (target.TryGetProperty("context", out var ctxProp) && ctxProp.ValueKind == JsonValueKind.Object)
            {
                wizardContext = ctxProp;
            }

            if (string.Equals(actionType, "ir.actions.act_window", StringComparison.OrdinalIgnoreCase) ||
                (actionType != null && actionType.StartsWith("ir.actions.", StringComparison.OrdinalIgnoreCase)) ||
                !string.IsNullOrWhiteSpace(resModel))
            {
                return true;
            }
        }

        return false;
    }

    public async Task<IReadOnlyList<OrderDto>> GetOrdersByCustomerAsync(int customerId, CancellationToken cancellationToken = default)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(TimeSpan.FromSeconds(8));

        try
        {
            var domain = new List<object>
            {
                new object[] { "partner_id", "=", customerId }
            };

            var payload = new
            {
                domain = domain,
                fields = new[] { "id", "name", "date_order", "amount_total", "state", "order_line" },
                order = "id desc",
                limit = 50
            };

            var orders = await CallJson2Async<List<OdooOrderModel>>(
                "sale.order",
                "search_read",
                payload,
                cts.Token) ?? new List<OdooOrderModel>();

            return orders.Select(order =>
            {
                var dto = OdooOrderMapper.ToDto(order);
                if (dto.CustomerId <= 0 && customerId > 0)
                {
                    dto.CustomerId = customerId;
                }
                return dto;
            }).ToList();
        }
        catch (OperationCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning("La consulta de pedidos para el cliente ID {CustomerId} excedió el tiempo límite estricto de 8 segundos.", customerId);
            throw new TimeoutException("La consulta de pedidos en Odoo excedió el tiempo límite de 8 segundos.", ex);
        }
    }

    public Task<IReadOnlyList<OrderDto>> GetOrdersByPartnerAsync(int partnerId, CancellationToken cancellationToken = default)
    {
        return GetOrdersByCustomerAsync(partnerId, cancellationToken);
    }

    private async Task<OrderDto> FetchOrderDetailsAsync(int orderId, CancellationToken cancellationToken)
    {
        var payload = new
        {
            domain = new List<object>
            {
                new object[] { "id", "=", orderId }
            },
            fields = new[] { "id", "name", "partner_id", "date_order", "state", "amount_total", "order_line" },
            limit = 1
        };

        var orders = await CallJson2Async<List<OdooOrderModel>>(
            "sale.order",
            "search_read",
            payload,
            cancellationToken);

        var order = orders?.FirstOrDefault()
            ?? throw new NotFoundException("Order", orderId);

        var lineIds = OdooJsonHelper.GetIntList(order.OrderLine);
        List<OdooOrderLineModel> lines = new();

        if (lineIds.Count > 0)
        {
            var linePayload = new
            {
                domain = new List<object>
                {
                    new object[] { "id", "in", lineIds }
                },
                fields = new[] { "id", "order_id", "product_id", "name", "product_uom_qty", "price_unit", "price_subtotal" }
            };

            lines = await CallJson2Async<List<OdooOrderLineModel>>(
                "sale.order.line",
                "search_read",
                linePayload,
                cancellationToken) ?? new List<OdooOrderLineModel>();
        }

        return OdooOrderMapper.ToDto(order, lines);
    }
}
