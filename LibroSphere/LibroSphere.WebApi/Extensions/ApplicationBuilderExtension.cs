using LibroSphere.Infrastructure;
using LIbroSphere.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Api.Extensions;

public static class ApplicationBuilderExtensions
{
    public static void ApplyMigrations(this IApplicationBuilder app)
    {
        using var scope = app.ApplicationServices.CreateScope();

        using var dbContext = scope.ServiceProvider
            .GetRequiredService<ApplicationDbContext>();

        dbContext.Database.Migrate();
    }
}