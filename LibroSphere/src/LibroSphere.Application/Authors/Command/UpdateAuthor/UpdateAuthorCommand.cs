using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Authors;

namespace LibroSphere.Application.Authors.Command.UpdateAuthor
{
    public sealed record UpdateAuthorCommand(Guid AuthorId, Name Name, Biography Biography) : ICommand;
}
