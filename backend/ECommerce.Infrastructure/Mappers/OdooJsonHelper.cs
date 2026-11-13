namespace ECommerce.Infrastructure.Mappers;

using System.Text.Json;

public static class OdooJsonHelper
{
    public static string? GetStringOrNull(JsonElement element)
    {
        if (element.ValueKind == JsonValueKind.String)
        {
            var str = element.GetString();
            return string.IsNullOrWhiteSpace(str) || str.Equals("false", StringComparison.OrdinalIgnoreCase)
                ? null
                : str;
        }

        if (element.ValueKind == JsonValueKind.Object)
        {
            if (element.TryGetProperty("content", out var contentProp) && contentProp.ValueKind == JsonValueKind.String)
            {
                var content = contentProp.GetString();
                return string.IsNullOrWhiteSpace(content) || content.Equals("false", StringComparison.OrdinalIgnoreCase)
                    ? null
                    : content;
            }

            if (element.TryGetProperty("image", out var imageProp) && imageProp.ValueKind == JsonValueKind.String)
            {
                var image = imageProp.GetString();
                return string.IsNullOrWhiteSpace(image) || image.Equals("false", StringComparison.OrdinalIgnoreCase)
                    ? null
                    : image;
            }
        }

        return null;
    }

    public static string? GetStringOrNull(object? value)
    {
        if (value is null)
        {
            return null;
        }

        if (value is JsonElement element)
        {
            return GetStringOrNull(element);
        }

        if (value is string str)
        {
            return string.IsNullOrWhiteSpace(str) || str.Equals("false", StringComparison.OrdinalIgnoreCase)
                ? null
                : str;
        }

        if (value is bool)
        {
            return null;
        }

        return value.ToString();
    }

    public static (int Id, string Name)? GetMany2One(JsonElement element)
    {
        if (element.ValueKind == JsonValueKind.Array && element.GetArrayLength() >= 2)
        {
            int id = 0;
            if (element[0].ValueKind == JsonValueKind.Number && element[0].TryGetInt32(out var parsedId))
            {
                id = parsedId;
            }
            string name = element[1].ValueKind == JsonValueKind.String ? element[1].GetString() ?? string.Empty : string.Empty;
            return (id, name);
        }
        else if (element.ValueKind == JsonValueKind.Number && element.TryGetInt32(out var parsedId))
        {
            return (parsedId, string.Empty);
        }
        return null;
    }

    public static List<int> GetIntList(JsonElement element)
    {
        var list = new List<int>();
        if (element.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in element.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.Number && item.TryGetInt32(out var val))
                {
                    list.Add(val);
                }
            }
        }
        else if (element.ValueKind == JsonValueKind.Number && element.TryGetInt32(out var singleVal))
        {
            list.Add(singleVal);
        }
        return list;
    }

    public static decimal SafeToDecimal(JsonElement element, decimal fallback = 0m)
    {
        try
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.Number:
                    if (element.TryGetDecimal(out var dec)) return dec;
                    if (element.TryGetDouble(out var dbl)) return Convert.ToDecimal(dbl);
                    if (element.TryGetInt64(out var l)) return Convert.ToDecimal(l);
                    return fallback;
                case JsonValueKind.String:
                    var str = element.GetString();
                    if (string.IsNullOrWhiteSpace(str) || str.Equals("false", StringComparison.OrdinalIgnoreCase))
                        return fallback;
                    if (decimal.TryParse(str, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var parsedInv))
                        return parsedInv;
                    if (decimal.TryParse(str, out var parsedLocal))
                        return parsedLocal;
                    return Convert.ToDecimal(str, System.Globalization.CultureInfo.InvariantCulture);
                case JsonValueKind.True:
                    return 1m;
                case JsonValueKind.False:
                case JsonValueKind.Null:
                case JsonValueKind.Undefined:
                default:
                    return fallback;
            }
        }
        catch
        {
            return fallback;
        }
    }

    public static decimal SafeToDecimal(object? value, decimal fallback = 0m)
    {
        if (value is null) return fallback;
        if (value is JsonElement el) return SafeToDecimal(el, fallback);
        try
        {
            return Convert.ToDecimal(value, System.Globalization.CultureInfo.InvariantCulture);
        }
        catch
        {
            return fallback;
        }
    }

    public static (int Id, string ProductName) ExtractProductIdAndName(JsonElement productIdElement, string? fallbackName = null)
    {
        int productId = 0;
        string? productName = null;

        try
        {
            if (productIdElement.ValueKind == JsonValueKind.Array && productIdElement.GetArrayLength() > 0)
            {
                if (productIdElement[0].ValueKind == JsonValueKind.Number && productIdElement[0].TryGetInt32(out var id))
                {
                    productId = id;
                }
                if (productIdElement.GetArrayLength() > 1 && productIdElement[1].ValueKind == JsonValueKind.String)
                {
                    productName = productIdElement[1].GetString();
                }
            }
            else if (productIdElement.ValueKind == JsonValueKind.Number && productIdElement.TryGetInt32(out var id))
            {
                productId = id;
            }
        }
        catch
        {
            // Fallback defensivo
        }

        if (string.IsNullOrWhiteSpace(productName))
        {
            if (!string.IsNullOrWhiteSpace(fallbackName) && !fallbackName.Equals("false", StringComparison.OrdinalIgnoreCase))
            {
                productName = fallbackName;
            }
            else
            {
                productName = productId > 0 ? $"Producto #{productId}" : "Producto";
            }
        }

        return (productId, productName);
    }
}

