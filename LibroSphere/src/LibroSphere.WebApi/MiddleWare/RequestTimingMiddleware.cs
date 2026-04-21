using System.Diagnostics;

namespace LibroSphere.WebApi.MiddleWare;

public sealed class RequestTimingMiddleware
{
    private readonly ILogger<RequestTimingMiddleware> _logger;
    private readonly RequestDelegate _next;

    public RequestTimingMiddleware(
        RequestDelegate next,
        ILogger<RequestTimingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var totalStopwatch = Stopwatch.StartNew();
        long? timeToFirstByteMs = null;

        context.Response.OnStarting(() =>
        {
            timeToFirstByteMs ??= totalStopwatch.ElapsedMilliseconds;
            context.Response.Headers["Server-Timing"] = $"app;dur={timeToFirstByteMs.Value}";
            context.Response.Headers["X-TTFB-Ms"] = timeToFirstByteMs.Value.ToString();
            return Task.CompletedTask;
        });

        try
        {
            await _next(context);
        }
        finally
        {
            totalStopwatch.Stop();

            if (context.Request.Path.StartsWithSegments("/api"))
            {
                _logger.LogInformation(
                    "RequestTiming {Method} {Path} => {StatusCode}. TTFB={TtfbMs}ms Total={TotalMs}ms ContentLength={ContentLength}",
                    context.Request.Method,
                    context.Request.Path,
                    context.Response.StatusCode,
                    timeToFirstByteMs ?? totalStopwatch.ElapsedMilliseconds,
                    totalStopwatch.ElapsedMilliseconds,
                    context.Response.ContentLength);
            }
        }
    }
}
