using System.Reflection;
using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Infrastructure;
using LibroSphere.Infrastructure.Services.Analytics;
using LibroSphere.Worker.Services;
using MassTransit;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using StackExchange.Redis;

namespace LibroSphere.Worker;

public static class DependencyInjection
{
    public static IServiceCollection AddWorkerServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Database")
            ?? throw new InvalidOperationException("Connection string 'Database' is not configured for Worker.");

        services.AddSingleton<IPublisher, NoOpPublisher>();
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(connectionString));

        var redisConnectionString = configuration.GetConnectionString("Redis") ?? "localhost";
        services.AddSingleton<IConnectionMultiplexer>(_ =>
        {
            var options = ConfigurationOptions.Parse(redisConnectionString, true);
            options.AbortOnConnectFail = false;
            return ConnectionMultiplexer.Connect(options);
        });

        services.Configure<SmtpEmailOptions>(configuration.GetSection("Email"));
        services.AddScoped<IEmailService, SmtpEmailService>();
        services.AddSingleton<IAnalyticsActivityStore, RedisAnalyticsActivityStore>();

        services.AddMassTransit(cfg =>
        {
            cfg.AddConsumers(Assembly.GetExecutingAssembly());

            cfg.UsingRabbitMq((ctx, rabbit) =>
            {
                rabbit.Host(
                    configuration["RabbitMQ:Host"] ?? "localhost",
                    "/",
                    h =>
                    {
                        h.Username(configuration["RabbitMQ:Username"] ?? "guest");
                        h.Password(configuration["RabbitMQ:Password"] ?? "guest");
                    });

                rabbit.ConfigureEndpoints(ctx);
            });
        });

        return services;
    }
}
