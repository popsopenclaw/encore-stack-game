using Encore.Application.Abstractions;

namespace Encore.Api.Services;

public class LobbyCleanupHostedService(IServiceScopeFactory scopeFactory, IConfiguration configuration, ILogger<LobbyCleanupHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var staleHours = configuration.GetValue<int?>("Lobby:StaleHours") ?? 24;
        if (staleHours < 1) staleHours = 1;

        var intervalMinutes = configuration.GetValue<int?>("Lobby:CleanupIntervalMinutes") ?? 15;
        if (intervalMinutes < 1) intervalMinutes = 1;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var repo = scope.ServiceProvider.GetRequiredService<ILobbyRepository>();
                var threshold = DateTimeOffset.UtcNow.AddHours(-staleHours);
                var removed = await repo.RemoveStaleAsync(threshold, stoppingToken);
                if (removed > 0)
                    logger.LogInformation("Lobby cleanup removed {Count} stale lobbies", removed);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Lobby cleanup iteration failed");
            }

            await Task.Delay(TimeSpan.FromMinutes(intervalMinutes), stoppingToken);
        }
    }
}
