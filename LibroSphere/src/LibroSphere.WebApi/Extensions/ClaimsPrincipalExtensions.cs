using System.Security.Claims;
using LibroSphere.Application.Abstractions.Identity;

namespace LibroSphere.WebApi.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetRequiredUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub")
            ?? throw new InvalidOperationException("UserId claim is missing from token.");
        return Guid.TryParse(value, out var id)
            ? id
            : throw new InvalidOperationException("UserId claim is not a valid Guid.");
    }

    public static string GetRequiredEmail(this ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.Email) ?? user.FindFirstValue("email")
            ?? throw new InvalidOperationException("Email claim is missing from token.");
    }

    public static string GetRequiredIdentityUserId(this ClaimsPrincipal user)
    {
        return user.FindFirstValue("identityUserId")
            ?? throw new InvalidOperationException("IdentityUserId claim is missing from token.");
    }

    public static bool IsAdmin(this ClaimsPrincipal user)
    {
        return user.IsInRole(ApplicationRoles.Admin);
    }
}
