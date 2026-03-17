using FluentValidation;
using LibroSphere.Application.Abstractions.Behavior;
using Microsoft.Extensions.DependencyInjection;
using System.Runtime.CompilerServices;

namespace LibroSphere.Services
{
    public static class DepedencyInjection
    {
        public static IServiceCollection AddApplication(this IServiceCollection services)
        {

            //RegisterServices From Assembly (Tj projekta) 
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
