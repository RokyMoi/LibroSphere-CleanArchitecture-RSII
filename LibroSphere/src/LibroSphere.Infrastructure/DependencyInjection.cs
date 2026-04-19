using Dapper;
using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Application.Abstractions.Data;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Storage;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Application.Abstractions.Seeding;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.WishList;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure.Authentication;
using LibroSphere.Infrastructure.Clock;
using LibroSphere.Infrastructure.Data;
using LibroSphere.Infrastructure.Repositories;
using LibroSphere.Infrastructure.Services;
using LibroSphere.Infrastructure.Services.Analytics;
using LibroSphere.Infrastructure.Storage;
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
using Microsoft.Data.SqlClient;

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
            services.Configure<CloudflareR2Options>(configuration.GetSection(CloudflareR2Options.SectionName));

            services.AddHttpContextAccessor();
            return services;
        }
        private static IServiceCollection RabbitMQDepedencyProviders(
    this IServiceCollection services,
    IConfiguration configuration)
        {
            var rabbitHost = configuration["RabbitMQ:Host"] ?? throw new InvalidOperationException("RabbitMQ host is not configured.");
            var rabbitUsername = configuration["RabbitMQ:Username"] ?? throw new InvalidOperationException("RabbitMQ username is not configured.");
            var rabbitPassword = configuration["RabbitMQ:Password"] ?? throw new InvalidOperationException("RabbitMQ password is not configured.");

            services.AddMassTransit(cfg =>
            {
                
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
        private static IServiceCollection AddPersistence(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            var connectionString = ResolveDatabaseConnectionString(configuration) ??
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
            services.AddScoped<IGenreRepository, GenreRepository>();
            services.AddScoped<IReviewRepository, ReviewRepository>();
            services.AddScoped<IWishlistRepository, WishlistRepository>();
            services.AddTransient<IDateTimeProvider, DateTimeProvider>();
          

            var redisConnectionString = configuration.GetConnectionString("Redis") ??
                throw new InvalidOperationException("Connection string 'Redis' is not configured.");
            services.AddSingleton<IConnectionMultiplexer>(config =>
            {
                var options = ConfigurationOptions.Parse(redisConnectionString, true);
                options.AbortOnConnectFail = false; 
                return ConnectionMultiplexer.Connect(options);
            });
            services.AddScoped<ICartService, CartService>();
            services.AddScoped<IPaymentService, PaymentService>();
            services.AddScoped<IPaymentWebhookProcessor, PaymentWebhookProcessor>();
            services.AddScoped<IOrderService, OrderService>();
            services.AddScoped<ISeedService, SeedService>();
            services.AddScoped<IBookAssetStorageService, CloudflareR2BookAssetStorageService>();
            services.AddScoped<LibroSphere.Application.Abstractions.Recommendations.IBookRecommendationService, BookRecommendationService>();
            services.AddScoped<IAnalyticsService, AnalyticsService>();
            services.AddSingleton<IAnalyticsActivityStore, RedisAnalyticsActivityStore>();

          
            services.AddScoped<IOrderRepository, OrderRepository>();
            services.AddScoped<IUserBookRepository, UserBookRepository>();

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
        private static IServiceCollection AddCustomAuthentication(
           this IServiceCollection services,
           IConfiguration configuration)
        {
            services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
            services.Configure<AccessControlOptions>(configuration.GetSection(AccessControlOptions.SectionName));
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
                    ClockSkew = TimeSpan.Zero,
                    NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier,
                    RoleClaimType = System.Security.Claims.ClaimTypes.Role
                };
            });

            services.AddAuthorization();

            services.AddScoped<IJwtService, JwtTokenService>();
            services.AddScoped<IAuthService, AuthService>();
            return services;



        }
    }
   
}
