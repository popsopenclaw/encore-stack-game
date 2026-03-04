using System.Text.Json;
using StackExchange.Redis;

namespace Encore.Api.Middleware;

public class ExceptionHandlingMiddleware(RequestDelegate next)
{
    public async Task Invoke(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex) when (!context.Response.HasStarted)
        {
            var (status, code, message) = Map(ex);
            context.Response.StatusCode = status;
            context.Response.ContentType = "application/json";
            var payload = ApiErrorFactory.Create(code, message, context);
            await context.Response.WriteAsync(JsonSerializer.Serialize(payload));
        }
    }

    private static (int status, string code, string message) Map(Exception ex) => ex switch
    {
        KeyNotFoundException => (StatusCodes.Status404NotFound, "not_found", ex.Message),
        UnauthorizedAccessException => (StatusCodes.Status403Forbidden, "forbidden", ex.Message),
        InvalidOperationException => (StatusCodes.Status400BadRequest, "invalid_operation", ex.Message),
        RedisConnectionException => (StatusCodes.Status503ServiceUnavailable, "redis_unavailable", "Realtime cache unavailable"),
        _ => (StatusCodes.Status500InternalServerError, "internal_error", "Internal server error")
    };
}
