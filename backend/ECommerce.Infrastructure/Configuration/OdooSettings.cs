namespace ECommerce.Infrastructure.Configuration;

public class OdooSettings
{
    public const string SectionName = "OdooSettings";

    public string Url { get; set; } = "http://localhost:8069";
    public string Database { get; set; } = "odoo20_integradores";
    public string ApiKey { get; set; } = string.Empty;
    public int TimeoutSeconds { get; set; } = 30;
}
