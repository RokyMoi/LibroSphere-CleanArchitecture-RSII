using Dapper;
using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure.Authentication;
using LibroSphere.Infrastructure.Clock;
using LibroSphere.Infrastructure.Data;
using LibroSphere.Infrastructure.Repositories;
using LibroSphere.Infrastructure.Services;
using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Quartz;
using StackExchange.Redis;
using System;
using System.Reflection;
using System.Text;

namespace LibroSphere.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.AddPersistence(configuration);
            services.AddCustomAuthentication(configuration);
            services.RabbitMQDepedencyProviders(configuration);





            services.AddHttpContextAccessor();
            return services;
        }
        private static IServiceCollection RabbitMQDepedencyProviders(
    this IServiceCollection services,
    IConfiguration configuration)
        {
            services.AddMassTransit(cfg =>
            {
                
                cfg.UsingRabbitMq((ctx, rabbit) =>
                {
                    rabbit.Host(configuration["RabbitMQ:Host"], "/", h =>
                    {
                        h.Username(configuration["RabbitMQ:Arname"]);
                        h.Password(configuration["RabbitMQ:Password"]);
                    });

                    rabbit.ConfigureEndpoints(ctx);
                });
            });

            return services;
        }
        private static IServiceCollection AddPersistence(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("Database") ??
                throw new InvalidOperationException("Connection string 'Database' is not configured.");

            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<IUnitOfWork>(sp =>
                sp.GetRequiredService<ApplicationDbContext>());

            services.AddSingleton<ISqlConnectionFactory>(_ =>
                new SqlConnectionFactory(connectionString));

            SqlMapper.AddTypeHandler(new DateOnlyTypeHandler());

            services.AddScoped<IAuthorRepository, AuthorRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IBookRepository, BookRepository>();
            services.AddTransient<IDateTimeProvider, DateTimeProvider>();
          

            var redisConnectionString = configuration.GetConnectionString("Redis");
            services.AddSingleton<IConnectionMultiplexer>(config =>
            {
                var options = ConfigurationOptions.Parse(redisConnectionString, true);
                options.AbortOnConnectFail = false; 
                return ConnectionMultiplexer.Connect(options);
            });
            services.AddScoped<ICartService, CartService>();
             services.AddScoped<IPaymentService, PaymentService>();
            services.AddScoped<IOrderService, OrderService>();

          
            services.AddScoped<IOrderRepository, OrderRepository>();
            services.AddScoped<IUserBookRepository, UserBookRepository>();

            return services;
        }
        private static IServiceCollection AddCustomAuthentication(
           this IServiceCollection services,
           IConfiguration configuration)
        {
            services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
            var jwtSettings = configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()!;


            services.AddIdentityCore<ApplicationUser>(opt =>
            {
                opt.Password.RequiredLength = 8;
                opt.Password.RequireUppercase = true;
                opt.Password.RequireDigit = true;
                opt.User.RequireUniqueEmail = true;
                opt.SignIn.RequireConfirmedEmail = false;
            })
            .AddRoles<IdentityRole>()
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddSignInManager()
            .AddDefaultTokenProviders();

            services.AddAuthentication(opt =>
            {
                opt.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                opt.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(opt =>
            {
                opt.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(jwtSettings.SecretKey)),
                    ValidateIssuer = true,
                    ValidIssuer = jwtSettings.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwtSettings.Audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                };
            });


            services.AddScoped<IJwtService, JwtTokenService>();
            services.AddScoped<IAuthService, AuthService>();
            return services;



        }
    }
   
}