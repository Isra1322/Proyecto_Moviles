namespace ECommerce.Infrastructure.Odoo.Models;

using System.Text.Json.Serialization;

public class OdooRpcRequest
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; } = "2.0";

    [JsonPropertyName("method")]
    public string Method { get; set; } = "call";

    [JsonPropertyName("params")]
    public OdooRpcParams Params { get; set; } = new();

    [JsonPropertyName("id")]
    public int Id { get; set; } = Random.Shared.Next(1, 100000);

    public static OdooRpcRequest Create(string service, string method, params object?[] args)
    {
        return new OdooRpcRequest
        {
            Params = new OdooRpcParams
            {
                Service = service,
                Method = method,
                Args = args.ToList()
            }
        };
    }
}

public class OdooRpcParams
{
    [JsonPropertyName("service")]
    public string Service { get; set; } = string.Empty;

    [JsonPropertyName("method")]
    public string Method { get; set; } = string.Empty;

    [JsonPropertyName("args")]
    public List<object?> Args { get; set; } = new();
}

