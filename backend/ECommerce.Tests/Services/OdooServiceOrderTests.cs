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
            // 5. stock.picking/action_set_quantities_to_reservation
            JsonResponse("true"),
            // 6. stock.picking/button_validate
            JsonResponse("true"),
            // 7. sale.order/search_read (fetch order)
            JsonResponse("[{\"id\": 101, \"name\": \"SO101\", \"partner_id\": [7, \"Cliente\"], \"date_order\": \"2026-11-12\", \"state\": \"sale\", \"amount_total\": 100.0, \"order_line\": [1]}]"),
            // 8. sale.order.line/search_read (fetch order lines)
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
        urls.Should().Contain("/json/2/stock.picking/action_set_quantities_to_reservation");
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
            // 5. stock.picking/action_set_quantities_to_reservation
            JsonResponse("true"),
            // 6. stock.picking/button_validate -> returns immediate transfer wizard action (ir.actions.act_window)
            JsonResponse("{\"type\": \"ir.actions.act_window\", \"res_model\": \"stock.immediate.transfer\", \"res_id\": 88, \"context\": {\"button_validate_picking_ids\": [55]}}"),
            // 7. stock.immediate.transfer/process
            JsonResponse("true"),
            // 8. stock.picking/search_read (ensure picking state)
            JsonResponse("[{\"id\": 55, \"state\": \"done\"}]"),
            // 9. sale.order/search_read
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
            // 5. stock.picking/action_set_quantities_to_reservation
            JsonResponse("true"),
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
}
