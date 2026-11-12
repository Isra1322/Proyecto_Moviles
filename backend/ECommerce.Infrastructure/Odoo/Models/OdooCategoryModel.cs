namespace ECommerce.Infrastructure.Odoo.Models;

using System.Text.Json;
using System.Text.Json.Serialization;

public class OdooCategoryModel
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("parent_id")]
    public JsonElement ParentId { get; set; }
}

