using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Users.AuthCommands
{
    public sealed record LogoutUserCommand(string UserId) : ICommand<AuthResult>;
}
