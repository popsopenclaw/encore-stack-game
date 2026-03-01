using System.Text;
using Encore.Api.Data;
using Encore.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
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

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { ok = true }));

app.Run();
