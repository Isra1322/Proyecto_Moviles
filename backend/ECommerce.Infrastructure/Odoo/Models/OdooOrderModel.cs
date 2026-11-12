namespace ECommerce.Infrastructure.Odoo.Models;

using System.Text.Json;
using System.Text.Json.Serialization;

public class OdooOrderModel
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("partner_id")]
    public JsonElement PartnerId { get; set; }

    [JsonPropertyName("date_order")]
    public JsonElement DateOrder { get; set; }

    [JsonPropertyName("state")]
    public string State { get; set; } = string.Empty;

    [JsonPropertyName("amount_total")]
    public decimal AmountTotal { get; set; }

    [JsonPropertyName("order_line")]
    public JsonElement OrderLine { get; set; }
}

public class OdooOrderLineModel
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("order_id")]
    public JsonElement OrderId { get; set; }

    [JsonPropertyName("product_id")]
    public JsonElement ProductId { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("product_uom_qty")]
    public decimal ProductUomQty { get; set; }

    [JsonPropertyName("price_unit")]
    public decimal PriceUnit { get; set; }

    [JsonPropertyName("price_subtotal")]
    public decimal PriceSubtotal { get; set; }
}

