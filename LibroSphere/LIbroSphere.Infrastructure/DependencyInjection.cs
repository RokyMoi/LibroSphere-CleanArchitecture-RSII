using Dapper;
using LibroSphere.Application.Abstractions.Clock;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Infrastructure.Data;
using LIbroSphere.Infrastructure.Clock;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace LIbroSphere.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
               IConfiguration configuration)
            
        {
            services.AddTransient<IDateTimeProvider, DateTimeProvider>();

            var connectionString = configuration.GetConnectionString("Database") ?? 
                throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<ApplicationDbContext>(options => {
                options.UseSqlServer(connectionString);

                services.AddScoped<IUnitOfWork>(sp=> sp.GetRequiredService<ApplicationDbContext>());
                services.AddSingleton<ISqlConnectionFactory>(_ =>
    new SqlConnectionFactory(connectionString));

                SqlMapper.AddTypeHandler(new DateOnlyTypeHandler());

            });
            return services;
        }
    }
}
