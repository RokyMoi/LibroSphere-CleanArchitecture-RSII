using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Data;

internal static class DbExceptions
{
    /// <summary>Returns true when the DB exception is caused by a unique/primary key constraint violation.</summary>
    public static bool IsDuplicateKeyViolation(DbUpdateException ex)
    {
        var inner = ex.InnerException?.Message ?? string.Empty;
        return inner.Contains("duplicate key", StringComparison.OrdinalIgnoreCase)
            || inner.Contains("Cannot insert duplicate", StringComparison.OrdinalIgnoreCase)
            || inner.Contains("UNIQUE constraint", StringComparison.OrdinalIgnoreCase)
            || inner.Contains("2601", StringComparison.OrdinalIgnoreCase)   // SQL Server error 2601
            || inner.Contains("2627", StringComparison.OrdinalIgnoreCase);  // SQL Server error 2627
    }
}
