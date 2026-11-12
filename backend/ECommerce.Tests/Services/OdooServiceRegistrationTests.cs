namespace ECommerce.Tests.Services;

using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using Moq.Protected;
using ECommerce.Application.DTOs.Auth;
using ECommerce.Application.Interfaces;
using ECommerce.Infrastructure.Configuration;
using ECommerce.Infrastructure.Odoo.Services;
using ECommerce.Infrastructure.Services;

public class OdooServiceRegistrationTests
{
    private readonly Mock<IJwtTokenService> _jwtTokenServiceMock;
    private readonly Mock<ICustomerCredentialStore> _credentialStoreMock;
    private readonly Mock<ILogger<OdooService>> _loggerMock;
    private readonly IOptions<OdooSettings> _options;

    public OdooServiceRegistrationTests()
    {
        _jwtTokenServiceMock = new Mock<IJwtTokenService>();
        _credentialStoreMock = new Mock<ICustomerCredentialStore>();
        _loggerMock = new Mock<ILogger<OdooService>>();
        _options = Options.Create(new OdooSettings
        {
            Url = "http://mock-odoo:8069",
            Database = "test_db",
            ApiKey = "test_key",
            TimeoutSeconds = 5
        });

        _jwtTokenServiceMock
            .Setup(j => j.GenerateToken(It.IsAny<int>(), It.IsAny<string>(), It.IsAny<string>()))
            .Returns("fake.jwt.token");
    }

