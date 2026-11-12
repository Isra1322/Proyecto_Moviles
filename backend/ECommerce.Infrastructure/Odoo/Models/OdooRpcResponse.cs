namespace ECommerce.Infrastructure.Odoo.Models;

using System.Text.Json.Serialization;

public class OdooRpcResponse<T>
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; } = "2.0";

    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("result")]
    public T? Result { get; set; }

    [JsonPropertyName("error")]
    public OdooRpcError? Error { get; set; }
}

public class OdooRpcError
{
    [JsonPropertyName("code")]
    public int Code { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("data")]
    public OdooRpcErrorData? Data { get; set; }
}

public class OdooRpcErrorData
{
    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("debug")]
    public string? Debug { get; set; }
}

