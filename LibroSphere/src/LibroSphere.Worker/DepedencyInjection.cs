using LibroSphere.Worker.Consumers;
using MassTransit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace LibroSphere.Worker;

public static class DependencyInjection
{
    public static IServiceCollection AddWorkerServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddMassTransit(cfg =>
        {

            cfg.AddConsumers(Assembly.GetExecutingAssembly());

            cfg.UsingRabbitMq((ctx, rabbit) =>
            {
                rabbit.Host(configuration["RabbitMQ:Host"], "/", h =>
                {
                    h.Username(configuration["RabbitMQ:Username"]);
                    h.Password(configuration["RabbitMQ:Password"]);
                });

                rabbit.ConfigureEndpoints(ctx);
            });
        });

        return services;
    }
}