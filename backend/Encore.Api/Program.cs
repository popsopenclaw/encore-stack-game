using System.Text;
using Encore.Infrastructure.Data;
using Encore.Infrastructure.Services;
using Encore.Application.Abstractions;
using Encore.Application.Auth;
using Encore.Application.Gameplay;
using Encore.Application.Lobby;
using Encore.Infrastructure.Adapters;
using Encore.Api.Hubs;
using Encore.Api.Middleware;
using Encore.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Postgres")));

builder.Services.AddSingleton<IConnectionMultiplexer>(_ =>
    ConnectionMultiplexer.Connect(builder.Configuration.GetConnectionString("Valkey")!));

builder.Services.AddHttpClient();
builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddScoped<GitHubOAuthService>();
builder.Services.AddSingleton<BoardTemplateProvider>();
builder.Services.AddScoped<GameSessionService>();
builder.Services.AddScoped<IGameStateStore, GameSessionService>();
builder.Services.AddScoped<EncoreRulesEngine>();

// Application ports/adapters
builder.Services.AddScoped<IAuthGateway, AuthGatewayAdapter>();
builder.Services.AddScoped<ITokenIssuer, TokenIssuerAdapter>();
builder.Services.AddScoped<IGameplayRepository, GameplayRepositoryAdapter>();
builder.Services.AddScoped<ILobbyRepository, LobbyRepositoryAdapter>();
builder.Services.AddScoped<IGameRules, GameRulesAdapter>();

// Use-cases
builder.Services.AddScoped<IAuthUseCase, AuthUseCase>();
builder.Services.AddScoped<IGameplayUseCase, GameplayUseCase>();
builder.Services.AddScoped<ILobbyUseCase, LobbyUseCase>();
builder.Services.AddScoped<LobbyRealtimeNotifier>();
builder.Services.AddHostedService<LobbyCleanupHostedService>();

var jwtKey = builder.Configuration["Jwt:SigningKey"] ?? throw new InvalidOperationException("Missing Jwt:SigningKey");
var issuer = builder.Configuration["Jwt:Issuer"] ?? "encore-api";
var audience = builder.Configuration["Jwt:Audience"] ?? "encore-clients";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ValidIssuer = issuer,
            ValidAudience = audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<LobbyHub>("/hubs/lobby");
app.MapGet("/health", () => Results.Ok(new { ok = true }));

app.Run();

public partial class Program { }
