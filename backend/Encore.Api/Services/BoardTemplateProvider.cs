using System.Text.Json;
using Encore.Api.Domain;

namespace Encore.Api.Services;

public class BoardTemplateProvider(IHostEnvironment env)
{
    private readonly Dictionary<string, BoardTemplate> _cache = new(StringComparer.OrdinalIgnoreCase);

    public BoardTemplate GetEncoreTemplate()
    {
        const string key = "encore-default";
        if (_cache.TryGetValue(key, out var tpl)) return tpl;

        var path = Path.Combine(env.ContentRootPath, "Domain", "Templates", "encore-default.json");
        var json = File.ReadAllText(path);
        tpl = JsonSerializer.Deserialize<BoardTemplate>(json) ?? throw new InvalidOperationException("Invalid board template json");
        _cache[key] = tpl;
        return tpl;
    }
}
