namespace ECommerce.Tests.Controllers;

using System.Security.Claims;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using ECommerce.Application.Common.Models;
using ECommerce.Application.DTOs.Addresses;
using ECommerce.Application.Interfaces;
using ECommerce.WebApi.Controllers;

public class AddressesControllerTests
{
    private readonly Mock<IAddressService> _serviceMock;
    private readonly Mock<ILogger<AddressesController>> _loggerMock;
    private readonly AddressesController _controller;

    public AddressesControllerTests()
    {
        _serviceMock = new Mock<IAddressService>();
        _loggerMock = new Mock<ILogger<AddressesController>>();
        _controller = new AddressesController(_serviceMock.Object, _loggerMock.Object);

        var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "42"),
            new Claim(ClaimTypes.Email, "cliente@test.com")
        }, "TestAuth"));

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };
    }

    [Fact]
    public async Task GetAll_ReturnsAddressesForAuthenticatedUser()
    {
        var sampleAddresses = new List<AddressDto>
        {
            new()
            {
                Id = Guid.NewGuid(),
                PartnerId = 42,
                Title = "Casa",
                Street = "Av. Amazonas y Naciones Unidas",
                City = "Quito",
                StateOrProvince = "Pichincha",
                Phone = "0991234567",
                IsDefault = true,
                CreatedAt = DateTime.UtcNow
            }
        };

        _serviceMock.Setup(s => s.GetByPartnerIdAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(sampleAddresses);

        var result = await _controller.GetAll(CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        var apiResponse = okResult.Value as ApiResponse<List<AddressDto>>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data.Should().HaveCount(1);
        apiResponse.Data!.First().Title.Should().Be("Casa");
    }

    [Fact]
    public async Task GetById_WhenExists_ReturnsOk()
    {
        var addressId = Guid.NewGuid();
        var addressDto = new AddressDto
        {
            Id = addressId,
            PartnerId = 42,
            Title = "Oficina",
            Street = "Calle 10 y Av. 6",
            City = "Guayaquil",
            Phone = "0987654321",
            IsDefault = false
        };

        _serviceMock.Setup(s => s.GetByIdAsync(addressId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(addressDto);

        var result = await _controller.GetById(addressId, CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        var apiResponse = okResult.Value as ApiResponse<AddressDto>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Id.Should().Be(addressId);
    }

    [Fact]
    public async Task GetById_WhenNotFound_Returns404NotFound()
    {
        var addressId = Guid.NewGuid();
        _serviceMock.Setup(s => s.GetByIdAsync(addressId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AddressDto?)null);

        var result = await _controller.GetById(addressId, CancellationToken.None);

        result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task Create_ValidAddress_Returns201Created()
    {
        var dto = new CreateAddressDto
        {
            Title = "Casa de campo",
            Street = "Vía a la costa km 15",
            City = "Santa Elena",
            Phone = "0998877665",
            IsDefault = true
        };

        var created = new AddressDto
        {
            Id = Guid.NewGuid(),
            PartnerId = 42,
            Title = dto.Title,
            Street = dto.Street,
            City = dto.City,
            Phone = dto.Phone,
            IsDefault = true,
            CreatedAt = DateTime.UtcNow
        };

        _serviceMock.Setup(s => s.CreateAsync(42, dto, It.IsAny<CancellationToken>()))
            .ReturnsAsync(created);

        var result = await _controller.Create(dto, CancellationToken.None);

        result.Should().BeOfType<ObjectResult>();
        var objResult = (ObjectResult)result;
        objResult.StatusCode.Should().Be(StatusCodes.Status201Created);

        var apiResponse = objResult.Value as ApiResponse<AddressDto>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Title.Should().Be("Casa de campo");
    }

    [Fact]
    public async Task Create_NullBody_Returns400BadRequest()
    {
        var result = await _controller.Create(null, CancellationToken.None);

        result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task Update_ExistingAddress_Returns200Ok()
    {
        var addressId = Guid.NewGuid();
        var updateDto = new UpdateAddressDto
        {
            Title = "Casa Nueva",
            Street = "Av. Simón Bolívar",
            City = "Quito",
            Phone = "0991122334"
        };

        var updated = new AddressDto
        {
            Id = addressId,
            PartnerId = 42,
            Title = updateDto.Title,
            Street = updateDto.Street,
            City = updateDto.City,
            Phone = updateDto.Phone,
            IsDefault = true
        };

        _serviceMock.Setup(s => s.UpdateAsync(addressId, 42, updateDto, It.IsAny<CancellationToken>()))
            .ReturnsAsync(updated);

        var result = await _controller.Update(addressId, updateDto, CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        var apiResponse = okResult.Value as ApiResponse<AddressDto>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Title.Should().Be("Casa Nueva");
    }

    [Fact]
    public async Task Update_NotFound_Returns404NotFound()
    {
        var addressId = Guid.NewGuid();
        var updateDto = new UpdateAddressDto
        {
            Title = "Casa Nueva",
            Street = "Av. Simón Bolívar",
            City = "Quito",
            Phone = "0991122334"
        };

        _serviceMock.Setup(s => s.UpdateAsync(addressId, 42, updateDto, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AddressDto?)null);

        var result = await _controller.Update(addressId, updateDto, CancellationToken.None);

        result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task Delete_ExistingAddress_Returns200Ok()
    {
        var addressId = Guid.NewGuid();
        _serviceMock.Setup(s => s.DeleteAsync(addressId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var result = await _controller.Delete(addressId, CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task Delete_NotFound_Returns404NotFound()
    {
        var addressId = Guid.NewGuid();
        _serviceMock.Setup(s => s.DeleteAsync(addressId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var result = await _controller.Delete(addressId, CancellationToken.None);

        result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task SetDefault_ExistingAddress_Returns200Ok()
    {
        var addressId = Guid.NewGuid();
        var addressDto = new AddressDto
        {
            Id = addressId,
            PartnerId = 42,
            Title = "Casa Principal",
            Street = "Calle Central 123",
            City = "Cuenca",
            Phone = "0995556667",
            IsDefault = true
        };

        _serviceMock.Setup(s => s.SetDefaultAsync(addressId, 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(addressDto);

        var result = await _controller.SetDefault(addressId, CancellationToken.None);

        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        var apiResponse = okResult.Value as ApiResponse<AddressDto>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.IsDefault.Should().BeTrue();
    }
}
