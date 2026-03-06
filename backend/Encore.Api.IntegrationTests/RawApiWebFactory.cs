using System.Collections.Concurrent;
using Encore.Api.IntegrationTests.Fakes;
using Encore.Application.Auth;
using Encore.Application.Gameplay;
using Encore.Application.Lobby;
using Encore.Application.Profile;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Moq;
using StackExchange.Redis;

namespace Encore.Api.IntegrationTests;

public class RawApiWebFactory : WebApplicationFactory<Program>
{
    private static readonly ConcurrentDictionary<string, string> RedisStore = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<IConnectionMultiplexer>();
            services.RemoveAll<IHostedService>();
            services.AddSingleton(CreateMockMultiplexer());

            services.AddSingleton<FakeAuthUseCase>();
            services.AddSingleton<FakeGameplayUseCase>();
            services.AddSingleton<FakeLobbyUseCase>();
            services.AddSingleton<FakeProfileUseCase>();

            services.AddSingleton<IAuthUseCase>(sp => sp.GetRequiredService<FakeAuthUseCase>());
            services.AddSingleton<IGameplayUseCase>(sp => sp.GetRequiredService<FakeGameplayUseCase>());
            services.AddSingleton<ILobbyUseCase>(sp => sp.GetRequiredService<FakeLobbyUseCase>());
            services.AddSingleton<IProfileUseCase>(sp => sp.GetRequiredService<FakeProfileUseCase>());
        });
    }

    private static IConnectionMultiplexer CreateMockMultiplexer()
    {
        var db = new Mock<IDatabase>();
        db.Setup(x => x.StringGetAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()))
            .ReturnsAsync((RedisKey key, CommandFlags _) =>
            {
                return RedisStore.TryGetValue(key!, out var value) ? (RedisValue)value : RedisValue.Null;
            });

        db.Setup(x => x.StringSetAsync(It.IsAny<RedisKey>(), It.IsAny<RedisValue>(), It.IsAny<TimeSpan?>(), It.IsAny<When>(), It.IsAny<CommandFlags>()))
            .ReturnsAsync((RedisKey key, RedisValue value, TimeSpan? _, When __, CommandFlags ___) =>
            {
                RedisStore[key!] = value.ToString();
                return true;
            });

        var mux = new Mock<IConnectionMultiplexer>();
        mux.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>())).Returns(db.Object);
        return mux.Object;
    }
}
