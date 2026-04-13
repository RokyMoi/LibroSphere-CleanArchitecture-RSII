using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.Users.Errors;

public static class UserErrors
{
    public static Error NotFound(Guid userId) =>
        new("Users.NotFound", $"The user with Id '{userId}' was not found.");
}
