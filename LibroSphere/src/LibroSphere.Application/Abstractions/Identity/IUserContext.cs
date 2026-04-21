using System;

namespace LibroSphere.Application.Abstractions.Identity
{
    public interface IUserContext
    {
        string? UserId { get; }
        string? Email { get; }
        bool IsAuthenticated { get; }
        bool IsAdmin { get; }
    }
}
