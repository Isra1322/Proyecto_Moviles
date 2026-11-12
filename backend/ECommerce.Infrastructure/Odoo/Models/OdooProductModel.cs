namespace ECommerce.Infrastructure.Odoo.Models;

using System.Text.Json;
using System.Text.Json.Serialization;

public class OdooProductModel
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description_sale")]
    public JsonElement DescriptionSale { get; set; }

    [JsonPropertyName("list_price")]
    public decimal ListPrice { get; set; }

    [JsonPropertyName("qty_available")]
    public decimal QtyAvailable { get; set; }

    [JsonPropertyName("categ_id")]
    public JsonElement CategId { get; set; }

    [JsonPropertyName("barcode")]
    public JsonElement Barcode { get; set; }

    [JsonPropertyName("default_code")]
    public JsonElement DefaultCode { get; set; }

    [JsonPropertyName("image_128")]
    public object? Image128 { get; set; }
}

