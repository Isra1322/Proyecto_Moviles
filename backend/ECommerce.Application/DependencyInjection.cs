namespace ECommerce.Application;

using Microsoft.Extensions.DependencyInjection;
using ECommerce.Application.UseCases.Auth;
using ECommerce.Application.UseCases.Categories;
using ECommerce.Application.UseCases.Orders;
using ECommerce.Application.UseCases.Products;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<LoginUseCase>();
        services.AddScoped<RegisterUseCase>();
        services.AddScoped<GetProductsUseCase>();
        services.AddScoped<GetProductByIdUseCase>();
        services.AddScoped<GetCategoriesUseCase>();
        services.AddScoped<CreateOrderUseCase>();
        services.AddScoped<GetOrdersUseCase>();
        services.AddScoped<GetOrderByIdUseCase>();

        return services;
    }
}
