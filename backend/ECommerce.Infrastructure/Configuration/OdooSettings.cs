namespace ECommerce.Infrastructure.Configuration;

public class OdooSettings
{
    public const string SectionName = "OdooSettings";

    public string Url { get; set; } = "http://127.0.0.1:8069";
    public string Database { get; set; } = "odoo20_integradores";
    public string ApiKey { get; set; } = string.Empty;
    public int TimeoutSeconds { get; set; } = 30;
}
