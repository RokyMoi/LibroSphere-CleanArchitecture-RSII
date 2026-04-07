using System.Reflection;
using LibroSphere.Infrastructure;
using LibroSphere.Worker.Services;
using MassTransit;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

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

        services.Configure<SmtpEmailOptions>(configuration.GetSection("Email"));
        services.AddScoped<IEmailService, SmtpEmailService>();

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
