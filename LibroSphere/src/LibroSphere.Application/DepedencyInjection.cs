using FluentValidation;
using LibroSphere.Application.Abstractions.Behavior;
using Microsoft.Extensions.DependencyInjection;

namespace LibroSphere.Services
{
    public static class DepedencyInjection
    {
        public static IServiceCollection AddApplication(this IServiceCollection services)
        {
            services.AddMediatR(configuration =>
            {
                configuration.RegisterServicesFromAssembly(typeof(DepedencyInjection).Assembly);
                configuration.AddOpenBehavior(typeof(LoggingBehavior<,>));
                configuration.AddOpenBehavior(typeof(ValidationBehavior<,>));
            });

            services.AddValidatorsFromAssembly(typeof(DepedencyInjection).Assembly);

            return services;
        }
    }
}
