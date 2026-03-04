using Encore.Api.IntegrationTests.Fakes;
using Encore.Application.Auth;
using Encore.Application.Gameplay;
using Encore.Application.Lobby;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Encore.Api.IntegrationTests;

public class ApiWebFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = "Test";
                options.DefaultChallengeScheme = "Test";
            }).AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", _ => { });

            services.AddSingleton<FakeAuthUseCase>();
            services.AddSingleton<FakeGameplayUseCase>();
            services.AddSingleton<FakeLobbyUseCase>();

            services.AddSingleton<IAuthUseCase>(sp => sp.GetRequiredService<FakeAuthUseCase>());
            services.AddSingleton<IGameplayUseCase>(sp => sp.GetRequiredService<FakeGameplayUseCase>());
            services.AddSingleton<ILobbyUseCase>(sp => sp.GetRequiredService<FakeLobbyUseCase>());
        });
    }
}
