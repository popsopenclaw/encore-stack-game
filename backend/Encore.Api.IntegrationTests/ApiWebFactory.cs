using Encore.Api.IntegrationTests.Fakes;
using Encore.Application.Auth;
using Encore.Application.Gameplay;
using Encore.Application.Lobby;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;

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

            services.AddScoped<IAuthUseCase, FakeAuthUseCase>();
            services.AddScoped<IGameplayUseCase, FakeGameplayUseCase>();
            services.AddScoped<ILobbyUseCase, FakeLobbyUseCase>();
        });
    }
}
