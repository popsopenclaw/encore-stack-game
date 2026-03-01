using System.Text.Json;
using Encore.Domain;
using Microsoft.Extensions.Hosting;

namespace Encore.Infrastructure.Services;

public class BoardTemplateProvider(IHostEnvironment env)
{
    private readonly Dictionary<string, BoardTemplate> _cache = new(StringComparer.OrdinalIgnoreCase);

    public BoardTemplate GetEncoreTemplate()
    {
        const string key = "encore-default";
        if (_cache.TryGetValue(key, out var tpl)) return tpl;

        var candidates = new[]
        {
            Path.Combine(env.ContentRootPath, "Domain", "Templates", "encore-default.json"),
            Path.Combine(env.ContentRootPath, "..", "Encore.Domain", "Templates", "encore-default.json"),
            Path.Combine(AppContext.BaseDirectory, "Domain", "Templates", "encore-default.json")
        };

        var path = candidates.FirstOrDefault(File.Exists)
                   ?? throw new FileNotFoundException("Could not locate encore-default.json template", string.Join(" | ", candidates));

        var json = File.ReadAllText(path);
        tpl = JsonSerializer.Deserialize<BoardTemplate>(json) ?? throw new InvalidOperationException("Invalid board template json");
        _cache[key] = tpl;
        return tpl;
    }
}
