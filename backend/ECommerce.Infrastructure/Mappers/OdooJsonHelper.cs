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
            var id = element[0].GetInt32();
            var name = element[1].GetString() ?? string.Empty;
            return (id, name);
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
        return list;
    }
}

