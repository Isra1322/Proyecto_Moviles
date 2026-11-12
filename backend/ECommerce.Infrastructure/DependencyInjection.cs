namespace ECommerce.Infrastructure;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using ECommerce.Application.Interfaces;
using ECommerce.Infrastructure.Configuration;
using ECommerce.Infrastructure.Odoo.Services;
using ECommerce.Infrastructure.Services;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<OdooSettings>(configuration.GetSection(OdooSettings.SectionName));

        services.AddSingleton<ICustomerCredentialStore, CustomerCredentialStore>();
        services.AddScoped<IJwtTokenService, JwtTokenService>();

        services.AddHttpClient<IOdooService, OdooService>((serviceProvider, client) =>
        {
            var settings = serviceProvider.GetRequiredService<IOptions<OdooSettings>>().Value;
            if (!string.IsNullOrWhiteSpace(settings.Url))
            {
                client.BaseAddress = new Uri(settings.Url.TrimEnd('/') + "/");
            }
            if (!string.IsNullOrWhiteSpace(settings.ApiKey))
            {
                client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", settings.ApiKey);
            }
            if (!string.IsNullOrWhiteSpace(settings.Database))
            {
                client.DefaultRequestHeaders.TryAddWithoutValidation("X-Odoo-Database", settings.Database);
            }
            client.Timeout = TimeSpan.FromSeconds(settings.TimeoutSeconds > 0 ? settings.TimeoutSeconds : 30);
        });

        return services;
    }
}
