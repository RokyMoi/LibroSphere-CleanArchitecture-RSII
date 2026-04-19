using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Users.Command.DeleteUser
{
    public sealed record DeleteUserCommand(Guid UserId) : ICommand;
}
