namespace ECommerce.Tests.Services;

using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using Moq.Protected;
using ECommerce.Application.DTOs.Orders;
using ECommerce.Application.Interfaces;
using ECommerce.Domain.Enums;
using ECommerce.Infrastructure.Configuration;
using ECommerce.Infrastructure.Odoo.Services;
using ECommerce.Infrastructure.Services;

public class OdooServiceOrderTests
{
    private readonly Mock<IJwtTokenService> _jwtTokenServiceMock;
    private readonly Mock<ICustomerCredentialStore> _credentialStoreMock;
    private readonly Mock<ILogger<OdooService>> _loggerMock;
    private readonly IOptions<OdooSettings> _options;

    public OdooServiceOrderTests()
    {
        _jwtTokenServiceMock = new Mock<IJwtTokenService>();
        _credentialStoreMock = new Mock<ICustomerCredentialStore>();
        _loggerMock = new Mock<ILogger<OdooService>>();
        _options = Options.Create(new OdooSettings
        {
            Url = "http://mock-odoo:8069",
            Database = "ecommerce_moviles",
            ApiKey = "test_api_key",
            TimeoutSeconds = 5
        });
    }

    private (OdooService service, List<HttpRequestMessage> sentRequests) CreateServiceWithResponses(params HttpResponseMessage[] responses)
    {
        var responseQueue = new Queue<HttpResponseMessage>(responses);
        var sentRequests = new List<HttpRequestMessage>();
        var handlerMock = new Mock<HttpMessageHandler>();

        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .Returns<HttpRequestMessage, CancellationToken>((req, ct) =>
            {
                sentRequests.Add(req);
                if (responseQueue.Count > 0)
                {
                    return Task.FromResult(responseQueue.Dequeue());
                }
                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent("[]") });
            });

        var httpClient = new HttpClient(handlerMock.Object);
        var service = new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);
        return (service, sentRequests);
    }

    private static HttpResponseMessage JsonResponse(string json, HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        return new HttpResponseMessage(statusCode)
        {
            Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
        };
    }

    [Fact]
    public async Task CreateOrderAsync_ValidatesDeliveryAndReturnsOrder()
    {
        // Arrange
        var (service, sentRequests) = CreateServiceWithResponses(
            // 1. sale.order/create
            JsonResponse("[101]"),
            // 2. sale.order/action_confirm
            JsonResponse("true"),
            // 3. stock.picking/search_read (find picking)
            JsonResponse("[{\"id\": 42, \"state\": \"confirmed\"}]"),
            // 4. stock.picking/action_assign
            JsonResponse("true"),
            // 5. stock.move/search_read (find moves for picking)
            JsonResponse("[{\"id\": 10, \"product_uom_qty\": 2.0}]"),
            // 6. stock.move/write (set quantity and picked)
            JsonResponse("true"),
            // 7. stock.picking/button_validate
            JsonResponse("true"),
            // 8. sale.order/search_read (fetch order)
            JsonResponse("[{\"id\": 101, \"name\": \"SO101\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 100.0, \"order_line\": [1]}]"),
            // 9. sale.order.line/search_read (fetch order lines)
            JsonResponse("[{\"id\": 1, \"order_id\": [101, \"SO101\"], \"product_id\": [10, \"Smartphone\"], \"name\": \"Smartphone\", \"product_uom_qty\": 2.0, \"price_unit\": 50.0, \"price_subtotal\": 100.0}]")
        );

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 10, Quantity = 2, UnitPrice = 50m }
            }
        };

        // Act
        var result = await service.CreateOrderAsync(orderDto);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(101);
        result.Status.Should().Be(OrderStatus.Confirmed);
        result.TotalAmount.Should().Be(100m);
        result.Items.Should().HaveCount(1);

        // Verify sent requests URLs
        var urls = sentRequests.Select(r => r.RequestUri?.AbsolutePath).ToList();
        urls.Should().Contain("/json/2/sale.order/create");
        urls.Should().Contain("/json/2/sale.order/action_confirm");
        urls.Should().Contain("/json/2/stock.picking/search_read");
        urls.Should().Contain("/json/2/stock.picking/action_assign");
        urls.Should().Contain("/json/2/stock.move/search_read");
        urls.Should().Contain("/json/2/stock.move/write");
        urls.Should().Contain("/json/2/stock.picking/button_validate");
    }

    [Fact]
    public async Task CreateOrderAsync_WhenButtonValidateReturnsWizard_ExecutesWizardAndCompletesOrder()
    {
        // Arrange
        var (service, sentRequests) = CreateServiceWithResponses(
            // 1. sale.order/create
            JsonResponse("[102]"),
            // 2. sale.order/action_confirm
            JsonResponse("true"),
            // 3. stock.picking/search_read
            JsonResponse("[{\"id\": 55, \"state\": \"confirmed\"}]"),
            // 4. stock.picking/action_assign
            JsonResponse("true"),
            // 5. stock.move/search_read
            JsonResponse("[{\"id\": 25, \"product_uom_qty\": 1.0}]"),
            // 6. stock.move/write
            JsonResponse("true"),
            // 7. stock.picking/button_validate -> returns immediate transfer wizard action (ir.actions.act_window)
            JsonResponse("{\"type\": \"ir.actions.act_window\", \"res_model\": \"stock.immediate.transfer\", \"res_id\": 88, \"context\": {\"button_validate_picking_ids\": [55]}}"),
            // 8. stock.immediate.transfer/process
            JsonResponse("true"),
            // 9. stock.picking/search_read (ensure picking state)
            JsonResponse("[{\"id\": 55, \"state\": \"done\"}]"),
            // 10. sale.order/search_read
            JsonResponse("[{\"id\": 102, \"name\": \"SO102\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 200.0, \"order_line\": []}]")
        );

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 15, Quantity = 1, UnitPrice = 200m }
            }
        };

        // Act
        var result = await service.CreateOrderAsync(orderDto);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(102);

        var urls = sentRequests.Select(r => r.RequestUri?.AbsolutePath).ToList();
        urls.Should().Contain("/json/2/stock.immediate.transfer/process");
    }

    [Fact]
    public async Task CreateOrderAsync_WhenPickingValidationFails_StillReturnsCreatedOrderSuccessfully()
    {
        // Arrange: picking validation encounters error (e.g. 500 Internal Server Error in stock.picking)
        var (service, sentRequests) = CreateServiceWithResponses(
            // 1. sale.order/create
            JsonResponse("[103]"),
            // 2. sale.order/action_confirm
            JsonResponse("true"),
            // 3. stock.picking/search_read -> fails with 500
            new HttpResponseMessage(HttpStatusCode.InternalServerError)
            {
                Content = new StringContent("{\"error\": \"Database lock\"}")
            },
            // 4. sale.order/search_read (order details fetch still succeeds!)
            JsonResponse("[{\"id\": 103, \"name\": \"SO103\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 50.0, \"order_line\": []}]")
        );

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 20, Quantity = 1, UnitPrice = 50m }
            }
        };

        // Act
        var result = await service.CreateOrderAsync(orderDto);

        // Assert: order is created and returned without throwing exception
        result.Should().NotBeNull();
        result.Id.Should().Be(103);
    }

    [Fact]
    public async Task CreateOrderAsync_WhenButtonValidateFails_StillReturnsCreatedOrderSuccessfully()
    {
        // Arrange
        var (service, sentRequests) = CreateServiceWithResponses(
            // 1. sale.order/create
            JsonResponse("[104]"),
            // 2. sale.order/action_confirm
            JsonResponse("true"),
            // 3. stock.picking/search_read
            JsonResponse("[{\"id\": 77, \"state\": \"confirmed\"}]"),
            // 4. stock.picking/action_assign
            JsonResponse("true"),
            // 5. stock.move/search_read (no moves to update in this scenario)
            JsonResponse("[]"),
            // 6. stock.picking/button_validate -> fails with 500
            new HttpResponseMessage(HttpStatusCode.InternalServerError)
            {
                Content = new StringContent("{\"error\": \"Validation error\"}")
            },
            // 7. sale.order/search_read
            JsonResponse("[{\"id\": 104, \"name\": \"SO104\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 75.0, \"order_line\": []}]")
        );

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 3, Quantity = 1, UnitPrice = 75m }
            }
        };

        // Act
        var result = await service.CreateOrderAsync(orderDto);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(104);

        var urls = sentRequests.Select(r => r.RequestUri?.AbsolutePath).ToList();
        urls.Should().Contain("/json/2/stock.picking/button_validate");
    }

    [Fact]
    public async Task GetOrdersByCustomerAsync_QueriesSaleOrderWithRestrictedFieldsAndNoNPlusOne()
    {
        string? capturedRequestBody = null;
        var sentRequests = new List<HttpRequestMessage>();
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .Returns<HttpRequestMessage, CancellationToken>(async (req, ct) =>
            {
                sentRequests.Add(req);
                if (req.Content != null)
                {
                    capturedRequestBody = await req.Content.ReadAsStringAsync(ct);
                }
                return JsonResponse("[{\"id\": 10, \"name\": \"SO010\", \"date_order\": \"2026-11-12\", \"amount_total\": 100.0, \"state\": \"sale\"}, {\"id\": 11, \"name\": \"SO011\", \"date_order\": \"2026-11-12\", \"amount_total\": 50.0, \"state\": \"draft\"}]");
            });

        var httpClient = new HttpClient(handlerMock.Object);
        var service = new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);

        // Act
        var result = await service.GetOrdersByCustomerAsync(7);

        // Assert: Exactly ONE HTTP request is sent (No N+1 queries!)
        sentRequests.Should().HaveCount(1);
        sentRequests[0].RequestUri?.AbsolutePath.Should().EndWith("/json/2/sale.order/search_read");

        // Inspect request body to ensure fields are restricted to UI requirements
        capturedRequestBody.Should().NotBeNull();
        using var doc = JsonDocument.Parse(capturedRequestBody!);
        var fieldsProp = doc.RootElement.GetProperty("fields");
        var fields = fieldsProp.EnumerateArray().Select(f => f.GetString()).ToList();

        // Estricto: NO traer ni mapear sale.order.line en el listado general
        fields.Should().BeEquivalentTo(new[] { "id", "name", "date_order", "amount_total", "state" });

        // Assert results
        result.Should().HaveCount(2);
        result[0].Id.Should().Be(10);
        result[0].CustomerId.Should().Be(7);
        result[0].Status.Should().Be(OrderStatus.Confirmed);
        result[0].TotalAmount.Should().Be(100.0m);
        result[0].Items.Should().BeEmpty();

        result[1].Id.Should().Be(11);
        result[1].CustomerId.Should().Be(7);
        result[1].Status.Should().Be(OrderStatus.Draft);
        result[1].TotalAmount.Should().Be(50.0m);
        result[1].Items.Should().BeEmpty();
    }

    [Fact]
    public async Task GetOrdersByCustomerAsync_WhenOdooTimesOut_ThrowsTimeoutException()
    {
        // Arrange: HttpMessageHandler that simulates timeout via TaskCanceledException when token is canceled
        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ThrowsAsync(new TaskCanceledException("The operation was canceled"));

        var httpClient = new HttpClient(handlerMock.Object);
        var service = new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);

        // Act & Assert
        var act = async () => await service.GetOrdersByCustomerAsync(7, CancellationToken.None);
        await act.Should().ThrowAsync<TimeoutException>()
            .WithMessage("*8 segundos*");
    }

    [Fact]
    public async Task GetOrdersByPartnerAsync_DelegatesToGetOrdersByCustomerAsync()
    {
        // Arrange
        var (service, sentRequests) = CreateServiceWithResponses(
            JsonResponse("[{\"id\": 20, \"name\": \"SO020\", \"date_order\": \"2026-11-12\", \"amount_total\": 75.0, \"state\": \"sale\", \"order_line\": [1]}]")
        );

        // Act
        var result = await service.GetOrdersByPartnerAsync(7);

        // Assert
        sentRequests.Should().HaveCount(1);
        result.Should().HaveCount(1);
        result[0].Id.Should().Be(20);
        result[0].CustomerId.Should().Be(7);
    }

    [Fact]
    public async Task CreateOrderAsync_PassesCancellationTokenToPostAsync()
    {
        // Arrange
        bool wasLinkedToProvidedToken = false;
        using var cts = new CancellationTokenSource();
        var expectedToken = cts.Token;

        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .Returns<HttpRequestMessage, CancellationToken>((req, ct) =>
            {
                if (req.RequestUri!.AbsolutePath.Contains("sale.order/create"))
                {
                    // Since HttpClient links the token internally with its Timeout token,
                    // cancelling expectedToken must cause ct.IsCancellationRequested to become true.
                    cts.Cancel();
                    wasLinkedToProvidedToken = ct.IsCancellationRequested;
                    return Task.FromResult(JsonResponse("[200]"));
                }
                return Task.FromResult(JsonResponse("true"));
            });

        var httpClient = new HttpClient(handlerMock.Object);
        var service = new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 1, Quantity = 1, UnitPrice = 50m }
            }
        };

        // Act
        try
        {
            await service.CreateOrderAsync(orderDto, expectedToken);
        }
        catch (OperationCanceledException)
        {
            // Expected if cancellation aborted downstream operations
        }

        // Assert
        wasLinkedToProvidedToken.Should().BeTrue("El CancellationToken debió propagarse a la llamada PostAsync");
    }

    [Fact]
    public async Task CreateOrderAsync_SendsExactBypassContextAndProcessesWizard()
    {
        // Arrange
        var capturedRequests = new List<(string Url, string Body)>();
        var responseQueue = new Queue<HttpResponseMessage>(new[]
        {
            // 1. sale.order/create
            JsonResponse("[105]"),
            // 2. sale.order/action_confirm
            JsonResponse("true"),
            // 3. stock.picking/search_read
            JsonResponse("[{\"id\": 99, \"state\": \"assigned\"}]"),
            // 4. stock.picking/action_assign
            JsonResponse("true"),
            // 5. stock.move/search_read
            JsonResponse("[{\"id\": 301, \"product_uom_qty\": 5.0}]"),
            // 6. stock.move/write
            JsonResponse("true"),
            // 7. stock.picking/button_validate -> returns backorder confirmation wizard
            JsonResponse("{\"type\": \"ir.actions.act_window\", \"res_model\": \"stock.backorder.confirmation\", \"res_id\": 777}"),
            // 8. stock.backorder.confirmation/process
            JsonResponse("true"),
            // 9. stock.picking/search_read (EnsurePickingDoneAsync)
            JsonResponse("[{\"id\": 99, \"state\": \"done\"}]"),
            // 10. sale.order/search_read
            JsonResponse("[{\"id\": 105, \"name\": \"SO105\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 250.0, \"order_line\": []}]")
        });

        var handlerMock = new Mock<HttpMessageHandler>();
        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .Returns<HttpRequestMessage, CancellationToken>(async (req, ct) =>
            {
                var body = req.Content != null ? await req.Content.ReadAsStringAsync(ct) : "";
                capturedRequests.Add((req.RequestUri?.AbsolutePath ?? "", body));
                if (responseQueue.Count > 0)
                {
                    return responseQueue.Dequeue();
                }
                return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent("[]") };
            });

        var httpClient = new HttpClient(handlerMock.Object);
        var service = new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 12, Quantity = 5, UnitPrice = 50m }
            }
        };

        // Act
        var result = await service.CreateOrderAsync(orderDto);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(105);

        // Inspect button_validate request
        var validateReq = capturedRequests.FirstOrDefault(r => r.Url == "/json/2/stock.picking/button_validate");
        validateReq.Url.Should().NotBeNullOrEmpty();
        using var validateDoc = JsonDocument.Parse(validateReq.Body);
        var validateCtx = validateDoc.RootElement.GetProperty("context");
        validateCtx.GetProperty("skip_immediate").GetBoolean().Should().BeTrue();
        validateCtx.GetProperty("skip_backorder").GetBoolean().Should().BeTrue();
        validateCtx.GetProperty("skip_sms").GetBoolean().Should().BeTrue();
        validateCtx.GetProperty("button_validate_picking_ids")[0].GetInt32().Should().Be(99);

        // Inspect stock.move/write request
        var moveWriteReq = capturedRequests.FirstOrDefault(r => r.Url == "/json/2/stock.move/write");
        moveWriteReq.Url.Should().NotBeNullOrEmpty();
        using var moveDoc = JsonDocument.Parse(moveWriteReq.Body);
        var moveVals = moveDoc.RootElement.GetProperty("vals");
        moveVals.GetProperty("quantity").GetDecimal().Should().Be(5.0m);
        moveVals.GetProperty("picked").GetBoolean().Should().BeTrue();

        // Inspect wizard process request
        var processReq = capturedRequests.FirstOrDefault(r => r.Url == "/json/2/stock.backorder.confirmation/process");
        processReq.Url.Should().NotBeNullOrEmpty();
        using var processDoc = JsonDocument.Parse(processReq.Body);
        processDoc.RootElement.GetProperty("ids")[0].GetInt32().Should().Be(777);
    }

    [Fact]
    public async Task CreateOrderAsync_WhenButtonValidateReturnsSmsWizard_ExecutesDontSendSmsAndCompletesOrder()
    {
        // Arrange
        var (service, sentRequests) = CreateServiceWithResponses(
            // 1. sale.order/create
            JsonResponse("[106]"),
            // 2. sale.order/action_confirm
            JsonResponse("true"),
            // 3. stock.picking/search_read
            JsonResponse("[{\"id\": 66, \"state\": \"assigned\"}]"),
            // 4. stock.picking/action_assign
            JsonResponse("true"),
            // 5. stock.move/search_read
            JsonResponse("[{\"id\": 401, \"product_uom_qty\": 1.0}]"),
            // 6. stock.move/write
            JsonResponse("true"),
            // 7. stock.picking/button_validate -> returns confirm.stock.sms wizard
            JsonResponse("{\"type\": \"ir.actions.act_window\", \"res_model\": \"confirm.stock.sms\", \"res_id\": 999}"),
            // 8. confirm.stock.sms/dont_send_sms
            JsonResponse("true"),
            // 9. stock.picking/search_read (EnsurePickingDoneAsync)
            JsonResponse("[{\"id\": 66, \"state\": \"done\"}]"),
            // 10. sale.order/search_read
            JsonResponse("[{\"id\": 106, \"name\": \"SO106\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 100.0, \"order_line\": []}]")
        );

        var orderDto = new CreateOrderDto
        {
            CustomerId = 7,
            Items = new List<CreateOrderItemDto>
            {
                new() { ProductId = 22, Quantity = 1, UnitPrice = 100m }
            }
        };

        // Act
        var result = await service.CreateOrderAsync(orderDto);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(106);

        var urls = sentRequests.Select(r => r.RequestUri?.AbsolutePath).ToList();
        urls.Should().Contain("/json/2/confirm.stock.sms/dont_send_sms");
    }

    [Fact]
    public async Task GetOrderByIdAsync_QueriesSaleOrderAndLines_MapsFieldsCorrectly()
    {
        // Arrange
        var capturedBodies = new List<string>();
        var (service, sentRequests) = CreateServiceWithResponses(
            // 1. sale.order/search_read
            JsonResponse("[{\"id\": 26, \"name\": \"SO026\", \"partner_id\": [7, \"Sebastián Andrade\"], \"date_order\": \"2026-11-13\", \"state\": \"sale\", \"amount_total\": 115.0, \"order_line\": [101, 102]}]"),
            // 2. sale.order.line/search_read
            JsonResponse("[{\"id\": 101, \"product_id\": [15, \"Laptop Dell XPS\"], \"name\": \"Laptop Dell\", \"product_uom_qty\": 2.0, \"price_unit\": 50.0, \"price_subtotal\": 100.0}, {\"id\": 102, \"product_id\": false, \"name\": \"Servicio de Entrega\", \"product_uom_qty\": 1.0, \"price_unit\": 15.0, \"price_subtotal\": 15.0}]")
        );

        // Act
        var result = await service.GetOrderByIdAsync(26);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(26);
        result.CustomerId.Should().Be(7);
        result.CustomerName.Should().Be("Sebastián Andrade");
        result.Status.Should().Be(OrderStatus.Confirmed);
        result.TotalAmount.Should().Be(115.0m);

        sentRequests.Should().HaveCount(2);
        sentRequests[0].RequestUri?.AbsolutePath.Should().EndWith("/json/2/sale.order/search_read");
        sentRequests[1].RequestUri?.AbsolutePath.Should().EndWith("/json/2/sale.order.line/search_read");

        result.Items.Should().HaveCount(2);

        // Item 1: tuple Many2One [15, "Laptop Dell XPS"]
        result.Items[0].Id.Should().Be(101);
        result.Items[0].ProductId.Should().Be(15);
        result.Items[0].ProductName.Should().Be("Laptop Dell XPS");
        result.Items[0].Quantity.Should().Be(2.0m);
        result.Items[0].UnitPrice.Should().Be(50.0m);
        result.Items[0].Subtotal.Should().Be(100.0m);

        // Item 2: fallback to name "Servicio de Entrega"
        result.Items[1].Id.Should().Be(102);
        result.Items[1].ProductId.Should().Be(0);
        result.Items[1].ProductName.Should().Be("Servicio de Entrega");
        result.Items[1].Quantity.Should().Be(1.0m);
        result.Items[1].UnitPrice.Should().Be(15.0m);
        result.Items[1].Subtotal.Should().Be(15.0m);
    }

    [Fact]
    public async Task GetOrdersByCustomerAsync_WithComplexOrMissingAmountTotal_MapsDefensivelyWithout500()
    {
        // Arrange: Odoo returns heterogeneous types for amount_total (e.g. float, string, boolean false, null)
        var (service, _) = CreateServiceWithResponses(
            JsonResponse("[{\"id\": 1, \"name\": \"SO001\", \"date_order\": \"2026-11-13\", \"amount_total\": \"120.50\", \"state\": \"sale\"}, {\"id\": 2, \"name\": \"SO002\", \"date_order\": false, \"amount_total\": false, \"state\": \"draft\"}, {\"id\": 3, \"name\": \"SO003\", \"date_order\": \"2026-11-13\", \"amount_total\": null, \"state\": \"sale\"}]")
        );

        // Act
        var result = await service.GetOrdersByCustomerAsync(7);

        // Assert
        result.Should().HaveCount(3);
        result[0].TotalAmount.Should().Be(120.50m);
        result[0].AmountTotal.Should().Be(120.50m);
        result[0].Status.Should().Be(OrderStatus.Confirmed);
        result[0].Items.Should().BeEmpty();

        result[1].TotalAmount.Should().Be(0m);
        result[1].AmountTotal.Should().Be(0m);
        result[1].Status.Should().Be(OrderStatus.Draft);
        result[1].Items.Should().BeEmpty();

        result[2].TotalAmount.Should().Be(0m);
        result[2].AmountTotal.Should().Be(0m);
        result[2].Status.Should().Be(OrderStatus.Confirmed);
        result[2].Items.Should().BeEmpty();
    }

    [Fact]
    public async Task GetOrderByIdAsync_WithHeterogeneousLineTypes_MapsAllFieldsDefensively()
    {
        // Arrange
        var (service, _) = CreateServiceWithResponses(
            // 1. sale.order
            JsonResponse("[{\"id\": 50, \"name\": \"SO050\", \"partner_id\": [7, \"Sebastián\"], \"date_order\": \"2026-11-13\", \"state\": \"sale\", \"amount_total\": 200.0, \"order_line\": [1, 2, 3]}]"),
            // 2. sale.order.line with various heterogeneous types (strings, null, false, single int product_id)
            JsonResponse("[" +
                "{\"id\": 1, \"product_id\": [42, \"Teclado RGB\"], \"name\": \"Teclado\", \"product_uom_qty\": \"3.0\", \"price_unit\": 45.0, \"price_subtotal\": 135.0}," +
                "{\"id\": 2, \"product_id\": 50, \"name\": \"Mouse Gamer\", \"product_uom_qty\": 2.0, \"price_unit\": null, \"price_subtotal\": false}," +
                "{\"id\": 3, \"product_id\": false, \"name\": false, \"product_uom_qty\": false, \"price_unit\": false, \"price_subtotal\": false}" +
            "]")
        );

        // Act
        var result = await service.GetOrderByIdAsync(50);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(50);
        result.TotalAmount.Should().Be(200.0m);
        result.AmountTotal.Should().Be(200.0m);
        result.Items.Should().HaveCount(3);

        // Line 1: string quantity "3.0" parsed safely via Convert.ToDecimal
        result.Items[0].Id.Should().Be(1);
        result.Items[0].ProductId.Should().Be(42);
        result.Items[0].ProductName.Should().Be("Teclado RGB");
        result.Items[0].Quantity.Should().Be(3.0m);
        result.Items[0].UnitPrice.Should().Be(45.0m);
        result.Items[0].Subtotal.Should().Be(135.0m);

        // Line 2: single int product_id, fallback to name, price_unit null fallback to 0
        result.Items[1].Id.Should().Be(2);
        result.Items[1].ProductId.Should().Be(50);
        result.Items[1].ProductName.Should().Be("Mouse Gamer");
        result.Items[1].Quantity.Should().Be(2.0m);
        result.Items[1].UnitPrice.Should().Be(0m);
        result.Items[1].Subtotal.Should().Be(0m);

        // Line 3: false product_id and false name -> fallback to "Producto", 0 quantity and 0 price
        result.Items[2].Id.Should().Be(3);
        result.Items[2].ProductId.Should().Be(0);
        result.Items[2].ProductName.Should().Be("Producto");
        result.Items[2].Quantity.Should().Be(0m);
        result.Items[2].UnitPrice.Should().Be(0m);
        result.Items[2].Subtotal.Should().Be(0m);
    }
}
