using System.Security.Claims;
using LibroSphere.Application.Abstractions.Identity;

namespace LibroSphere.WebApi.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetRequiredUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.Parse(value!);
    }

    public static string GetRequiredEmail(this ClaimsPrincipal user)
    {
        return user.FindFirstValue(ClaimTypes.Email) ?? user.FindFirstValue("email")!;
    }

    public static string GetRequiredIdentityUserId(this ClaimsPrincipal user)
    {
        return user.FindFirstValue("identityUserId")!;
    }

    public static bool IsAdmin(this ClaimsPrincipal user)
    {
        return user.IsInRole(ApplicationRoles.Admin);
    }
}
