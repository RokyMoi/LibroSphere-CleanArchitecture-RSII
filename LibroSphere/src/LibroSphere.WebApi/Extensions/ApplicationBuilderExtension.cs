using LibroSphere.Infrastructure;
using LibroSphere.WebApi.MiddleWare;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;

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
