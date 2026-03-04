namespace Encore.Api.Middleware;

public sealed record ApiError(string Code, string Message, string? CorrelationId = null);

public static class ApiErrorFactory
{
    public static ApiError Create(string code, string message, HttpContext context)
    {
        var cid = context.Items.TryGetValue("X-Correlation-Id", out var raw) ? raw?.ToString() : null;
        return new ApiError(code, message, cid);
    }
}
