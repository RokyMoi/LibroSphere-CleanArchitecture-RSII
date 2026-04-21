using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Abstractions.Clock;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure;
using LibroSphere.Infrastructure.Authentication;
using LibroSphere.WebApi.MiddleWare;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using LibroSphere.Application.Exceptions;

namespace LibroSphere.Api.Extensions;

public static class ApplicationBuilderExtensions
{
    public static async Task SeedIdentityAsync(this IApplicationBuilder app)
    {
        using var scope = app.ApplicationServices.CreateScope();

        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var options = scope.ServiceProvider.GetRequiredService<IOptions<AccessControlOptions>>().Value;
        var clock = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();

        // Makeee role if not exist
        string[] roles = [ApplicationRoles.User, ApplicationRoles.Admin];
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
                await roleManager.CreateAsync(new IdentityRole(role));
        }

       
        if (options.SeedDefaultAdmin)
        {
            await CreateUserIfNotExists(userManager, clock,
                options.DefaultAdminEmail,
                options.DefaultAdminPassword,
                options.DefaultAdminFirstName,
                options.DefaultAdminLastName,
                isAdmin: true);
        }

        // Seed android user
        if (options.SeedDefaultUser)
        {
            await CreateUserIfNotExists(userManager, clock,
                options.DefaultUserEmail,
                options.DefaultUserPassword,
                options.DefaultUserFirstName,
                options.DefaultUserLastName,
                isAdmin: false);
        }
    }

    private static async Task CreateUserIfNotExists(
        UserManager<ApplicationUser> userManager,
        IDateTimeProvider clock,
        string email,
        string password,
        string firstName,
        string lastName,
        bool isAdmin)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            return;

        var existing = await userManager.FindByEmailAsync(email);
        if (existing != null)
            return;

        var domainUser = User.Create(
            new FirstName(firstName),
            new LastName(lastName),
            new Email(email),
            clock);

        var appUser = new ApplicationUser
        {
            UserName = email,
            Email = email,
            DomainUserId = domainUser.Id,
            DomainUser = domainUser,
            DateRegistered = clock.UtcNow
        };

        var result = await userManager.CreateAsync(appUser, password);
        if (!result.Succeeded)
            throw new BusinessException($"Nije moguce kreirati korisnika {email}: {string.Join(", ", result.Errors.Select(e => e.Description))}");

        await userManager.AddToRoleAsync(appUser, ApplicationRoles.User);

        if (isAdmin)
            await userManager.AddToRoleAsync(appUser, ApplicationRoles.Admin);
    }

    public static void UseCustomMiddleWare(this IApplicationBuilder app)
    {
        app.UseMiddleware<RequestTimingMiddleware>();
        app.UseMiddleware<ExceptionHandlingMiddleware>();
    }
}
