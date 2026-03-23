using Dapper;
using LibroSphere.Application.Abstractions.Clock;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure.Data;
using LIbroSphere.Infrastructure.Clock;
using LIbroSphere.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;

namespace LIbroSphere.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // DateTimeProvider
            services.AddTransient<IDateTimeProvider, DateTimeProvider>();

            // Connection string
            var connectionString = configuration.GetConnectionString("Database") ??
                throw new InvalidOperationException("Connection string 'Database' is not configured.");

            // DbContext
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(connectionString)
            );

            // UnitOfWork
            services.AddScoped<IUnitOfWork>(sp =>
                sp.GetRequiredService<ApplicationDbContext>());

            // Dapper connection factory
            services.AddSingleton<ISqlConnectionFactory>(_ =>
                new SqlConnectionFactory(connectionString));

            // Dapper type handlers
            SqlMapper.AddTypeHandler(new DateOnlyTypeHandler());

            // Repositories
            services.AddScoped<IAuthorRepository, AuthorRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IBookRepository, BookRepository>();


            return services;
        }
    }
}