    private OdooService CreateServiceWithHttpResponses(Queue<HttpResponseMessage> responses)
    {
        var handlerMock = new Mock<HttpMessageHandler>();

        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(() => responses.Dequeue());

        var httpClient = new HttpClient(handlerMock.Object);
        return new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task RegisterCustomerAsync_WhenSearchReturnsEmptyArray_ProceedsToCreateAndSucceeds()
    {
        // 1. search_read returns []
        // 2. create returns [42]
        var responses = new Queue<HttpResponseMessage>();
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("[]")
        });
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("[42]")
        });

        var service = CreateServiceWithHttpResponses(responses);
        var request = new RegisterRequestDto
        {
            Name = "Carlos Mendoza",
            Email = "carlos@nuevo.com",
            Password = "Password123"
        };

        var result = await service.RegisterCustomerAsync(request);

        result.Success.Should().BeTrue();
        result.PartnerId.Should().Be(42);
        result.Email.Should().Be("carlos@nuevo.com");
    }

    [Fact]
    public async Task RegisterCustomerAsync_WhenSearchReturnsWrappedEmptyResult_ProceedsToCreateAndSucceeds()
    {
        // 1. search_read returns {"result": []}
        // 2. create returns {"result": [55]}
        var responses = new Queue<HttpResponseMessage>();
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("{\"result\": []}")
        });
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("{\"result\": [55]}")
        });

        var service = CreateServiceWithHttpResponses(responses);
        var request = new RegisterRequestDto
        {
            Name = "Laura Gomez",
            Email = "laura@nuevo.com",
            Password = "Password123"
        };

        var result = await service.RegisterCustomerAsync(request);

        result.Success.Should().BeTrue();
        result.PartnerId.Should().Be(55);
    }

    [Fact]
    public async Task RegisterCustomerAsync_WhenPartnerExistsWithMatchingEmail_ReturnsDuplicateError()
    {
        // 1. search_read returns matching partner
        var responses = new Queue<HttpResponseMessage>();
        var existingPartnerJson = JsonSerializer.Serialize(new[]
        {
            new { id = 10, name = "Carlos Ya Existe", email = "carlos@duplicado.com" }
        });
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(existingPartnerJson)
        });

        var service = CreateServiceWithHttpResponses(responses);
        var request = new RegisterRequestDto
        {
            Name = "Carlos Duplicado",
            Email = "carlos@duplicado.com",
            Password = "Password123"
        };

        var result = await service.RegisterCustomerAsync(request);

        result.Success.Should().BeFalse();
        result.Message.Should().Be("Ya existe un contacto registrado con este correo en Odoo.");
    }

    [Fact]
    public async Task RegisterCustomerAsync_WhenSearchReturnsPartnerWithFalseEmail_DoesNotBlockAndProceedsToCreate()
    {
        // 1. search_read returns partner where email is false or does not match
        // 2. create returns [77]
        var responses = new Queue<HttpResponseMessage>();
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("[{\"id\": 1, \"name\": \"Administrator\", \"email\": false}]")
        });
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("[77]")
        });

        var service = CreateServiceWithHttpResponses(responses);
        var request = new RegisterRequestDto
        {
            Name = "Nuevo Usuario",
            Email = "nuevo@inventado.com",
            Password = "Password123"
        };

        var result = await service.RegisterCustomerAsync(request);

        result.Success.Should().BeTrue();
        result.PartnerId.Should().Be(77);
    }

    [Fact]
    public async Task RegisterCustomerAsync_WhenSearchThrowsException_DoesNotReturnDuplicateErrorAndAttemptsCreate()
    {
        // 1. search_read returns 500 error
        // 2. create returns [88]
        var responses = new Queue<HttpResponseMessage>();
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.InternalServerError)
        {
            Content = new StringContent("Server Error")
        });
        responses.Enqueue(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("[88]")
        });

        var service = CreateServiceWithHttpResponses(responses);
        var request = new RegisterRequestDto
        {
            Name = "Usuario Prueba",
            Email = "prueba@correo.com",
            Password = "Password123"
        };

        var result = await service.RegisterCustomerAsync(request);

        result.Success.Should().BeTrue();
        result.PartnerId.Should().Be(88);
    }

    [Fact]
    public async Task RegisterCustomerAsync_SendsCorrectValsListPayloadToOdooCreate()
    {
        string? capturedCreateBody = null;
        string? capturedCreatePath = null;
        var handlerMock = new Mock<HttpMessageHandler>();

        handlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .Returns<HttpRequestMessage, CancellationToken>(async (req, ct) =>
            {
                if (req.RequestUri!.AbsolutePath.Contains("search_read"))
                {
                    return new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new StringContent("[]")
                    };
                }

                if (req.RequestUri!.AbsolutePath.Contains("create"))
                {
                    capturedCreatePath = req.RequestUri.AbsolutePath;
                    if (req.Content != null)
                    {
                        capturedCreateBody = await req.Content.ReadAsStringAsync(ct);
                    }
                    return new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new StringContent("[99]")
                    };
                }

                return new HttpResponseMessage(HttpStatusCode.NotFound);
            });

        var httpClient = new HttpClient(handlerMock.Object);
        var service = new OdooService(httpClient, _options, _jwtTokenServiceMock.Object, _credentialStoreMock.Object, _loggerMock.Object);

        var request = new RegisterRequestDto
        {
            Name = " Maria Lopez ",
            Email = " maria@example.com ",
            Password = "SecurePassword123",
            Phone = null
        };

        var result = await service.RegisterCustomerAsync(request);

        result.Success.Should().BeTrue();
        result.PartnerId.Should().Be(99);
        capturedCreatePath.Should().NotBeNull();
        capturedCreatePath.Should().EndWith("/json/2/res.partner/create");

        capturedCreateBody.Should().NotBeNull();
        using var jsonDoc = JsonDocument.Parse(capturedCreateBody!);
        var root = jsonDoc.RootElement;

        root.TryGetProperty("vals_list", out var valsListProp).Should().BeTrue();
        valsListProp.ValueKind.Should().Be(JsonValueKind.Array);
        valsListProp.GetArrayLength().Should().Be(1);

        var partnerVals = valsListProp[0];
        partnerVals.GetProperty("name").GetString().Should().Be("Maria Lopez");
        partnerVals.GetProperty("email").GetString().Should().Be("maria@example.com");
        partnerVals.GetProperty("phone").GetString().Should().Be(string.Empty);
        partnerVals.GetProperty("customer_rank").GetInt32().Should().Be(1);
        partnerVals.TryGetProperty("active", out _).Should().BeFalse();
    }
}
