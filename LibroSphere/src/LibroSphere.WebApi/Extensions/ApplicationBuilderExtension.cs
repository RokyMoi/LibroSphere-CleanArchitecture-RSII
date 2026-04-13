using LibroSphere.Infrastructure;
using LibroSphere.Infrastructure.Authentication;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.WebApi.MiddleWare;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace LibroSphere.Api.Extensions;

public static class ApplicationBuilderExtensions
{
    private const string BaselineMigrationId = "20260327145028_UserRegistration";

    public static void ApplyMigrations(this IApplicationBuilder app)
    {
        using var scope = app.ApplicationServices.CreateScope();

        using var dbContext = scope.ServiceProvider
            .GetRequiredService<ApplicationDbContext>();

        EnsureBaselineMigrationHistory(dbContext);
        dbContext.Database.Migrate();
    }

    public static async Task SeedIdentityAsync(this IApplicationBuilder app)
    {
        using var scope = app.ApplicationServices.CreateScope();

        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var accessControlOptions = scope.ServiceProvider.GetRequiredService<IOptions<AccessControlOptions>>().Value;

        foreach (var roleName in new[] { LibroSphere.Application.Abstractions.Identity.ApplicationRoles.User, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.Admin })
        {
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                await roleManager.CreateAsync(new IdentityRole(roleName));
            }
        }

        foreach (var user in userManager.Users.ToList())
        {
            var existingRoles = await userManager.GetRolesAsync(user);
            if (existingRoles.Count == 0)
            {
                await userManager.AddToRoleAsync(user, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.User);
            }

            var shouldBeAdmin = accessControlOptions.AdminEmails.Any(email =>
                email.Equals(user.Email, StringComparison.OrdinalIgnoreCase));

            if (shouldBeAdmin && !await userManager.IsInRoleAsync(user, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.Admin))
            {
                await userManager.AddToRoleAsync(user, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.Admin);
            }
        }

        if (!accessControlOptions.SeedDefaultAdmin ||
            string.IsNullOrWhiteSpace(accessControlOptions.DefaultAdminEmail) ||
            string.IsNullOrWhiteSpace(accessControlOptions.DefaultAdminPassword))
        {
            return;
        }

        var adminUser = await userManager.FindByEmailAsync(accessControlOptions.DefaultAdminEmail);
        if (adminUser is null)
        {
            var dateTimeProvider = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();
            var domainUser = User.Create(
                new FirstName(accessControlOptions.DefaultAdminFirstName),
                new LastName(accessControlOptions.DefaultAdminLastName),
                new Email(accessControlOptions.DefaultAdminEmail),
                dateTimeProvider);

            adminUser = new ApplicationUser
            {
                UserName = accessControlOptions.DefaultAdminEmail,
                Email = accessControlOptions.DefaultAdminEmail,
                DomainUserId = domainUser.Id,
                DomainUser = domainUser,
                DateRegistered = dateTimeProvider.UtcNow
            };

            var createResult = await userManager.CreateAsync(adminUser, accessControlOptions.DefaultAdminPassword);
            if (!createResult.Succeeded)
            {
                throw new InvalidOperationException($"Default admin creation failed: {string.Join(", ", createResult.Errors.Select(x => x.Description))}");
            }
        }

        if (!await userManager.IsInRoleAsync(adminUser, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.User))
        {
            await userManager.AddToRoleAsync(adminUser, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.User);
        }

        if (!await userManager.IsInRoleAsync(adminUser, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.Admin))
        {
            await userManager.AddToRoleAsync(adminUser, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.Admin);
        }

        if (!accessControlOptions.SeedDefaultUser ||
            string.IsNullOrWhiteSpace(accessControlOptions.DefaultUserEmail) ||
            string.IsNullOrWhiteSpace(accessControlOptions.DefaultUserPassword))
        {
            return;
        }

        var defaultUser = await userManager.FindByEmailAsync(accessControlOptions.DefaultUserEmail);
        if (defaultUser is null)
        {
            var dateTimeProvider = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();
            var domainUser = User.Create(
                new FirstName(accessControlOptions.DefaultUserFirstName),
                new LastName(accessControlOptions.DefaultUserLastName),
                new Email(accessControlOptions.DefaultUserEmail),
                dateTimeProvider);

            defaultUser = new ApplicationUser
            {
                UserName = accessControlOptions.DefaultUserEmail,
                Email = accessControlOptions.DefaultUserEmail,
                DomainUserId = domainUser.Id,
                DomainUser = domainUser,
                DateRegistered = dateTimeProvider.UtcNow
            };

            var createResult = await userManager.CreateAsync(defaultUser, accessControlOptions.DefaultUserPassword);
            if (!createResult.Succeeded)
            {
                throw new InvalidOperationException($"Default user creation failed: {string.Join(", ", createResult.Errors.Select(x => x.Description))}");
            }
        }

        if (!await userManager.IsInRoleAsync(defaultUser, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.User))
        {
            await userManager.AddToRoleAsync(defaultUser, LibroSphere.Application.Abstractions.Identity.ApplicationRoles.User);
        }
    }

    public static void UseCustomMiddleWare(this IApplicationBuilder app)
    {
        app.UseMiddleware<ExceptionHandlingMiddleware>();
    }

    private static void EnsureBaselineMigrationHistory(ApplicationDbContext dbContext)
    {
        var pendingMigrations = dbContext.Database.GetPendingMigrations().ToList();
        if (pendingMigrations.Count != 1 || pendingMigrations[0] != BaselineMigrationId)
        {
            return;
        }

        var appliedMigrations = dbContext.Database.GetAppliedMigrations().ToList();
        if (appliedMigrations.Count > 0)
        {
            return;
        }

        if (!TableExists(dbContext, "AspNetUsers") || !TableExists(dbContext, "Users"))
        {
            return;
        }

        dbContext.Database.ExecuteSqlRaw(
            """
            IF NOT EXISTS (SELECT 1 FROM [__EFMigrationsHistory] WHERE [MigrationId] = {0})
            BEGIN
                INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
                VALUES ({0}, {1})
            END
            """,
            BaselineMigrationId,
            "8.0.25");
    }

    private static bool TableExists(ApplicationDbContext dbContext, string tableName)
    {
        using var command = dbContext.Database.GetDbConnection().CreateCommand();
        command.CommandText = "SELECT COUNT(1) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @tableName";

        var parameter = new SqlParameter("@tableName", tableName);
        command.Parameters.Add(parameter);

        if (command.Connection!.State != System.Data.ConnectionState.Open)
        {
            command.Connection.Open();
        }

        var result = command.ExecuteScalar();
        return result is not null && Convert.ToInt32(result) > 0;
    }
}
