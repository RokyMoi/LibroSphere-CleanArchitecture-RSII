namespace LibroSphere.Application.Users.Query.GetUserById;

public sealed record UserResponse(
    Guid Id,
    string FirstName,
    string LastName,
    string Email,
    DateTime DateRegistered,
    DateTime? LastLogin,
    bool IsActive);
