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
using Microsoft.Data.SqlClient;

namespace LibroSphere.Worker;

public static class DependencyInjection
{
    public static IServiceCollection AddWorkerServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = ResolveDatabaseConnectionString(configuration)
            ?? throw new InvalidOperationException("Connection string 'Database' is not configured for Worker.");
        var redisConnectionString = configuration.GetConnectionString("Redis")
            ?? throw new InvalidOperationException("Connection string 'Redis' is not configured for Worker.");
        var rabbitHost = configuration["RabbitMQ:Host"]
            ?? throw new InvalidOperationException("RabbitMQ host is not configured for Worker.");
        var rabbitUsername = configuration["RabbitMQ:Username"]
            ?? throw new InvalidOperationException("RabbitMQ username is not configured for Worker.");
        var rabbitPassword = configuration["RabbitMQ:Password"]
            ?? throw new InvalidOperationException("RabbitMQ password is not configured for Worker.");

        services.AddSingleton<IPublisher, NoOpPublisher>();
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(connectionString));

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
                rabbit.Host(rabbitHost, "/", h =>
                {
                    h.Username(rabbitUsername);
                    h.Password(rabbitPassword);
                });

                rabbit.ConfigureEndpoints(ctx);
            });
        });

        return services;
    }

    private static string? ResolveDatabaseConnectionString(IConfiguration configuration)
    {
        var host = configuration["DB_HOST"];
        var port = configuration["DB_PORT"];
        var database = configuration["DB_NAME"];
        var user = configuration["DB_USER"];
        var password = configuration["DB_PASSWORD"] ?? configuration["DB_SA_PASSWORD"];

        if (!string.IsNullOrWhiteSpace(host) &&
            !string.IsNullOrWhiteSpace(database) &&
            !string.IsNullOrWhiteSpace(user) &&
            !string.IsNullOrWhiteSpace(password))
        {
            var builder = new SqlConnectionStringBuilder
            {
                DataSource = string.IsNullOrWhiteSpace(port) ? host : $"{host},{port}",
                InitialCatalog = database,
                UserID = user,
                Password = password,
                TrustServerCertificate = true
            };

            return builder.ConnectionString;
        }

        return configuration.GetConnectionString("Database");
    }
}
